import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/models/user_model.dart';
import '../../services/user_service.dart';
import '../community/community_service.dart';
import 'single_post_screen.dart';
import '../Message/chat_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final UserModel user;

  const OtherUserProfileScreen({super.key, required this.user});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserById(uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFriendStatus() async {
    if (_currentUser == null) return;

    // Determine current status
    if (_currentUser!.friends.contains(widget.user.uid)) {
      // Currently friends, we don't have an unfriend method but let's implement a simple arrayRemove
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
            'friends': FieldValue.arrayRemove([widget.user.uid]),
          });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
            'friends': FieldValue.arrayRemove([_currentUser!.uid]),
          });
    } else if (widget.user.friendRequests.contains(_currentUser!.uid)) {
      // Already requested, maybe cancel request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
            'friendRequests': FieldValue.arrayRemove([_currentUser!.uid]),
          });
    } else if (_currentUser!.friendRequests.contains(widget.user.uid)) {
      // They requested me, so accept
      await _userService.acceptFriendRequest(widget.user.uid);
    } else {
      // Send request
      await _userService.sendFriendRequest(widget.user.uid);
    }

    // Refresh user
    await _fetchCurrentUser();
    // Re-fetch widget user too, to check if they have me in friendRequests
    final updatedTargetUser = await _userService.getUserById(widget.user.uid);
    if (mounted && updatedTargetUser != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFriend = _currentUser?.friends.contains(widget.user.uid) ?? false;
    // Check real-time target user data
    return StreamBuilder<UserModel?>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null),
      builder: (context, userSnapshot) {
        final targetUser = userSnapshot.data ?? widget.user;
        final isRequested = targetUser.friendRequests.contains(
          _currentUser?.uid ?? '',
        );
        final hasRequestedMe =
            _currentUser?.friendRequests.contains(targetUser.uid) ?? false;

        return StreamBuilder<QuerySnapshot>(
          stream: _communityService.getPostsStream(),
          builder: (context, snapshot) {
            int postsCount = 0;
            List<DocumentSnapshot> userPosts = [];

            if (snapshot.hasData) {
              userPosts = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['publisherId'] == targetUser.uid;
              }).toList();
              postsCount = userPosts.length;
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: const BackButton(color: Colors.black),
                title: Text(
                  targetUser.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ),
              body: ListView(
                children: [
                  // Cover Photo & Avatar Header
                  SizedBox(
                    height: 250,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2070&auto=format&fit=crop",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 100,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.green.shade100,
                              backgroundImage:
                                  targetUser.profilePicUrl.isNotEmpty
                                  ? NetworkImage(targetUser.profilePicUrl)
                                  : null,
                              child: targetUser.profilePicUrl.isEmpty
                                  ? Text(
                                      targetUser.fullName.isNotEmpty
                                          ? targetUser.fullName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name and Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          targetUser.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${targetUser.friends.length} friends • $postsCount posts",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (targetUser.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            targetUser.bio,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Add Friend / Message)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: ElevatedButton.icon(
                            onPressed: _currentUser == null
                                ? null
                                : _toggleFriendStatus,
                            icon: Icon(
                              isFriend
                                  ? Icons.person_remove
                                  : (hasRequestedMe
                                        ? Icons.check
                                        : (isRequested
                                              ? Icons.undo
                                              : Icons.person_add)),
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              isFriend
                                  ? 'Friends'
                                  : (hasRequestedMe
                                        ? 'Accept Request'
                                        : (isRequested
                                              ? 'Requested'
                                              : 'Add Friend')),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFriend
                                  ? Colors.grey.shade600
                                  : Colors.blueAccent[700], // Facebook blue
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                        if (isFriend) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to chat
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatScreen(receiverUser: targetUser),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.message,
                                color: Colors.black87,
                                size: 20,
                              ),
                              label: const Text(
                                'Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(thickness: 8, color: Colors.grey.shade300),

                  // Personal Details Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Personal details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          "${targetUser.town}, ${targetUser.state}",
                        ),
                        _buildDetailRow(
                          Icons.home_outlined,
                          "${targetUser.country}",
                        ),
                        _buildDetailRow(
                          Icons.cake_outlined,
                          "${targetUser.age} years old",
                        ),
                        _buildDetailRow(
                          targetUser.gender == 'Male'
                              ? Icons.male
                              : targetUser.gender == 'Female'
                              ? Icons.female
                              : Icons.transgender,
                          targetUser.gender,
                        ),
                      ],
                    ),
                  ),
                  Divider(thickness: 8, color: Colors.grey.shade300),

                  // Posts Header
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      "Posts",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Posts List
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (userPosts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("No posts found."),
                      ),
                    )
                  else
                    ...userPosts.map((doc) => _buildUserPost(doc)).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Same as profile_screen
  Widget _buildUserPost(DocumentSnapshot postDoc) {
    // Basic post card, simplified for brevity but matching styles
    final data = postDoc.data() as Map<String, dynamic>;
    final caption = data['caption'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption.isNotEmpty)
            Padding(padding: const EdgeInsets.all(16.0), child: Text(caption)),
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              height: 200,
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
