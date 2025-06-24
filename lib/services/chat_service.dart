import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/models/chat_message.dart';
import 'package:map_project/models/app_user.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get clubs that the current user has joined
  static Stream<List<Club>> getUserJoinedClubs() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('No current user found');
      return Stream.value([]);
    }

    print('Searching for clubs with user ID: $currentUserId');

    return _firestore
        .collection('club')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} clubs for user');
      final clubs = snapshot.docs.map((doc) {
        print(
            'Club: ${doc.data()['name']} - Members: ${doc.data()['members']}');
        return Club.fromMap(doc.data(), doc.id);
      }).toList(); // Sort clubs: prioritize clubs with messages, then by most recent activity
      clubs.sort((a, b) {
        // Check if clubs have real messages (not empty and not placeholder text)
        final aHasRealMessage = a.lastMessage.isNotEmpty &&
            !a.lastMessage.startsWith('Send your first message');
        final bHasRealMessage = b.lastMessage.isNotEmpty &&
            !b.lastMessage.startsWith('Send your first message');

        // If both clubs have real messages, sort by lastMessageTime
        if (aHasRealMessage && bHasRealMessage) {
          return b.lastMessageTime.compareTo(a.lastMessageTime);
        }
        // If only club 'a' has real messages, it should come first
        else if (aHasRealMessage && !bHasRealMessage) {
          return -1;
        }
        // If only club 'b' has real messages, it should come first
        else if (!aHasRealMessage && bHasRealMessage) {
          return 1;
        }
        // If neither club has real messages, sort by creation time (most recent first)
        else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return clubs;
    });
  }

  // Get messages for a specific club
  static Stream<List<ChatMessage>> getClubMessages(String clubId) {
    return _firestore
        .collection('club')
        .doc(clubId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a message to a club
  static Future<void> sendMessage(String clubId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      print('🔥 Sending message to club: $clubId');
      print('🔥 Message content: $message');
      print('🔥 Current user: ${currentUser.uid}');

      // Get club document to verify it exists
      final clubDoc = await _firestore.collection('club').doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      print('🔥 Club exists, proceeding with message send');

      // Get user data for sender info
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final senderName = userData?['name'] ??
          currentUser.displayName ??
          currentUser.email ??
          'Unknown User';
      final senderPhotoUrl = userData?['photoUrl'] ?? '';

      print('🔥 Sender name: $senderName');

      // Create message document
      final messageRef = await _firestore
          .collection('club')
          .doc(clubId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'message': message,
        'timestamp': Timestamp.now(),
        'clubId': clubId,
      });

      // Update club's last message info
      await _firestore.collection('club').doc(clubId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSender': senderName,
      });

      print('🔥 Message sent successfully with ID: ${messageRef.id}');
    } catch (e) {
      print('🔥 Error sending message: $e');
      rethrow;
    }
  }

  // Get club members as AppUser objects
  static Future<List<AppUser>> getClubMembers(List<String> memberIds) async {
    try {
      if (memberIds.isEmpty) {
        return [];
      }

      print('🔍 Getting members for IDs: $memberIds');

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();
      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? 'Unknown User',
          birthDate: data['birthDate'] ?? '',
          gender: data['gender'] ?? '',
          photoUrl: data['photoUrl'] ?? '',
          sportsList: List<String>.from(data['sportsList'] ?? []),
          communityList: List<String>.from(data['communityList'] ?? []),
          eventList: List<String>.from(data['eventList'] ?? []),
          role: data['role'] ?? '',
        );
      }).toList();

      print('🔍 Found ${members.length} members');
      return members;
    } catch (e) {
      print('❌ Error getting club members: $e');
      return [];
    }
  }

  // Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    // Convert both timestamps to Malaysia time (UTC+8) for proper comparison
    final malaysiaTime = timestamp.toUtc().add(Duration(hours: 8));
    final nowMalaysia = DateTime.now().toUtc().add(Duration(hours: 8));
    final difference = nowMalaysia.difference(malaysiaTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Format message time
  static String formatMessageTime(DateTime timestamp) {
    // Convert to Malaysia time (UTC+8)
    final malaysiaTime = timestamp.toUtc().add(Duration(hours: 8));
    final now = DateTime.now().toUtc().add(Duration(hours: 8));

    // Check if it's today
    if (malaysiaTime.year == now.year &&
        malaysiaTime.month == now.month &&
        malaysiaTime.day == now.day) {
      // Show only time for today's messages
      return '${malaysiaTime.hour.toString().padLeft(2, '0')}:${malaysiaTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Show date and time for older messages
      final day = malaysiaTime.day.toString().padLeft(2, '0');
      final month = malaysiaTime.month.toString().padLeft(2, '0');
      final time =
          '${malaysiaTime.hour.toString().padLeft(2, '0')}:${malaysiaTime.minute.toString().padLeft(2, '0')}';
      return '$day/$month $time';
    }
  }

  // Debug method to check club membership
  static Future<void> debugClubMembership() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('❌ No current user');
      return;
    }

    print('🔍 Checking clubs for user: $currentUserId');
    print('Current user email: ${_auth.currentUser?.email}');

    // Get all clubs
    final allClubs = await _firestore.collection('club').get();

    print('📊 Found ${allClubs.docs.length} clubs');

    for (final doc in allClubs.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      final isUserInClub = members.contains(currentUserId);
      print(
          '  📁 ${data['name']} - Members: $members - User in club: $isUserInClub');
    }

    // Get user's clubs using the same query as getUserJoinedClubs
    final userClubs = await _firestore
        .collection('club')
        .where('members', arrayContains: currentUserId)
        .get();

    print('User joined clubs: ${userClubs.docs.length}');
    print('=== DEBUG TEST COMPLETE ===');
  }

  // Pin a message
  static Future<void> pinMessage(String clubId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('club')
          .doc(clubId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isPinned': true,
        'pinnedAt': FieldValue.serverTimestamp(),
        'pinnedBy': currentUser.uid,
      });

      print('Message pinned successfully');
    } catch (e) {
      print('Error pinning message: $e');
      throw e;
    }
  }

  // Unpin a message
  static Future<void> unpinMessage(String clubId, String messageId) async {
    try {
      await _firestore
          .collection('club')
          .doc(clubId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isPinned': false,
        'pinnedAt': null,
        'pinnedBy': null,
      });

      print('Message unpinned successfully');
    } catch (e) {
      print('Error unpinning message: $e');
      throw e;
    }
  }

  // Get pinned messages for a club
  static Stream<List<ChatMessage>> getPinnedMessages(String clubId) {
    print('🔍 Getting pinned messages for club: $clubId');
    return _firestore
        .collection('club')
        .doc(clubId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .orderBy('pinnedAt', descending: false) // Oldest pinned first
        .snapshots()
        .map((snapshot) {
      print('📌 Found ${snapshot.docs.length} pinned messages');
      for (var doc in snapshot.docs) {
        print('📌 Pinned message: ${doc.data()}');
      }
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
