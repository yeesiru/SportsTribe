// Point Center Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gamification_models.dart';
import '../services/gamification_service.dart';
import '../utils/colors.dart';

class PointCenterScreen extends StatefulWidget {
  const PointCenterScreen({Key? key}) : super(key: key);

  @override
  _PointCenterScreenState createState() => _PointCenterScreenState();
}

class _PointCenterScreenState extends State<PointCenterScreen> {
  final GamificationService _gamificationService = GamificationService();
  
  List<Achievement> _achievements = [];
  List<UserAchievement> _userAchievements = [];
  UserPoints? _userPoints;
  
  bool _isLoading = true;
  String _userId = "current_user_id"; // In a real app, get this from auth service

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load points, achievements, and user progress in parallel
      final futures = await Future.wait([
        _gamificationService.getUserPoints(_userId),
        _gamificationService.getAchievements(),
        _gamificationService.getUserAchievements(_userId),
      ]);

      setState(() {
        _userPoints = futures[0] as UserPoints?;
        _achievements = futures[1] as List<Achievement>;
        _userAchievements = futures[2] as List<UserAchievement>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  // Find user's progress for a specific achievement
  UserAchievement? _getUserAchievementProgress(String achievementId) {
    try {
      return _userAchievements.firstWhere(
        (ua) => ua.achievementId == achievementId,
      );
    } catch (e) {
      // No progress found
      return null;
    }
  }

  // Calculate completion percentage
  double _getCompletionPercentage(UserAchievement? userAchievement) {
    if (userAchievement == null) return 0.0;
    if (userAchievement.maxProgress <= 0) return 0.0;
    
    double percentage = userAchievement.progress / userAchievement.maxProgress;
    return percentage > 1.0 ? 1.0 : percentage;
  }

  // Handle claim button press
  Future<void> _claimAchievement(Achievement achievement, UserAchievement? userAchievement) async {
    // Only proceed if achievement is completed but not claimed
    if (userAchievement == null || userAchievement.progress < userAchievement.maxProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the achievement to claim rewards')),
      );
      return;
    }

    if (userAchievement.dateEarned != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward already claimed')),
      );
      return;
    }

    try {
      // Update the achievement as claimed (dateEarned gets set)
      await _gamificationService.updateAchievementProgress(
        _userId, 
        achievement.id, 
        userAchievement.maxProgress
      );
      
      // Reload data
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+ ${achievement.pointsReward} points earned!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to claim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                            'Point Center',
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

                  // Points display
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/medal_badge.png',
                              width: 100,
                              height: 100,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 42,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_userPoints?.currentPoints ?? 0} Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to rewards screen
                            Navigator.pushNamed(context, '/rewards');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Redeem Now'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Level progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        const Text(
                          'Lv1',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: Colors.grey[700],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '65/100',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Achievements list
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _achievements.length,
                        itemBuilder: (context, index) {
                          final achievement = _achievements[index];
                          final userAchievement = _getUserAchievementProgress(achievement.id);
                          final progressPercentage = _getCompletionPercentage(userAchievement);
                          final isCompleted = userAchievement != null && 
                                             userAchievement.progress >= userAchievement.maxProgress;
                          final isClaimed = userAchievement != null && userAchievement.dateEarned != null;
                          
                          // Achievement icon based on category
                          IconData achievementIcon;
                          switch (achievement.iconAsset) {
                            case 'Users':
                              achievementIcon = Icons.people;
                              break;
                            case 'Award':
                              achievementIcon = Icons.sports_basketball;
                              break;
                            case 'MessageSquare':
                              achievementIcon = Icons.chat;
                              break;
                            case 'UserPlus':
                              achievementIcon = Icons.person_add;
                              break;
                            case 'Heart':
                              achievementIcon = Icons.favorite;
                              break;
                            default:
                              achievementIcon = Icons.emoji_events;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Achievement icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    achievementIcon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Achievement details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        achievement.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reward: ${achievement.pointsReward} points',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (!isCompleted || !isClaimed)
                                        LinearProgressIndicator(
                                          value: progressPercentage,
                                          backgroundColor: Colors.grey[700],
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Claim button
                                if (isCompleted && !isClaimed)
                                  ElevatedButton(
                                    onPressed: () => _claimAchievement(achievement, userAchievement),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('CLAIM'),
                                  )
                                else if (isClaimed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'CLAIMED',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'CLAIM',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
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
    );
  }
}