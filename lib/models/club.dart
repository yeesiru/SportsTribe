import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String sport;
  final String imageUrl;
  final List<String> members; // Changed from 'memberIds' to 'members'
  final String createdBy;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageTime;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.sport,
    required this.imageUrl,
    required this.members, // Changed from 'memberIds' to 'members'
    required this.createdBy,
    required this.createdAt,
    this.lastMessage = '',
    DateTime? lastMessageTime,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  factory Club.fromMap(Map<String, dynamic> map, String id) {
    return Club(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sport: map['sport'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      members: (map['members'] as List?)?.map((e) => e.toString()).toList() ??
          [], // Changed from 'memberIds' to 'members'
      createdBy: map['createdBy'] ??
          map['creatorId'] ??
          '', // Support both field names
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          map['lastMessageTime'] != null && map['lastMessageTime'] is Timestamp
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sport': sport,
      'imageUrl': imageUrl,
      'members': members, // Changed from 'memberIds' to 'members'
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }
}
