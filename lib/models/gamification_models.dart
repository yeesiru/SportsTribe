// Flutter Data Models for Gamification & Rewards Module
import 'package:cloud_firestore/cloud_firestore.dart';

// Achievement Model
class Achievement {
  String id;
  String title;
  String description;
  int pointsReward;
  String iconAsset;
  String requirement;
  String progressTrackingType; // 'count', 'boolean', etc.
  String category;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.iconAsset,
    required this.requirement,
    required this.progressTrackingType,
    required this.category,
  });
  
  // Convert from Firestore document
  factory Achievement.fromFirestore(Map<String, dynamic> data) {
    return Achievement(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      pointsReward: data['pointsReward'],
      iconAsset: data['iconAsset'],
      requirement: data['requirement'],
      progressTrackingType: data['progressTrackingType'],
      category: data['category'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsReward': pointsReward,
      'iconAsset': iconAsset,
      'requirement': requirement,
      'progressTrackingType': progressTrackingType,
      'category': category,
    };
  }
}

// User Achievement Model
class UserAchievement {
  String userId;
  String achievementId;
  DateTime? dateEarned;
  int progress;
  int maxProgress;
  
  UserAchievement({
    required this.userId,
    required this.achievementId,
    this.dateEarned,
    required this.progress,
    required this.maxProgress,
  });
  
  // Convert from Firestore document
  factory UserAchievement.fromFirestore(Map<String, dynamic> data) {
    return UserAchievement(
      userId: data['userId'],
      achievementId: data['achievementId'],
      dateEarned: data['dateEarned'] != null ? (data['dateEarned'] as Timestamp).toDate() : null,
      progress: data['progress'],
      maxProgress: data['maxProgress'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'dateEarned': dateEarned,
      'progress': progress,
      'maxProgress': maxProgress,
    };
  }
}

// Reward Model
class Reward {
  String id;
  String title;
  String description;
  int pointsCost;
  String imageAsset;
  DateTime? startDate;
  DateTime? endDate;
  int quantityAvailable;
  String category;
  
  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.imageAsset,
    this.startDate,
    this.endDate,
    required this.quantityAvailable,
    required this.category,
  });
  
  // Convert from Firestore document
  factory Reward.fromFirestore(Map<String, dynamic> data) {
    return Reward(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      pointsCost: data['pointsCost'],
      imageAsset: data['imageAsset'],
      startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      quantityAvailable: data['quantityAvailable'],
      category: data['category'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'imageAsset': imageAsset,
      'startDate': startDate,
      'endDate': endDate,
      'quantityAvailable': quantityAvailable,
      'category': category,
    };
  }
}

// User Reward Model
class UserReward {
  String userId;
  String rewardId;
  DateTime dateRedeemed;
  String status; // 'claimed', 'used', 'expired'
  String? code;
  
  UserReward({
    required this.userId,
    required this.rewardId,
    required this.dateRedeemed,
    required this.status,
    this.code,
  });
  
  // Convert from Firestore document
  factory UserReward.fromFirestore(Map<String, dynamic> data) {
    return UserReward(
      userId: data['userId'],
      rewardId: data['rewardId'],
      dateRedeemed: (data['dateRedeemed'] as Timestamp).toDate(),
      status: data['status'],
      code: data['code'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'dateRedeemed': dateRedeemed,
      'status': status,
      'code': code,
    };
  }
}

// User Points Model
class UserPoints {
  String userId;
  int totalPoints;
  int currentPoints;
  List<PointsHistory> history;
  
  UserPoints({
    required this.userId,
    required this.totalPoints,
    required this.currentPoints,
    required this.history,
  });
  
  // Convert from Firestore document
  factory UserPoints.fromFirestore(Map<String, dynamic> data) {
    List<PointsHistory> history = [];
    if (data['history'] != null) {
      history = (data['history'] as List).map((item) => PointsHistory.fromFirestore(item)).toList();
    }
    
    return UserPoints(
      userId: data['userId'],
      totalPoints: data['totalPoints'],
      currentPoints: data['currentPoints'],
      history: history,
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentPoints': currentPoints,
      'history': history.map((item) => item.toFirestore()).toList(),
    };
  }
}

// Points History Model
class PointsHistory {
  DateTime date;
  int points;
  String source; // e.g., 'achievement', 'reward_redemption', 'admin_gift'
  String description;
  String? referenceId; // ID of related achievement or reward
  
  PointsHistory({
    required this.date,
    required this.points,
    required this.source,
    required this.description,
    this.referenceId,
  });
  
  // Convert from Firestore document
  factory PointsHistory.fromFirestore(Map<String, dynamic> data) {
    return PointsHistory(
      date: (data['date'] as Timestamp).toDate(),
      points: data['points'],
      source: data['source'],
      description: data['description'],
      referenceId: data['referenceId'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'points': points,
      'source': source,
      'description': description,
      'referenceId': referenceId,
    };
  }
}

// User Ranking Model (for Leaderboard)
class UserRanking {
  String userId;
  String username;
  String profileImage;
  int points;
  int rank;
  
  UserRanking({
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.points,
    required this.rank,
  });
  
  // Convert from Firestore document
  factory UserRanking.fromFirestore(Map<String, dynamic> data) {
    return UserRanking(
      userId: data['userId'],
      username: data['username'],
      profileImage: data['profileImage'],
      points: data['points'],
      rank: data['rank'],
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'points': points,
      'rank': rank,
    };
  }
}