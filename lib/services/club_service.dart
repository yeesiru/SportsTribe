import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/models/club.dart';

class ClubService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create sample clubs for testing
  static Future<void> createSampleClubs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final clubs = [
      Club(
        id: '',
        name: 'Badminton Squad',
        description:
            'Join our badminton community for weekly games and tournaments!',
        sport: 'Badminton',
        imageUrl: '',
        members: [currentUser.uid], // Add current user to the club
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        lastMessage: 'Send your first message!',
        lastMessageTime: DateTime.now(),
      ),
      Club(
        id: '',
        name: 'Basketball Warriors',
        description: 'Weekly basketball games every Saturday morning',
        sport: 'Basketball',
        imageUrl: '',
        members: [currentUser.uid],
        createdBy: currentUser.uid,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        lastMessage: 'See you all this Saturday!',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Club(
        id: '',
        name: 'Tennis Club',
        description: 'For all tennis enthusiasts of all skill levels',
        sport: 'Tennis',
        imageUrl: '',
        members: [currentUser.uid],
        createdBy: currentUser.uid,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        lastMessage: 'Anyone up for doubles tomorrow?',
        lastMessageTime: DateTime.now().subtract(Duration(minutes: 30)),
      ),
    ];

    for (final club in clubs) {
      await _firestore.collection('clubs').add(club.toMap());
    }
  }

  // Join a club
  static Future<void> joinClub(String clubId, String userId) async {
    await _firestore.collection('clubs').doc(clubId).update({
      'memberIds': FieldValue.arrayUnion([userId])
    });
  }

  // Leave a club
  static Future<void> leaveClub(String clubId, String userId) async {
    await _firestore.collection('clubs').doc(clubId).update({
      'memberIds': FieldValue.arrayRemove([userId])
    });
  }

  // Get all clubs
  static Stream<List<Club>> getAllClubs() {
    return _firestore
        .collection('clubs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Club.fromMap(doc.data(), doc.id))
            .toList());
  }
}
