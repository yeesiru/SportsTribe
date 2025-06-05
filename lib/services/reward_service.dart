import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all rewards
  Future<List<Reward>> getRewards() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('rewards')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting rewards: $e');
      rethrow;
    }
  }
  
  // Get active rewards only (for user view)
  Future<List<Reward>> getActiveRewards() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .orderBy('pointsCost')
          .get();
      
      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active rewards: $e');
      rethrow;
    }
  }
  
  // Get a single reward by ID
  Future<Reward?> getRewardById(String rewardId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('rewards')
          .doc(rewardId)
          .get();
      
      if (doc.exists) {
        return Reward.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting reward by ID: $e');
      rethrow;
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
      rethrow;
    }
  }
  
  // Delete Reward
  Future<void> deleteReward(String rewardId) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).delete();
    } catch (e) {
      print('Error deleting reward: $e');
      rethrow;
    }
  }
  
  // Update reward redemption count (when user redeems)
  Future<void> incrementRewardRedemptionCount(String rewardId) async {
    try {
      await _firestore.collection('rewards').doc(rewardId).update({
        'redeemedCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error incrementing reward redemption count: $e');
      rethrow;
    }
  }
}