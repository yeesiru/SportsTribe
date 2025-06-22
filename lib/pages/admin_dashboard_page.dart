import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/admin_manage_reward.dart';
import 'package:map_project/pages/admin_manage_clubs_page.dart';
import 'package:map_project/pages/admin_manage_users_page.dart';
import 'package:map_project/pages/admin_reports_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _tabs = ['Users', 'Clubs', 'Reports', 'Rewards'];

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('Logout'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text('Logging out...'),
                  ],
                ),
              ),
            );
          },
        );

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        // Navigate back to auth page (MainPage will handle this automatically)
        // No need to manually navigate as the StreamBuilder in MainPage will detect
        // the auth state change and redirect to AuthPage
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFD4FF3D), // Lime green color from the image
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),            ),
            Spacer(),
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                int index = entry.key;
                String tab = entry.value;
                bool isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(                    
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });

                      if (index == 3) { // Rewards tab
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RewardManagementPage(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildUsersList();
      case 1:
        return _buildClubsList();
      case 2:
        return _buildReportsList();
      case 3:
        // This case should never be reached since we navigate directly
        return Container(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      default:
        return _buildUsersList();
    }
  }
  Widget _buildUsersList() {
    return AdminManageUsersPage();
  }
  Widget _buildClubsList() {
    return AdminManageClubsPage();
  }
  Widget _buildReportsList() {
    return AdminReportsPage();
  }
}
