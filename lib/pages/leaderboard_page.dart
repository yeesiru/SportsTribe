// Leaderboard Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gamification_models.dart';
import '../services/gamification_service.dart';
import '../utils/colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GamificationService _gamificationService = GamificationService();
  List<UserRanking> _leaderboard = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // In a real app, get the current user ID from your auth service
    _currentUserId = "current_user_id";
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final leaderboard = await _gamificationService.getLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leaderboard: $e')),
      );
    }
  }

  Color? _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[300]; // Silver
      case 3:
        return Colors.brown[300]; // Bronze
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the appbar
                ],
              ),
            ),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Top players by total points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leaderboard table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    SizedBox(
                      width: 40,
                      child: Text(
                        'Rank',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Points',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Leaderboard list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _leaderboard.length,
                      itemBuilder: (context, index) {
                        final ranking = _leaderboard[index];
                        final isCurrentUser = ranking.userId == _currentUserId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.blueAccent.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                // Rank
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    ranking.rank.toString(),
                                    style: TextStyle(
                                      color: _getMedalColor(ranking.rank) ??
                                          Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // User avatar and name
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      ranking.profileImage.isNotEmpty
                                          ? NetworkImage(ranking.profileImage)
                                          : null,
                                  child: ranking.profileImage.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ranking.username,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.blueAccent
                                          : Colors.white,
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : null,
                                    ),
                                  ),
                                ),
                                // Points
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    ranking.points.toString(),
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.blueAccent
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom navigation
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.people, color: Colors.white),
                    onPressed: () {
                      // Already on leaderboard
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white54),
                    onPressed: () {
                      // Navigate to chat
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sports_basketball,
                        color: Colors.white54),
                    onPressed: () {
                      // Navigate to events
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white54),
                    onPressed: () {
                      // Navigate to profile
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
