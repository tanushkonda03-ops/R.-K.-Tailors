import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'complete_profile_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connecting/waiting for auth cache
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // If no user is logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Check if the user document exists and handle roles
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (docSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Error fetching user role.")),
              );
            }

            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>;
              final isAdmin = data['isAdmin'] == true;
              final username = data['username'] as String? ?? 'User';

              if (isAdmin) {
                return AdminDashboard(username: username);
              } else {
                return HomeScreen(username: username);
              }
            } else {
              // User exists in Auth but missing Firestore doc (Google SSO new user case)
              // Route to Complete Profile
              return CompleteProfileScreen(
                uid: snapshot.data!.uid,
                email: snapshot.data!.email ?? '',
              );
            }
          },
        );
      },
    );
  }
}
