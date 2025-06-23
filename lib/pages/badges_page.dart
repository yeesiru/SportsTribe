import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/points_badge_service.dart';
import '../models/badge.dart' as BadgeModel;

class BadgesPage extends StatefulWidget {
  const BadgesPage({Key? key}) : super(key: key);

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  Map<String, dynamic> _badgeProgress = {};

  @override
  void initState() {
    super.initState();
    _loadBadgeProgress();
  }

  Future<void> _loadBadgeProgress() async {
    try {
      Map<String, dynamic> progress = await PointsBadgeService.getBadgeProgress(user.uid);
      setState(() {
        _badgeProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading badge progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Badges',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD7F520), Color(0xFFB8D404)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your achievements...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBadgeProgress,                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD7F520),
                              Color(0xFFB8D404),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD7F520).withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(                              'Achievement Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [                                _buildStatItem(
                                  'Earned',
                                  '${_badgeProgress['earnedBadges'] ?? 0}',
                                  Icons.emoji_events,
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.1),
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildStatItem(
                                  'Total',
                                  '${_badgeProgress['totalBadges'] ?? 0}',
                                  Icons.military_tech,
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.1),
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildStatItem(
                                  'Progress',
                                  '${((_badgeProgress['earnedBadges'] ?? 0) / (_badgeProgress['totalBadges'] ?? 1) * 100).toInt()}%',
                                  Icons.trending_up,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Section Title
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD7F520), Color(0xFFB8D404)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'All Badges',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),                      if (_badgeProgress['progress'] != null)                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7, // Reduced to give more height
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _badgeProgress['progress'].length,
                          itemBuilder: (context, index) {
                          Map<String, dynamic> badgeData = _badgeProgress['progress'][index];
                          BadgeModel.Badge badge = badgeData['badge'];
                          bool earned = badgeData['earned'];
                          double progress = badgeData['progress'];
                          int currentCount = badgeData['currentCount'];
                          int requiredCount = badgeData['requiredCount'];

                          return _buildBadgeCard(
                            badge,
                            earned,
                            progress,
                            currentCount,
                            requiredCount,
                          );
                        },
                      )                      else
                        Container(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[200]!,
                                        Colors.grey[100]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'No badges available yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start attending events to earn your first badge!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    height: 1.4,
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
    );
  }  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }Widget _buildBadgeCard(
    BadgeModel.Badge badge,
    bool earned,
    double progress,
    int currentCount,
    int requiredCount,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),        border: Border.all(
          color: earned 
              ? Color(0xFFD7F520) 
              : Color(0xFFE5E7EB),
          width: earned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: earned 
                ? Color(0xFFD7F520).withOpacity(0.3)
                : Color(0xFF1F2937).withOpacity(0.08),
            blurRadius: earned ? 12 : 8,
            offset: Offset(0, earned ? 6 : 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(                gradient: earned 
                    ? LinearGradient(
                        colors: [Color(0xFFD7F520), Color(0xFFB8D404)],
                      )
                    : LinearGradient(
                        colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                      ),
                shape: BoxShape.circle,                boxShadow: earned ? [
                  BoxShadow(
                    color: Color(0xFFD7F520).withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ] : [],
              ),
              child: Center(
                child: Text(
                  badge.iconPath,
                  style: TextStyle(
                    fontSize: 28,
                    color: earned ? Colors.black87 : Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Badge Name
            Flexible(
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: earned ? Color(0xFF1F2937) : Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 6),

            // Badge Description
            Flexible(
              child: Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 12),

            // Progress or Status
            if (earned)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(                  gradient: LinearGradient(
                    colors: [Color(0xFFD7F520), Color(0xFFB8D404)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFD7F520).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 4),                    Text(
                      'Earned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            else if (badge.category == 'participation')
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar
                  Container(
                    width: double.infinity,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD7F520), Color(0xFFB8D404)],
                              ),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '$currentCount / $requiredCount events',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Special Achievement',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
