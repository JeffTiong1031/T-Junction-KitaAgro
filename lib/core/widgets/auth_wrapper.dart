import 'package:flutter/material.dart';
import '../../features/auth/welcome_screen.dart';
import '../../main_layout.dart';
import '../../features/auth/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../features/auth/complete_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthService is static or singleton is better, but here creating a new instance
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return const WelcomeScreen();
          }

          // User is logged in, now check if profile is complete
          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData &&
                  userSnapshot.data != null &&
                  userSnapshot.data!.exists) {
                final userModel = UserModel.fromMap(
                  userSnapshot.data!.data() as Map<String, dynamic>,
                );
                // Check if profile is incomplete
                if (userModel.town == 'Not Specified' || userModel.age == 0) {
                  return CompleteProfileScreen(user: userModel);
                }
                return const MainLayout();
              } else if (userSnapshot.connectionState == ConnectionState.done) {
                // User exists in Auth but not Firestore (Rare edge case)
                // Create a temporary model to allow completion
                UserModel tempUser = UserModel(
                  uid: user.uid,
                  email: user.email ?? '',
                  username:
                      user.displayName ?? 'User${user.uid.substring(0, 5)}',
                  fullName: user.displayName ?? '',
                  age: 0,
                  gender: 'Not Specified',
                  town: 'Not Specified',
                  state: 'Not Specified',
                  country: 'Not Specified',
                  role: 'Farmer',
                  createdAt: DateTime.now(),
                );
                return CompleteProfileScreen(user: tempUser);
              }

              // Fallback
              return const MainLayout();
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
