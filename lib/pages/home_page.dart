import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/createClub_page.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/club_details_page.dart';
import 'package:map_project/pages/create_event.dart';
import 'package:map_project/pages/create_post.dart';
import 'package:map_project/pages/browse_community.dart';

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

  // Fetch club where creatorID match userID
  Stream<QuerySnapshot> getUserRelatedClubs() {
    final uid = user.uid;
    return FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .snapshots();
  }

  // Fetch all public and user clubs
  Future<List<String>> _getRelevantClubIds() async {
    final uid = user.uid;
    final userClubsSnap = await FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .get();
    final publicClubsSnap = await FirebaseFirestore.instance
        .collection('club')
        .where('isPrivate', isEqualTo: false)
        .get();
    final userClubIds = userClubsSnap.docs.map((doc) => doc.id).toSet();
    final publicClubIds = publicClubsSnap.docs.map((doc) => doc.id).toSet();
    return {...userClubIds, ...publicClubIds}.toList();
  }

  Future<List<Map<String, dynamic>>> _getAllClubItems(
      {required bool isEvent}) async {
    final clubIds = await _getRelevantClubIds();
    List<Map<String, dynamic>> allItems = [];
    for (final clubId in clubIds) {
      final snap = await FirebaseFirestore.instance
          .collection('club')
          .doc(clubId)
          .collection(isEvent ? 'events' : 'posts')
          .orderBy('createdAt', descending: true)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        data['clubId'] = clubId;
        data['id'] = doc.id;
        allItems.add(data);
      }
    }
    return allItems;
  }

  Widget _buildEventsOrPostsTab(bool isEvent) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllClubItems(isEvent: isEvent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
              child: Text(isEvent ? 'No events found.' : 'No posts found.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final data = items[idx];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                leading: data['imageUrl'] != null && data['imageUrl'] != ''
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(data['imageUrl']))
                    : CircleAvatar(
                        child: Icon(isEvent ? Icons.event : Icons.article)),
                title: Text(data['content'] ?? ''),
                subtitle: Text(data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp).toDate().toString()
                    : ''),
              ),
            );
          },
        );
      },
    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            // Navigate to Create Event page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateEventPage()),
            );
          } else {
            // Navigate to Create Post page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostPage()),
            );
          }
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green[200],
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.data == null ||
                              snapshot.data!.docs.isEmpty) {
                            // No communities joined, show only Join Community
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BrowseCommunityPage(),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey[200],
                                        child: Icon(Icons.group_add,
                                            color: Colors.grey[800]),
                                      ),
                                      SizedBox(height: 8),
                                      Text('Join community',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.chevron_right),
                              ],
                            );
                          }
                          // Show all clubs the user is related to
                          return Row(
                            children: [
                              ...snapshot.data!.docs.map((doc) {
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
                                          backgroundImage: club['imageUrl'] !=
                                                  null
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
                              SizedBox(width: 10),
                              // Join community column (static)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BrowseCommunityPage(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(Icons.group_add,
                                          color: Colors.grey[800]),
                                    ),
                                    SizedBox(height: 8),
                                    Text('Join community',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.chevron_right),
                            ],
                          );
                        },
                      ),
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
          Expanded(
            child: _selectedIndex == 0
                ? _buildEventsOrPostsTab(true)
                : _buildEventsOrPostsTab(false),
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
