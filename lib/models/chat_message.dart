import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String message;
  final DateTime timestamp;
  final String clubId;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.message,
    required this.timestamp,
    required this.clubId,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
  });
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null && map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      clubId: map['clubId'] ?? '',
      isPinned: map['isPinned'] ?? false,
      pinnedAt: map['pinnedAt'] != null && map['pinnedAt'] is Timestamp
          ? (map['pinnedAt'] as Timestamp).toDate()
          : null,
      pinnedBy: map['pinnedBy'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'clubId': clubId,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
      'pinnedBy': pinnedBy,
    };
  }
}
