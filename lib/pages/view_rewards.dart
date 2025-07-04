import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/points_badge_service.dart';

class UserViewRewardsPage extends StatefulWidget {
  const UserViewRewardsPage({Key? key}) : super(key: key);

  @override
  State<UserViewRewardsPage> createState() => _UserViewRewardsPageState();
}

class _UserViewRewardsPageState extends State<UserViewRewardsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _userPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userPoints = userData['points'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rewards Store',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Color(0xFFD7F520),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.black87, size: 20),
                SizedBox(width: 6),
                Text(
                  '$_userPoints',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black87),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading rewards...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rewards')
                  .where('availability', isEqualTo: 'Available')
                  .snapshots(),
              builder: (context, snapshot) {
                print(
                    'Rewards query - Connection state: ${snapshot.connectionState}');
                print('Rewards query - Has error: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('Rewards query error: ${snapshot.error}');
                }
                print('Rewards query - Has data: ${snapshot.hasData}');
                if (snapshot.hasData) {
                  print(
                      'Rewards query - Document count: ${snapshot.data!.docs.length}');
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        SizedBox(height: 16),
                        Text(
                          'Error loading rewards',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Container(
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black87),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  );
                }

                final rewards = snapshot.data!.docs;

                if (rewards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No rewards available',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back later for new rewards!',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadUserPoints,
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final rewardDoc = rewards[index];
                      final rewardData =
                          rewardDoc.data() as Map<String, dynamic>;
                      final canAfford =
                          _userPoints >= (rewardData['pointsCost'] ?? 0);
                      final isAvailable = (rewardData['quantity'] == null) ||
                          ((rewardData['redeemedCount'] ?? 0) <
                              rewardData['quantity']);

                      return _buildRewardCard(
                          rewardDoc, rewardData, canAfford, isAvailable);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRewardCard(QueryDocumentSnapshot rewardDoc,
      Map<String, dynamic> rewardData, bool canAfford, bool isAvailable) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              canAfford && isAvailable ? Color(0xFFD7F520) : Colors.grey[200]!,
          width: canAfford && isAvailable ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: canAfford && isAvailable
                ? Color(0xFFD7F520).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reward Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFD7F520).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: rewardData['imageUrl'] != null &&
                        rewardData['imageUrl'].isNotEmpty
                    ? Image.network(
                        rewardData['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.card_giftcard,
                              size: 40,
                              color: Color(0xFFB8D404),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: Color(0xFFB8D404),
                        ),
                      ),
              ),
            ),
          ), // Reward Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    rewardData['name'] ?? 'Reward',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2),

                  // Description
                  if (rewardData['description'] != null &&
                      rewardData['description'].isNotEmpty)
                    Flexible(
                      child: Text(
                        rewardData['description'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  Spacer(),

                  // Points and Button
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: Color(0xFFB8D404),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${rewardData['pointsCost'] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB8D404),
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        height: 24,
                        child: ElevatedButton(
                          onPressed: canAfford && isAvailable
                              ? () => _redeemReward(rewardDoc, rewardData)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford && isAvailable
                                ? Color(0xFFD7F520)
                                : Colors.grey[400],
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            !isAvailable
                                ? 'Sold Out'
                                : canAfford
                                    ? 'Redeem'
                                    : 'Need ${(rewardData['pointsCost'] ?? 0) - _userPoints}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: canAfford && isAvailable
                                  ? Colors.black87
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _redeemReward(
      QueryDocumentSnapshot rewardDoc, Map<String, dynamic> rewardData) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFD7F520)),
            SizedBox(width: 12),
            Text("Confirm Redemption"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to redeem this reward?",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardData['name'] ?? 'Reward',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Color(0xFFD7F520), size: 20),
                      SizedBox(width: 6),
                      Text(
                        '${rewardData['pointsCost'] ?? 0} points',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB8D404),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Remaining balance: ${_userPoints - (rewardData['pointsCost'] ?? 0)} points',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD7F520),
            ),
            child: Text(
              "Redeem",
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing redemption...'),
                ],
              ),
            ),
          ),
        );

        // Attempt redemption
        bool success = await PointsBadgeService.redeemReward(
          rewardDoc.id,
          rewardData['pointsCost'] ?? 0,
        );

        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Update local points
          await _loadUserPoints();

          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Success!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reward redeemed successfully!',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'An admin will contact you soon to arrange delivery of your reward.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Error'),
                ],
              ),
              content: Text(
                'Failed to redeem reward. You may not have enough points or the reward may no longer be available.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still open
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
