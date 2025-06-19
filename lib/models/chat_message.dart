import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String message;
  final DateTime timestamp;
  final String clubId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.message,
    required this.timestamp,
    required this.clubId,
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
    };
  }
}
