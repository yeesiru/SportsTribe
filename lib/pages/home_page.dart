import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/createClub_page.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/club_details_page.dart';
import 'package:map_project/pages/browse_clubs_page.dart';

class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  late int _currentTabIndex; // 0 = home, 1 = chat, 2 = leaderboard, 3 = profile

  //Fetch club where creatorID match userID
  Stream<QuerySnapshot> getUserRelatedClubs() {
  final uid = user.uid;
  return FirebaseFirestore.instance
      .collection('club')
      .where('members', arrayContains: uid)
      .snapshots();
}

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPage(int index) {
    if (index == _currentTabIndex) return; // Already on this page

    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0:
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(initialTabIndex: 3)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage('assets/images/profile.jpg'),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Hi, ${user.displayName ?? user.email!.split('@')[0]}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.notifications_outlined),
                                onPressed: () {},
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateclubPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 5),
                        Text('520 pts',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // User's created communities (clubs)
                      StreamBuilder<QuerySnapshot>(
                        stream: getUserRelatedClubs(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green[200],
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }   
                          // Show all clubs the user is related to
                          return Row(
                            children: snapshot.data!.docs.map((doc) {
                              final club = doc.data() as Map<String, dynamic>;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClubDetailsPage(
                                        clubId: doc.id,
                                        clubData: club,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.green[200],
                                        backgroundImage: club['imageUrl'] != null
                                            ? NetworkImage(club['imageUrl'])
                                            : null,
                                        child: club['imageUrl'] == null
                                            ? Icon(Icons.sports_tennis,
                                                color: Colors.green[800])
                                            : null,
                                      ),
                                      SizedBox(height: 8),
                                      Text(club['name'] ?? 'My Club',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(width: 10),
                      // Join community column (static)                      
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrowseClubsPage(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: Icon(Icons.group_add, color: Colors.grey[800]),
                            ),
                            SizedBox(height: 8),
                            Text('Join community', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs for Events and Posts
          Container(
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Events',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedIndex == 0 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Posts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedIndex == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedIndex == 0)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 15),
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.green[200],
                              child: Icon(Icons.sports_tennis,
                                  color: Colors.green[800], size: 20),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Badminton Squad',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('25 mins ago',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Spacer(),
                            Icon(Icons.more_vert),
                          ],
                        ),
                        SizedBox(height: 15),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: [
                              TextSpan(
                                text: '🏸 Badminton Day! ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        Text('Join us for a day of smashes, rallies, and fun!'),
                        SizedBox(height: 5),
                        Text('📅 Date: 8 April 2025'),
                        Text('📍 Venue: Impian Emas Badminton Hall'),
                        Text('🎮 Categories: Singles, Doubles & Mixed'),
                        SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('#Badminton',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('#ShuttleSmash',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: Size(100, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('Join',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text('Posts tab content'),
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
                  onTap: () => _navigateToPage(0)),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  isActive: _currentTabIndex == 1,
                  onTap: () => _navigateToPage(1)),
              _buildNavItem(
                  icon: Icons.rocket,
                  isActive: _currentTabIndex == 2,
                  onTap: () => _navigateToPage(2),
                  hasNotification: true),
              _buildNavItem(
                  icon: Icons.person_outline,
                  isActive: _currentTabIndex == 3,
                  onTap: () => _navigateToPage(3)),
            ],
          ),
        ),
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
}
