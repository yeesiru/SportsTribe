// Firebase Services for Gamification & Rewards Module

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:map_project/models/gamification_models.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ACHIEVEMENTS

  // Get all available achievements
  Future<List<Achievement>> getAchievements() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('achievements').get();
      return snapshot.docs
          .map((doc) =>
              Achievement.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  // Get user's progress on achievements
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('userAchievements')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) =>
              UserAchievement.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  // Update achievement progress
  Future<void> updateAchievementProgress(
      String userId, String achievementId, int progress) async {
    try {
      // Get the achievement to check maxProgress
      DocumentSnapshot achievementDoc =
          await _firestore.collection('achievements').doc(achievementId).get();
      Achievement achievement = Achievement.fromFirestore(
          achievementDoc.data() as Map<String, dynamic>);

      // Get the user achievement
      QuerySnapshot userAchievementSnapshot = await _firestore
          .collection('userAchievements')
          .where('userId', isEqualTo: userId)
          .where('achievementId', isEqualTo: achievementId)
          .limit(1)
          .get();

      if (userAchievementSnapshot.docs.isEmpty) {
        // Create new user achievement
        UserAchievement userAchievement = UserAchievement(
          userId: userId,
          achievementId: achievementId,
          progress: progress,
          maxProgress: achievement.progressTrackingType == 'boolean'
              ? 1
              : int.parse(achievement.requirement),
        );

        await _firestore
            .collection('userAchievements')
            .add(userAchievement.toFirestore());
      } else {
        // Update existing user achievement
        String docId = userAchievementSnapshot.docs[0].id;
        UserAchievement userAchievement = UserAchievement.fromFirestore(
            userAchievementSnapshot.docs[0].data() as Map<String, dynamic>);

        int maxProgress = userAchievement.maxProgress;
        int newProgress = progress > maxProgress ? maxProgress : progress;

        // Check if achievement is newly completed
        bool newlyCompleted = userAchievement.progress < maxProgress &&
            newProgress >= maxProgress;

        await _firestore.collection('userAchievements').doc(docId).update({
          'progress': newProgress,
          'dateEarned': newlyCompleted
              ? FieldValue.serverTimestamp()
              : userAchievement.dateEarned,
        });

        // If achievement is completed, award points
        if (newlyCompleted) {
          await awardPoints(userId, achievement.pointsReward, 'achievement',
              'Completed achievement: ${achievement.title}', achievementId);
        }
      }
    } catch (e) {
      print('Error updating achievement progress: $e');
    }
  }

  // REWARDS

  // Get all available rewards
  Future<List<Reward>> getRewards() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('rewards').get();
      return snapshot.docs
          .map(
              (doc) => Reward.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting rewards: $e');
      return [];
    }
  }

  // Get rewards by category
  Future<List<Reward>> getRewardsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rewards')
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs
          .map(
              (doc) => Reward.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting rewards by category: $e');
      return [];
    }
  }

  // Get user's redeemed rewards
  Future<List<UserReward>> getUserRewards(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('userRewards')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) =>
              UserReward.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user rewards: $e');
      return [];
    }
  }

  // Redeem a reward
  Future<bool> redeemReward(String userId, String rewardId) async {
    try {
      // Get the reward
      DocumentSnapshot rewardDoc =
          await _firestore.collection('rewards').doc(rewardId).get();
      Reward reward =
          Reward.fromFirestore(rewardDoc.data() as Map<String, dynamic>);

      // Get user points
      DocumentSnapshot userPointsDoc =
          await _firestore.collection('userPoints').doc(userId).get();

      if (!userPointsDoc.exists) {
        return false; // User doesn't have points record
      }

      UserPoints userPoints = UserPoints.fromFirestore(
          userPointsDoc.data() as Map<String, dynamic>);

      // Check if user has enough points
      if (userPoints.currentPoints < reward.pointsCost) {
        return false; // Not enough points
      }

      // Check if reward is available (quantity and dates)
      if (reward.quantityAvailable <= 0) {
        return false; // No more rewards available
      }

      DateTime now = DateTime.now();
      if (reward.startDate != null && reward.startDate!.isAfter(now)) {
        return false; // Reward not yet available
      }

      if (reward.endDate != null && reward.endDate!.isBefore(now)) {
        return false; // Reward expired
      }

      // Generate reward code (in a real app, this could be more sophisticated)
      String code =
          'RWD${reward.id}${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Create user reward record
      UserReward userReward = UserReward(
        userId: userId,
        rewardId: rewardId,
        dateRedeemed: now,
        status: 'claimed',
        code: code,
      );

      await _firestore.collection('userRewards').add(userReward.toFirestore());

      // Deduct points from user
      await _firestore.collection('userPoints').doc(userId).update({
        'currentPoints': FieldValue.increment(-reward.pointsCost),
        'history': FieldValue.arrayUnion([
          {
            'date': FieldValue.serverTimestamp(),
            'points': -reward.pointsCost,
            'source': 'reward_redemption',
            'description': 'Redeemed reward: ${reward.title}',
            'referenceId': rewardId,
          }
        ])
      });

      // Update reward quantity
      await _firestore
          .collection('rewards')
          .doc(rewardId)
          .update({'quantityAvailable': FieldValue.increment(-1)});

      return true;
    } catch (e) {
      print('Error redeeming reward: $e');
      return false;
    }
  }

  // POINTS AND LEADERBOARD

  // Get user points
  Future<UserPoints?> getUserPoints(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('userPoints').doc(userId).get();

      if (!doc.exists) {
        // Create new user points record if it doesn't exist
        UserPoints newUserPoints = UserPoints(
          userId: userId,
          totalPoints: 0,
          currentPoints: 0,
          history: [],
        );

        await _firestore
            .collection('userPoints')
            .doc(userId)
            .set(newUserPoints.toFirestore());
        return newUserPoints;
      }

      return UserPoints.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting user points: $e');
      return null;
    }
  }

  // Award points to user
  Future<void> awardPoints(String userId, int points, String source,
      String description, String? referenceId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('userPoints').doc(userId).get();

      if (!doc.exists) {
        // Create new user points record
        UserPoints userPoints = UserPoints(
          userId: userId,
          totalPoints: points,
          currentPoints: points,
          history: [
            PointsHistory(
              date: DateTime.now(),
              points: points,
              source: source,
              description: description,
              referenceId: referenceId,
            )
          ],
        );

        await _firestore
            .collection('userPoints')
            .doc(userId)
            .set(userPoints.toFirestore());
      } else {
        // Update existing user points record
        await _firestore.collection('userPoints').doc(userId).update({
          'totalPoints': FieldValue.increment(points),
          'currentPoints': FieldValue.increment(points),
          'history': FieldValue.arrayUnion([
            {
              'date': FieldValue.serverTimestamp(),
              'points': points,
              'source': source,
              'description': description,
              'referenceId': referenceId,
            }
          ])
        });
      }

      // Update leaderboard (only for positive points)
      if (points > 0) {
        await updateLeaderboard(userId, points);
      }
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  // Get leaderboard
  Future<List<UserRanking>> getLeaderboard({int limit = 100}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      List<UserRanking> rankings = [];
      int rank = 1;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        rankings.add(UserRanking(
          userId: data['userId'],
          username: data['username'],
          profileImage: data['profileImage'],
          points: data['points'],
          rank: rank,
        ));
        rank++;
      }

      return rankings;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Update leaderboard
  Future<void> updateLeaderboard(String userId, int pointsToAdd) async {
    try {
      // Get user info from users collection
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return; // User doesn't exist
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Check if user already exists in leaderboard
      DocumentSnapshot leaderboardDoc =
          await _firestore.collection('leaderboard').doc(userId).get();

      if (!leaderboardDoc.exists) {
        // Create new leaderboard entry
        await _firestore.collection('leaderboard').doc(userId).set({
          'userId': userId,
          'username': userData['username'] ?? 'User',
          'profileImage': userData['profileImage'] ?? '',
          'points': pointsToAdd,
        });
      } else {
        // Update existing leaderboard entry
        await _firestore.collection('leaderboard').doc(userId).update({
          'points': FieldValue.increment(pointsToAdd),
          'username': userData['username'] ?? 'User',
          'profileImage': userData['profileImage'] ?? '',
        });
      }
    } catch (e) {
      print('Error updating leaderboard: $e');
    }
  }

  // ADMIN FUNCTIONS

  // Create/Update Achievement
  Future<void> saveAchievement(Achievement achievement) async {
    try {
      if (achievement.id.isEmpty) {
        // Generate new ID for new achievement
        DocumentReference docRef = _firestore.collection('achievements').doc();
        achievement.id = docRef.id;
        await docRef.set(achievement.toFirestore());
      } else {
        // Update existing achievement
        await _firestore
            .collection('achievements')
            .doc(achievement.id)
            .set(achievement.toFirestore());
      }
    } catch (e) {
      print('Error saving achievement: $e');
    }
  }

  // Delete Achievement
  Future<void> deleteAchievement(String achievementId) async {
    try {
      await _firestore.collection('achievements').doc(achievementId).delete();
    } catch (e) {
      print('Error deleting achievement: $e');
    }
  }

  // Create/Update Reward
  Future<void> saveReward(Reward reward) async {
    try {
      if (reward.id.isEmpty) {
        // Generate new ID for new reward
        DocumentReference docRef = _firestore.collection('rewards').doc();
        reward.id = docRef.id;
        await docRef.set(reward.toFirestore());
      } else {
        // Update existing reward
        await _firestore
            .collection('rewards')
            .doc(reward.id)
            .set(reward.toFirestore());
      }
    } catch (e) {
      print('Error saving reward: $e');
    }
  }

  // Delete Reward
  Future<void> deleteReward(String rewardId) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).delete();
    } catch (e) {
      print('Error deleting reward: $e');
    }
  }
}
