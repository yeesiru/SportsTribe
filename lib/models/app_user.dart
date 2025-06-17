import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String birthDate;
  final String gender;
  final String photoUrl;
  final List<String> sportsList;
  final List<String> communityList;
  final List<String> eventList;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.photoUrl,
    required this.sportsList,
    required this.communityList,
    required this.eventList,
    required this.role,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      birthDate: map['birthDate'] ?? '',
      gender: map['gender'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      sportsList:
          (map['sportsList'] as List?)?.map((e) => e.toString()).toList() ?? [],
      communityList:
          (map['communityList'] as List?)?.map((e) => e.toString()).toList() ?? [],
      eventList:
          (map['eventList'] as List?)?.map((e) => e.toString()).toList() ?? [],
      role: map['role'] ?? 'member',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'birthDate': birthDate,
      'gender': gender,
      'photoUrl': photoUrl,
      'sportsList': List<String>.from(sportsList),
      'communityList': List<String>.from(communityList),
      'eventList': List<String>.from(eventList),
      'role': role,
      'createdAt': createdAt,
    };
  }
}
