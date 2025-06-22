import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> editProfile(String uid, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('users').doc(uid).update(updatedData);
      print('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('Account deleted successfully');
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  Future<void> addUser(String uid, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': '', // Default empty name
        'birthDate': '', // Default empty birth date
        'gender': '', // Default empty gender
        'photoUrl': '', // Default empty photo URL
        'sportsList': [], // Default empty sports list
        'communityList': [], // Default empty community list
        'eventList': [], // Default empty event list
        'role': 'member', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User added successfully with email');
    } catch (e) {
      print('Error adding user with email: $e');
      rethrow;
    }
  }

  Future<void> addUserWithProfile(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      print('User profile added successfully');
    } catch (e) {
      print('Error adding user profile: $e');
      rethrow;
    }
  }

  // Admin-specific methods
  Future<List<AppUser>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      rethrow;
    }
  }

  Future<int> getUserCount() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting user count: $e');
      rethrow;
    }
  }

  Future<int> getAdminCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting admin count: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
      print('User role updated successfully');
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final allUsers = querySnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
      
      if (query.isEmpty) return allUsers;
      
      final searchQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.name.toLowerCase().contains(searchQuery) ||
               user.email.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  Stream<List<AppUser>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    });
  }

  Future<bool> userExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      rethrow;
    }
  }
}
