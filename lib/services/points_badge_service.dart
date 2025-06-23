import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge.dart';
import '../models/attendance.dart';

class PointsBadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points configuration
  static const int ATTENDANCE_POINTS = 20;
  static const int ORGANIZER_BONUS_POINTS = 10;
  static const int COMPLETION_BONUS_POINTS = 5;

  // Award points and badges for event attendance
  static Future<Map<String, dynamic>> awardAttendanceRewards(
    String userId,
    String eventId,
    bool isOrganizer,
  ) async {
    try {
      int pointsEarned = ATTENDANCE_POINTS;
      List<String> badgesEarned = [];
      
      // Bonus points for organizers
      if (isOrganizer) {
        pointsEarned += ORGANIZER_BONUS_POINTS;
      }

      // Get user's current data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      int currentPoints = userData['points'] ?? 0;
      List<String> currentBadges = List<String>.from(userData['badges'] ?? []);
      List<String> attendedEvents = List<String>.from(userData['attendedEvents'] ?? []);
      Map<String, dynamic> statistics = Map<String, dynamic>.from(userData['statistics'] ?? {});

      // Update attended events
      if (!attendedEvents.contains(eventId)) {
        attendedEvents.add(eventId);
      }

      // Update statistics
      statistics['totalEventsAttended'] = attendedEvents.length;
      statistics['totalPointsEarned'] = currentPoints + pointsEarned;

      // Check for new badges
      List<Badge> availableBadges = Badge.getDefaultBadges();
      
      for (Badge badge in availableBadges) {
        if (!currentBadges.contains(badge.id)) {
          bool earned = false;
          
          switch (badge.category) {
            case 'participation':
              earned = attendedEvents.length >= badge.requiredEvents;
              break;
            case 'organizing':
              if (isOrganizer && badge.id == 'organizer') {
                earned = true;
              }
              break;
          }
          
          if (earned) {
            badgesEarned.add(badge.id);
            currentBadges.add(badge.id);
            pointsEarned += badge.points;
          }
        }
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'points': currentPoints + pointsEarned,
        'badges': currentBadges,
        'attendedEvents': attendedEvents,
        'statistics': statistics,
      });

      return {
        'pointsEarned': pointsEarned,
        'badgesEarned': badgesEarned,
        'totalPoints': currentPoints + pointsEarned,
        'totalBadges': currentBadges.length,
      };
    } catch (e) {
      print('Error awarding attendance rewards: $e');
      return {
        'pointsEarned': 0,
        'badgesEarned': [],
        'totalPoints': 0,
        'totalBadges': 0,
      };
    }
  }

  // Mark attendance for an event
  static Future<bool> markAttendance(
    String eventId,
    String eventTitle,
    Map<String, bool> attendance,
    String? clubId,
  ) async {
    try {
      String markerId = _auth.currentUser!.uid;
      DateTime now = DateTime.now();

      // Create attendance session
      AttendanceSession session = AttendanceSession(
        eventId: eventId,
        eventTitle: eventTitle,
        participants: attendance.keys.toList(),
        attendance: attendance,
        isCompleted: true,
        createdAt: now,
        createdBy: markerId,
      );

      // Save attendance session
      await _firestore.collection('attendance_sessions').doc(eventId).set(session.toFirestore());

      // Process each participant
      for (String userId in attendance.keys) {
        bool isPresent = attendance[userId] ?? false;
        
        if (isPresent) {
          // Create individual attendance record
          EventAttendance attendanceRecord = EventAttendance(
            id: '${eventId}_$userId',
            eventId: eventId,
            userId: userId,
            isPresent: true,
            markedAt: now,
            markedBy: markerId,
          );

          await _firestore.collection('event_attendance').doc(attendanceRecord.id).set(attendanceRecord.toFirestore());

          // Award rewards
          bool isOrganizer = false;
          
          // Check if user is organizer
          DocumentReference eventRef;
          if (clubId != null) {
            eventRef = _firestore.collection('club').doc(clubId).collection('events').doc(eventId);
          } else {
            eventRef = _firestore.collection('events').doc(eventId);
          }
          
          DocumentSnapshot eventDoc = await eventRef.get();
          if (eventDoc.exists) {
            Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
            isOrganizer = eventData['createdBy'] == userId;
          }

          await awardAttendanceRewards(userId, eventId, isOrganizer);
        }
      }

      // Mark event as completed
      DocumentReference eventRef;
      if (clubId != null) {
        eventRef = _firestore.collection('club').doc(clubId).collection('events').doc(eventId);
      } else {
        eventRef = _firestore.collection('events').doc(eventId);
      }
      
      await eventRef.update({
        'isCompleted': true,
        'attendanceMarked': true,
        'completedAt': Timestamp.fromDate(now),
      });

      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  // Get user's leaderboard ranking
  static Future<Map<String, dynamic>> getUserRanking(String userId) async {
    try {
      // Get all users sorted by points
      QuerySnapshot usersQuery = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .get();

      List<DocumentSnapshot> users = usersQuery.docs;
      
      for (int i = 0; i < users.length; i++) {
        if (users[i].id == userId) {
          Map<String, dynamic> userData = users[i].data() as Map<String, dynamic>;
          return {
            'rank': i + 1,
            'points': userData['points'] ?? 0,
            'badges': userData['badges'] ?? [],
            'totalUsers': users.length,
          };
        }
      }

      return {
        'rank': users.length,
        'points': 0,
        'badges': [],
        'totalUsers': users.length,
      };
    } catch (e) {
      print('Error getting user ranking: $e');
      return {
        'rank': 0,
        'points': 0,
        'badges': [],
        'totalUsers': 0,
      };
    }
  }

  // Get leaderboard data
  static Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      QuerySnapshot usersQuery = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> leaderboard = [];
      
      for (int i = 0; i < usersQuery.docs.length; i++) {
        DocumentSnapshot doc = usersQuery.docs[i];
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        leaderboard.add({
          'rank': i + 1,
          'userId': doc.id,
          'name': userData['name'] ?? 'Unknown',
          'photoUrl': userData['photoUrl'] ?? '',
          'points': userData['points'] ?? 0,
          'badges': userData['badges'] ?? [],
          'attendedEvents': (userData['attendedEvents'] as List?)?.length ?? 0,
        });
      }

      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Redeem reward
  static Future<bool> redeemReward(String rewardId, int pointsCost) async {
    try {
      String userId = _auth.currentUser!.uid;
      
      // Check user's points
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      int currentPoints = userData['points'] ?? 0;

      if (currentPoints < pointsCost) {
        return false; // Insufficient points
      }

      // Deduct points
      await _firestore.collection('users').doc(userId).update({
        'points': currentPoints - pointsCost,
      });

      // Record redemption
      await _firestore.collection('reward_redemptions').add({
        'userId': userId,
        'rewardId': rewardId,
        'pointsCost': pointsCost,
        'redeemedAt': Timestamp.now(),
        'status': 'pending',
      });

      // Update reward redeemed count
      DocumentReference rewardRef = _firestore.collection('rewards').doc(rewardId);
      await rewardRef.update({
        'redeemedCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error redeeming reward: $e');
      return false;
    }
  }

  // Get badge details
  static Badge? getBadgeById(String badgeId) {
    List<Badge> badges = Badge.getDefaultBadges();
    try {
      return badges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  // Get user's badge progress
  static Future<Map<String, dynamic>> getBadgeProgress(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      List<String> userBadges = List<String>.from(userData['badges'] ?? []);
      List<String> attendedEvents = List<String>.from(userData['attendedEvents'] ?? []);
      int eventsAttended = attendedEvents.length;

      List<Badge> allBadges = Badge.getDefaultBadges();
      List<Map<String, dynamic>> progress = [];

      for (Badge badge in allBadges) {
        bool earned = userBadges.contains(badge.id);
        double progressPercent = 0.0;
        
        if (badge.category == 'participation') {
          progressPercent = badge.requiredEvents > 0 
              ? (eventsAttended / badge.requiredEvents).clamp(0.0, 1.0)
              : (earned ? 1.0 : 0.0);
        } else if (badge.category == 'organizing') {
          progressPercent = earned ? 1.0 : 0.0;
        }

        progress.add({
          'badge': badge,
          'earned': earned,
          'progress': progressPercent,
          'currentCount': eventsAttended,
          'requiredCount': badge.requiredEvents,
        });
      }

      return {
        'totalBadges': allBadges.length,
        'earnedBadges': userBadges.length,
        'progress': progress,
      };
    } catch (e) {
      print('Error getting badge progress: $e');
      return {
        'totalBadges': 0,
        'earnedBadges': 0,
        'progress': [],
      };
    }
  }
}
