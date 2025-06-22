import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/auth_page.dart';
import 'package:map_project/pages/home_page.dart';
import 'package:map_project/pages/profile_setup_page.dart';
import 'package:map_project/pages/admin_dashboard_page.dart';

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
                  .snapshots(),              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (userSnapshot.hasError) {
                  print('Error loading user data: ${userSnapshot.error}');
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading user profile'),
                          SizedBox(height: 8),
                          Text('Please try again later'),
                        ],
                      ),
                    ),
                  );
                }
                
                // Check if user document exists and has data
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final data = userSnapshot.data!.data();
                  
                  // Safe type casting with null check
                  if (data != null && data is Map<String, dynamic>) {
                    final userData = data;
                    print('User data: $userData'); // Debug print
                    
                    // Check if essential profile fields are filled
                    final name = userData['name']?.toString().trim() ?? '';
                    final birthDate = userData['birthDate']?.toString().trim() ?? '';
                    
                    if (name.isNotEmpty && birthDate.isNotEmpty) {
                      print('Profile is complete, checking user role...'); // Debug print
                      
                      // Profile is complete, now check user role for routing
                      final userRole = userData['role']?.toString() ?? 'member';
                      print('User role: $userRole'); // Debug print
                      
                      if (userRole == 'admin') {
                        print('Admin user detected, navigating to AdminDashboard'); // Debug print
                        return AdminDashboard();
                      } else {
                        print('Regular user detected, navigating to HomePage'); // Debug print
                        return HomePage();
                      }
                    }
                  }
                }
                
                print('Profile is incomplete or document does not exist, showing ProfileSetupPage'); // Debug print
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