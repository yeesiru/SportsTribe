import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/auth_page.dart';
import 'package:map_project/pages/login_page.dart';
import 'package:map_project/pages/home_page.dart';
import 'package:map_project/pages/profile_setup_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Check if user has completed their profile using StreamBuilder
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  print('User data: $userData'); // Debug print
                  
                  // Check if essential profile fields are filled
                  if (userData['name'] != null && 
                      userData['name'].toString().trim().isNotEmpty &&
                      userData['birthDate'] != null && 
                      userData['birthDate'].toString().trim().isNotEmpty) {
                    print('Profile is complete, navigating to HomePage'); // Debug print
                    // Profile is complete, show home page
                    return HomePage();
                  }
                }
                
                print('Profile is incomplete, showing ProfileSetupPage'); // Debug print
                // Profile is incomplete or doesn't exist, show profile setup
                return const ProfileSetupPage();
              },
            );
          } else {
            return AuthPage();
          }
        },
      ),
    );
  }
}
