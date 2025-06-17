import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/main_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/home_page.dart';

class ProfilePage extends StatefulWidget {
  final int initialTabIndex;

  const ProfilePage({
    super.key,
    this.initialTabIndex = 3,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;

  // Profile information
  String username = '';
  String birthDate = 'Not yet set';
  String gender = 'Not yet set';
  String photoUrl = '';
  String email = '';
  String role = '';
  List<dynamic> sportsList = [];
  List<dynamic> communityList = [];
  List<dynamic> eventList = [];
  bool mySportsEnabled = true;
  bool myCommunityEnabled = true;
  late int _currentTabIndex; // Profile tab is active

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        username = data['name'] ?? '';
        birthDate = data['birthDate'] ?? 'Not yet set';
        gender = data['gender'] ?? 'Not yet set';
        photoUrl = data['photoUrl'] ?? '';
        email = data['email'] ?? user.email ?? '';
        role = data['role'] ?? '';
        sportsList = data['sportsList'] ?? [];
        communityList = data['communityList'] ?? [];
        eventList = data['eventList'] ?? [];
      });
    }
  }

  Future<void> _updateUserProfile(Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);
      await _fetchUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editField(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateUserProfile({field: controller.text.trim()});
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editListField(String field, List<dynamic> currentList) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${currentList.join(", ")}'),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Add new item',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newItem = controller.text.trim();
              if (newItem.isNotEmpty) {
                final updatedList = List<String>.from(currentList)..add(newItem);
                await _updateUserProfile({field: updatedList});
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    if (index == _currentTabIndex) return; // Already on this page

    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(initialTabIndex: 0)),
        );
        break;
      case 1: // Chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(initialTabIndex: 1)),
        );
        break;
      case 2: // Leaderboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LeaderboardPage(initialTabIndex: 2)),
        );
        break;
      case 3: // Profile
        // Already on profile, no navigation needed
        break;
    }
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    bool isToggleable = false,
    bool toggleValue = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500]),
          ),
          Spacer(),
          if (isToggleable)
            Switch(
              value: toggleValue,
              onChanged: (value) {
                onTap();
              },
              activeColor: Colors.green,
              activeTrackColor: Colors.green[100],
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.black.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
              if (hasNotification)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          if (isActive)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 40),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 16),
                    Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profile Avatar
          Transform.translate(
            offset: Offset(0, -40),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                ),
                // Bottom right upload icon
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.file_upload_outlined,
                        color: Colors.purple[300],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.person_outline,
                      label: 'Username',
                      value: username,
                      onTap: () {
                        _editField('name', username);
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.calendar_today,
                      label: 'Birth Date',
                      value: birthDate,
                      onTap: () {
                        _editField('birthDate', birthDate);
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.wc,
                      label: 'Gender',
                      value: gender,
                      onTap: () {
                        _editField('gender', gender);
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: email,
                      onTap: () {}, // Email is not editable here
                    ),
                    _buildProfileItem(
                      icon: Icons.sports_volleyball,
                      label: 'My Sports',
                      value: sportsList.isNotEmpty ? sportsList.join(', ') : 'None',
                      onTap: () {
                        _editListField('sportsList', sportsList);
                      },
                    ),

                    SizedBox(height: 120),
                    // Logout button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Sign Out'),
                              content:
                                  Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    // Replace entire navigation stack with MainPage
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) => MainPage()),
                                        (route) => false);
                                  },
                                  child: Text('Sign Out'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.logout),
                        label: Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    // Add bottom padding to account for navbar
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  icon: Icons.group,
                  isActive: _currentTabIndex == 0,
                  onTap: () {
                    _navigateToPage(0);
                  }),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  isActive: _currentTabIndex == 1,
                  onTap: () {
                    _navigateToPage(1);
                  }),
              _buildNavItem(
                  icon: Icons.rocket,
                  isActive: _currentTabIndex == 2,
                  onTap: () {
                    _navigateToPage(2);
                  },
                  hasNotification: true),
              _buildNavItem(
                  icon: Icons.person_outline,
                  isActive: _currentTabIndex == 3,
                  onTap: () {
                    // Already on profile page
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
