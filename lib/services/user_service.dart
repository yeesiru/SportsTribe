import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user data from Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting current user data: $e');
    }
    return null;
  }

  /// Get user data by uid from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting user data for uid $uid: $e');
    }
    return null;
  }

  /// Stream of current user data
  static Stream<Map<String, dynamic>?> getCurrentUserDataStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Stream of user data by uid
  static Stream<Map<String, dynamic>?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}
