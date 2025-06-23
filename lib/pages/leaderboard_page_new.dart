import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/home_page.dart';
import 'package:map_project/pages/badges_page.dart';
import '../services/points_badge_service.dart';

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
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  Map<String, dynamic> _userRanking = {};

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      List<Map<String, dynamic>> leaderboard = await PointsBadgeService.getLeaderboard(limit: 100);
      Map<String, dynamic> userRanking = await PointsBadgeService.getUserRanking(user.uid);
      
      setState(() {
        _leaderboardData = leaderboard;
        _userRanking = userRanking;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToBadges() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BadgesPage()),
    );
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
          MaterialPageRoute(builder: (context) => const HomePage(initialTabIndex: 0)),
        );
        break;
      case 1: 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const ChatPage(initialTabIndex: 1)),
        );
        break;
      case 2: 
        break;
      case 3: 
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const ProfilePage(initialTabIndex: 3)),
        );
        break;
    }
  }

  Widget _buildRankWidget(int rank) {
    if (rank <= 3) {
      Color medalColor;
      IconData medalIcon;
      
      switch (rank) {
        case 1:
          medalColor = Colors.amber;
          medalIcon = Icons.looks_one;
          break;
        case 2:
          medalColor = Colors.grey[400]!;
          medalIcon = Icons.looks_two;
          break;
        case 3:
          medalColor = Colors.brown[400]!;
          medalIcon = Icons.looks_3;
          break;
        default:
          medalColor = Colors.grey;
          medalIcon = Icons.circle;
      }
      
      return Icon(
        medalIcon,
        color: medalColor,
        size: 24,
      );
    } else {
      return Text(
        rank.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
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
              Icon(
                icon,
                color: isActive ? const Color(0xFFD7F520) : Colors.grey,
                size: 24,
              ),
              if (hasNotification)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFD7F520),
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
      body: Container(
        decoration: const BoxDecoration(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leaderboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _isLoading 
                                ? 'Loading...'
                                : 'Your rank: #${_userRanking['rank'] ?? 'N/A'} with ${_userRanking['points'] ?? 0} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badges button
                    IconButton(
                      onPressed: _navigateToBadges,
                      icon: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'My Badges',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                children: [
                                  const SizedBox(width: 40),
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
                                      'Player',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Points',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Divider
                            const Divider(height: 1),
                            
                            // Leaderboard list
                            Expanded(
                              child: _leaderboardData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.leaderboard,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No leaderboard data yet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Attend events to earn points!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadLeaderboard,
                                      child: ListView.builder(
                                        itemCount: _leaderboardData.length,
                                        itemBuilder: (context, index) {
                                          final userData = _leaderboardData[index];
                                          final isCurrentUser = userData['userId'] == user.uid;
                                          
                                          return Container(
                                            color: isCurrentUser ? Colors.blue[50] : null,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  child: Center(
                                                    child: _buildRankWidget(userData['rank']),
                                                  ),
                                                ),
                                                CircleAvatar(
                                                  backgroundImage: userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty
                                                      ? NetworkImage(userData['photoUrl']) as ImageProvider
                                                      : const AssetImage('assets/images/profile.jpg'),
                                                  radius: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        isCurrentUser ? 'You' : userData['name'],
                                                        style: TextStyle(
                                                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                                          color: isCurrentUser ? Colors.blue[800] : Colors.black87,
                                                        ),
                                                      ),
                                                      if (userData['badges'] != null && userData['badges'].isNotEmpty)
                                                        Text(
                                                          '${userData['badges'].length} badges',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      userData['points'].toString(),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: isCurrentUser ? Colors.blue[800] : Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${userData['attendedEvents']} events',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
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
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
