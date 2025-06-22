import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Future<void> seedInitialData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No user logged in');
      return;
    }

    print(
        'Seeding data for user: ${currentUser.uid} (${currentUser.email})'); // Check if user is already in any clubs
    final existingUserClubs = await _firestore
        .collection('club') // Changed from 'clubs' to 'club'
        .where('members',
            arrayContains:
                currentUser.uid) // Changed from 'memberIds' to 'members'
        .limit(1)
        .get();

    if (existingUserClubs.docs.isNotEmpty) {
      print('User already has clubs, skipping seed');
      return;
    }

    // Create sample clubs
    final clubsData = [
      {
        'name': 'Badminton Squad',
        'description':
            'Join our badminton community for weekly games and tournaments!',
        'sport': 'Badminton',
        'imageUrl': '',
        'members': [currentUser.uid], // Changed from 'memberIds' to 'members'
        'createdBy': currentUser.uid,
        'createdAt': Timestamp.now(),
        'lastMessage': 'Welcome to Badminton Squad!',
        'lastMessageTime': Timestamp.now(),
      },
      {
        'name': 'Basketball Warriors',
        'description': 'Weekly basketball games every Saturday morning',
        'sport': 'Basketball',
        'imageUrl': '',
        'members': [currentUser.uid], // Changed from 'memberIds' to 'members'
        'createdBy': currentUser.uid,
        'createdAt':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
        'lastMessage': 'See you all this Saturday!',
        'lastMessageTime':
            Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
      },
      {
        'name': 'Tennis Club',
        'description': 'For all tennis enthusiasts of all skill levels',
        'sport': 'Tennis',
        'imageUrl': '',
        'members': [currentUser.uid], // Changed from 'memberIds' to 'members'
        'createdBy': currentUser.uid,
        'createdAt':
            Timestamp.fromDate(DateTime.now().subtract(Duration(days: 3))),
        'lastMessage': 'Anyone up for doubles tomorrow?',
        'lastMessageTime':
            Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))),
      },
    ];

    print('Creating ${clubsData.length} clubs...');

    // Create clubs
    for (int i = 0; i < clubsData.length; i++) {
      final clubData = clubsData[i];
      print('Creating club: ${clubData['name']}');

      final docRef = await _firestore
          .collection('club')
          .add(clubData); // Changed from 'clubs' to 'club'
      print('Created club with ID: ${docRef.id}');

      // Add some sample messages
      final messages = [
        {
          'senderId': currentUser.uid,
          'senderName': currentUser.displayName ?? 'You',
          'senderPhotoUrl': currentUser.photoURL ?? '',
          'message': 'Hello everyone! 👋',
          'timestamp': Timestamp.now(),
          'clubId': docRef.id,
        },
        {
          'senderId': 'sample_user_${i + 1}',
          'senderName': ['John', 'Sarah', 'Mike'][i],
          'senderPhotoUrl': '',
          'message': [
            'Hey there! Looking forward to our next game!',
            'Count me in for this weekend!',
            'Great to have everyone here!'
          ][i],
          'timestamp': Timestamp.fromDate(
              DateTime.now().subtract(Duration(minutes: 10))),
          'clubId': docRef.id,
        },
      ];

      for (final messageData in messages) {
        await docRef.collection('messages').add(messageData);
        print('Added message to club ${docRef.id}');
      }
    }
    print('Sample data seeded successfully!');
  }

  // Force reset and recreate sample data
  static Future<void> resetAndSeedData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No user logged in');
      return;
    }

    print(
        'Resetting and seeding data for user: ${currentUser.uid}'); // Delete existing clubs where user is a member
    final existingClubs = await _firestore
        .collection('club') // Changed from 'clubs' to 'club'
        .where('members',
            arrayContains:
                currentUser.uid) // Changed from 'memberIds' to 'members'
        .get();

    for (final doc in existingClubs.docs) {
      print('Deleting club: ${doc.data()['name']}');
      await doc.reference.delete();
    }

    // Now seed fresh data
    await seedInitialData();
  }
}
