import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreService {
  static Future<void> addUserToFirestore(User user, {String role = 'member'}) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      await userDoc.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': role});
  }
}
