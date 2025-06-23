import 'package:cloud_firestore/cloud_firestore.dart';

class EventAttendance {
  final String id;
  final String eventId;
  final String userId;
  final bool isPresent;
  final DateTime markedAt;
  final String markedBy;
  final int pointsEarned;
  final List<String> badgesEarned;

  EventAttendance({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.isPresent,
    required this.markedAt,
    required this.markedBy,
    this.pointsEarned = 0,
    this.badgesEarned = const [],
  });

  factory EventAttendance.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return EventAttendance(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      isPresent: data['isPresent'] ?? false,
      markedAt: (data['markedAt'] as Timestamp).toDate(),
      markedBy: data['markedBy'] ?? '',
      pointsEarned: data['pointsEarned'] ?? 0,
      badgesEarned:
          (data['badgesEarned'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'isPresent': isPresent,
      'markedAt': Timestamp.fromDate(markedAt),
      'markedBy': markedBy,
      'pointsEarned': pointsEarned,
      'badgesEarned': badgesEarned,
    };
  }
}

class AttendanceSession {
  final String eventId;
  final String eventTitle;
  final List<String> participants;
  final Map<String, bool> attendance;
  final bool isCompleted;
  final DateTime createdAt;
  final String createdBy;

  AttendanceSession({
    required this.eventId,
    required this.eventTitle,
    required this.participants,
    required this.attendance,
    this.isCompleted = false,
    required this.createdAt,
    required this.createdBy,
  });

  factory AttendanceSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AttendanceSession(
      eventId: doc.id,
      eventTitle: data['eventTitle'] ?? '',
      participants:
          (data['participants'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      attendance: Map<String, bool>.from(data['attendance'] ?? {}),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventTitle': eventTitle,
      'participants': participants,
      'attendance': attendance,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
