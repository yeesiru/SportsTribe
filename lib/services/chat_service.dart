import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/models/chat_message.dart';
import 'package:map_project/models/app_user.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth =
      FirebaseAuth.instance; // Get clubs that the current user has joined
  static Stream<List<Club>> getUserJoinedClubs() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user found');
      return Stream.value([]);
    }

    print('Searching for clubs with user ID: $currentUserId');

    return _firestore
        .collection('club') // Changed from 'clubs' to 'club'
        .where('members',
            arrayContains:
                currentUserId) // Changed from 'memberIds' to 'members'
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} clubs for user');
      return snapshot.docs.map((doc) {
        print(
            'Club: ${doc.data()['name']} - Members: ${doc.data()['members']}');
        return Club.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get messages for a specific club
  static Stream<List<ChatMessage>> getClubMessages(String clubId) {
    return _firestore
        .collection('club') // Changed from 'clubs' to 'club'
        .doc(clubId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  } // Send a message to a club

  static Future<void> sendMessage(String clubId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in');
      return;
    }

    print('📤 Sending message to club: $clubId');
    print('👤 Current user: ${currentUser.uid}');
    print('💬 Message: $message');

    try {
      // First, verify the club exists and user is a member
      final clubDoc = await _firestore.collection('club').doc(clubId).get();
      if (!clubDoc.exists) {
        print('❌ Club does not exist');
        return;
      }

      final clubData = clubDoc.data()!;
      final members = List<String>.from(clubData['members'] ?? []);

      if (!members.contains(currentUser.uid)) {
        print('❌ User is not a member of this club');
        print('Club members: $members');
        return;
      }

      print('✅ User is verified as club member');

      // Get current user data
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.exists ? userDoc.data() : null;

      final chatMessage = ChatMessage(
        id: '',
        senderId: currentUser.uid,
        senderName:
            userData?['name'] ?? currentUser.displayName ?? 'Unknown User',
        senderPhotoUrl: userData?['photoUrl'] ?? currentUser.photoURL ?? '',
        message: message,
        timestamp: DateTime.now(),
        clubId: clubId,
      );

      print('📝 Creating message document...');

      // Add message to club's messages subcollection
      final messageRef = await _firestore
          .collection('club')
          .doc(clubId)
          .collection('messages')
          .add(chatMessage.toMap());

      print('✅ Message created with ID: ${messageRef.id}');

      // Update club's last message
      await _firestore.collection('club').doc(clubId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Club last message updated');
      print('🎉 Message sent successfully!');
    } catch (e) {
      print('❌ Error sending message: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Get club members
  static Future<List<AppUser>> getClubMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    final List<AppUser> members = [];

    // Firebase 'in' query has a limit of 10, so we need to batch the queries
    for (int i = 0; i < memberIds.length; i += 10) {
      final batch = memberIds.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection('users')
          .where('uid', whereIn: batch)
          .get();

      members.addAll(
          snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
    }

    return members;
  }

  // Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Format time for chat messages
  static String formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Debug function to check club membership
  static Future<void> debugClubMembership() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user logged in');
      return;
    }

    print('Current user ID: $currentUserId');
    print('Current user email: ${_auth.currentUser?.email}'); // Get all clubs
    final allClubs = await _firestore
        .collection('club')
        .get(); // Changed from 'clubs' to 'club'
    print('Total clubs in database: ${allClubs.docs.length}');

    for (final doc in allClubs.docs) {
      final data = doc.data();
      final memberIds = List<String>.from(
          data['members'] ?? []); // Changed from 'memberIds' to 'members'
      print(
          'Club: ${data['name']} - Members: $memberIds - User in club: ${memberIds.contains(currentUserId)}');
    }

    // Try to get user's clubs
    final userClubs = await _firestore
        .collection('club') // Changed from 'clubs' to 'club'
        .where('members',
            arrayContains:
                currentUserId) // Changed from 'memberIds' to 'members'
        .get();
    print('User joined clubs: ${userClubs.docs.length}');
  }
}
