import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kita_agro/core/models/user_model.dart';
import 'package:kita_agro/features/Message/chat_screen.dart';

class DynamicContactButton extends StatefulWidget {
  final String ownerId;

  const DynamicContactButton({Key? key, required this.ownerId}) : super(key: key);

  @override
  State<DynamicContactButton> createState() => _DynamicContactButtonState();
}

class _DynamicContactButtonState extends State<DynamicContactButton> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const SizedBox.shrink(); // Or some login prompt
    }

    // State 1: Self
    if (_currentUserId == widget.ownerId) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          onPressed: null,
          child: const Text('Your Product'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .snapshots(),
      builder: (context, currentUserSnapshot) {
        if (!currentUserSnapshot.hasData) {
          return const SizedBox(
            height: 48, 
            width: double.infinity, 
            child: Center(child: CircularProgressIndicator())
          );
        }

        final currentUserData =
            currentUserSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final myFriends = List<String>.from(currentUserData['friends'] ?? []);

        // Listen to owner's document for BOTH pending checks AND profile data for chat
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.ownerId)
              .snapshots(),
          builder: (context, ownerSnapshot) {
            if (!ownerSnapshot.hasData) {
              return const SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Center(child: CircularProgressIndicator()));
            }

            final ownerData =
                ownerSnapshot.data!.data() as Map<String, dynamic>? ?? {};

            // State 2: Friends (Accepted)
            if (myFriends.contains(widget.ownerId)) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat with Owner'),
                  onPressed: () {
                    // Create UserModel from ownerData
                    try {
                      final ownerUser = UserModel.fromMap(ownerData);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(receiverUser: ownerUser),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Error opening chat: ${e.toString()}')),
                      );
                    }
                  },
                ),
              );
            }

            final ownerFriendRequests =
                List<dynamic>.from(ownerData['friendRequests'] ?? [])
                    .map((e) => e.toString())
                    .toList();

            // State 3: Request Pending
            if (ownerFriendRequests.contains(_currentUserId)) {
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  icon: const Icon(Icons.access_time),
                  label: const Text('Request Pending'),
                  onPressed: null,
                ),
              );
            }

            // State 4: None (Send Friend Request)
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Send Friend Request'),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.ownerId)
                        .update({
                      'friendRequests': FieldValue.arrayUnion([_currentUserId]),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sending request: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
