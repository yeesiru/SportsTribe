import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // Test Firebase connection
  static Future<bool> testFirebaseConnection() async {
    try {
      print('🔍 Testing Firebase connection...');

      // Test basic Firestore write with simple document
      await _firestore.collection('connectionTest').doc('test').set({
        'timestamp': Timestamp.now(),
        'status': 'connected',
        'userId': _auth.currentUser?.uid ?? 'unknown'
      });

      print('✅ Basic Firestore write successful');

      // Test reading it back
      final doc =
          await _firestore.collection('connectionTest').doc('test').get();
      if (doc.exists) {
        print('✅ Basic Firestore read successful');
      }

      // Test Auth
      final user = _auth.currentUser;
      if (user != null) {
        print('✅ User authenticated: ${user.uid} (${user.email})');
      } else {
        print('❌ No user authenticated');
        return false;
      }

      // Test club access
      print('🔍 Testing club collection access...');
      final clubTest = await _firestore.collection('club').limit(1).get();
      print(
          '✅ Club collection accessible, found ${clubTest.docs.length} documents');

      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }

  // Test creating a simple club
  static Future<void> testCreateClub() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }
      final testClub = {
        'name': 'Test Club ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'This is a test club',
        'sport': 'Testing',
        'imageUrl': '',
        'members': [user.uid], // Changed from 'memberIds' to 'members'
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'lastMessage': 'Test message',
        'lastMessageTime': Timestamp.now(),
      };

      final docRef = await _firestore
          .collection('club')
          .add(testClub); // Changed from 'clubs' to 'club'
      print('✅ Test club created with ID: ${docRef.id}');

      // Verify we can read it back
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Test club verified: ${doc.data()!['name']}');
      }

      // Clean up
      await docRef.delete();
      print('✅ Test club cleaned up');
    } catch (e) {
      print('❌ Test club creation failed: $e');
    }
  }

  // Check current user's clubs
  static Future<void> checkUserClubs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔍 Checking clubs for user: ${user.uid}');
      final snapshot = await _firestore
          .collection('club') // Changed from 'clubs' to 'club'
          .where('members',
              arrayContains: user.uid) // Changed from 'memberIds' to 'members'
          .get();

      print('📊 Found ${snapshot.docs.length} clubs');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
            '  📁 ${data['name']} - Members: ${data['members']}'); // Changed from 'memberIds' to 'members'
      }
    } catch (e) {
      print('❌ Error checking user clubs: $e');
    }
  }

  // Test sending a message to a club
  static Future<void> testSendMessage(String clubId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🧪 Testing message send to club: $clubId');

      // Create a test message
      final testMessage = {
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Test User',
        'senderPhotoUrl': user.photoURL ?? '',
        'message': 'Test message ${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': Timestamp.now(),
        'clubId': clubId,
      };

      // Try to add the message directly
      final messageRef = await _firestore
          .collection('club')
          .doc(clubId)
          .collection('messages')
          .add(testMessage);

      print('✅ Test message sent with ID: ${messageRef.id}');

      // Test updating club last message
      await _firestore.collection('club').doc(clubId).update({
        'lastMessage': testMessage['message'],
        'lastMessageTime': testMessage['timestamp'],
      });

      print('✅ Club last message updated');
    } catch (e) {
      print('❌ Test message send failed: $e');
    }
  }

  // Test Firebase rules specifically
  static Future<void> testFirebaseRules() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔍 Testing Firebase Rules...');
      print('User: ${user.uid}');

      // Test 1: Can we write to a simple collection?
      print('Test 1: Writing to simple collection...');
      await _firestore.collection('ruleTest').doc('test').set({
        'userId': user.uid,
        'timestamp': Timestamp.now(),
        'test': 'simple write'
      });
      print('✅ Simple write successful');

      // Test 2: Can we write to club collection?
      print('Test 2: Writing to club collection...');
      await _firestore.collection('club').doc('testClub').set({
        'name': 'Test Club',
        'members': [user.uid],
        'createdBy': user.uid,
        'createdAt': Timestamp.now()
      });
      print('✅ Club write successful');

      // Test 3: Can we write to messages subcollection?
      print('Test 3: Writing to messages subcollection...');
      await _firestore
          .collection('club')
          .doc('testClub')
          .collection('messages')
          .doc('testMessage')
          .set({
        'senderId': user.uid,
        'senderName': 'Test User',
        'message': 'Test message',
        'timestamp': Timestamp.now()
      });
      print('✅ Messages subcollection write successful');

      // Clean up
      await _firestore.collection('club').doc('testClub').delete();
      await _firestore.collection('ruleTest').doc('test').delete();
      print('✅ Cleanup complete');
    } catch (e) {
      print('❌ Firebase rules test failed: $e');
      print('❌ This indicates your Firebase rules are not properly set');
    }
  }
}
