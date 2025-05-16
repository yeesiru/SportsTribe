import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/home_page.dart';

class LeaderboardPage extends StatefulWidget {
  final int initialTabIndex;
  
  const LeaderboardPage({
    super.key,
    this.initialTabIndex = 2,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late int _currentTabIndex; 
  final List<LeaderboardUser> _users = [
    LeaderboardUser(
      id: 'current_user',
      name: 'You',
      points: 10000,
      rank: 0, 
      image: 'assets/images/profile.jpg',
      isCurrentUser: true,
    ),
    LeaderboardUser(
      id: 'user1',
      name: 'User 1',
      points: 100000,
      rank: 1,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user2',
      name: 'User 2',
      points: 99999,
      rank: 2,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user3',
      name: 'User 3',
      points: 99998,
      rank: 3,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user4',
      name: 'User 4',
      points: 99997,
      rank: 4,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user5',
      name: 'User 5',
      points: 99996,
      rank: 5,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user6',
      name: 'User 6',
      points: 99995,
      rank: 6,
      image: 'assets/images/profile.jpg',
    ),
    LeaderboardUser(
      id: 'user7',
      name: 'User 7',
      points: 99994,
      rank: 7,
      image: 'assets/images/profile.jpg',
    ),
  ];
  
  List<LeaderboardUser> get _sortedUsers {
    List<LeaderboardUser> sorted = List.from(_users);
    sorted.sort((a, b) => b.points.compareTo(a.points));
    for (int i = 0; i < sorted.length; i++) {
      if (!sorted[i].isCurrentUser) {
        sorted[i].rank = i + 1;
      }
    }
    final currentUserIndex = sorted.indexWhere((user) => user.isCurrentUser);
    if (currentUserIndex >= 0) {
      sorted[currentUserIndex].rank = currentUserIndex + 1;
      final currentUser = sorted.removeAt(currentUserIndex);
      sorted.insert(0, currentUser);
    }
    
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  void _navigateToPage(int index) {
    if (index == _currentTabIndex) return; 
    
    setState(() {
      _currentTabIndex = index;
    });
    
    switch (index) {
      case 0: 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => HomePage(initialTabIndex: 0)),
        );
        break;
      case 1: 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ChatPage(initialTabIndex: 1)),
        );
        break;
      case 2: 
        break;
      case 3: 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ProfilePage(initialTabIndex: 3)),
        );
        break;
    }
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
                  color: isActive ? Colors.black.withOpacity(0.1) : Colors.transparent,
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/leaderboard.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '100 points earned this month',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          children: [
                            SizedBox(width: 40),
                            Expanded(
                              child: Text(
                                'Rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '',
                              ),
                            ),
                            Text(
                              'Point',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Divider(height: 1),
                      
                      // Leaderboard list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _sortedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _sortedUsers[index];
                            final isCurrentUser = user.isCurrentUser;
                            
                            return Container(
                              color: isCurrentUser ? Colors.grey[200] : null,
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Text(
                                        isCurrentUser ? 'You' : user.rank.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundImage: AssetImage(user.image),
                                    radius: 18,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    user.points.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                }
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline, 
                isActive: _currentTabIndex == 1,
                onTap: () {
                  _navigateToPage(1);
                }
              ),
              _buildNavItem(
                icon: Icons.rocket, 
                isActive: _currentTabIndex == 2,
                onTap: () {
                  // Already on leaderboard page
                }
              ),
              _buildNavItem(
                icon: Icons.person_outline, 
                isActive: _currentTabIndex == 3,
                onTap: () {
                  _navigateToPage(3);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardUser {
  final String id;
  final String name;
  final int points;
  int rank;
  final String image;
  final bool isCurrentUser;
  
  LeaderboardUser({
    required this.id,
    required this.name,
    required this.points,
    required this.rank,
    required this.image,
    this.isCurrentUser = false,
  });
} 