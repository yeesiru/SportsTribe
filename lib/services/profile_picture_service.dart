import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ProfilePictureService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker =
      ImagePicker(); // Show image source selection dialog
  static Future<void> showImageSourceDialog(BuildContext context,
      {VoidCallback? onSuccess}) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Color(0xFFD7F520)),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, context,
                    onSuccess: onSuccess);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFFD7F520)),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, context,
                    onSuccess: onSuccess);
              },
            ),
            // Add a test option for emulator
            ListTile(
              leading: Icon(Icons.portrait, color: Colors.blue),
              title: Text('Use Default Profile'),
              subtitle: Text('For testing purposes'),
              onTap: () {
                Navigator.pop(context);
                _setDefaultProfilePicture(context, onSuccess: onSuccess);
              },
            ),
            if (_auth.currentUser?.photoURL?.isNotEmpty == true ||
                _hasCustomProfilePicture())
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture(context, onSuccess: onSuccess);
                },
              ),
          ],
        ),
      ),
    );
  } // Pick image and upload to Firebase

  static Future<void> _pickAndUploadImage(
      ImageSource source, BuildContext context,
      {VoidCallback? onSuccess}) async {
    try {
      print('Starting image pick from source: $source');

      final XFile? pickedFile = await _picker
          .pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 800,
        maxHeight: 800,
      )
          .timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('Image picker timed out');
          throw Exception('Image selection timed out. Please try again.');
        },
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      print('Image selected: ${pickedFile.path}');

      final File imageFile = File(pickedFile.path);

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Selected image file not found');
      }

      final int fileSize = await imageFile.length();
      print('Image file size: ${fileSize} bytes');

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception(
            'Image file is too large. Please select a smaller image.');
      }

      // Upload to Firebase Storage
      print('Starting upload to Firebase Storage...');
      final String downloadUrl = await _uploadImageToStorage(imageFile);
      print('Upload successful, download URL: $downloadUrl');

      // Update user profile in Firestore
      print('Updating user profile in Firestore...');
      await _updateUserProfilePicture(downloadUrl);
      print('Profile updated successfully');

      // Call success callback
      onSuccess?.call();
    } catch (e) {
      print('Error in _pickAndUploadImage: $e');
      // Note: We don't show snackbar here to avoid context issues
      // The calling widget should handle the UI updates
    }
  }

  // Upload image to Firebase Storage
  static Future<String> _uploadImageToStorage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    print('Starting Firebase Storage upload for user: ${user.uid}');

    final String fileName =
        'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference storageRef = _storage.ref().child(fileName);

    print('Upload path: $fileName');

    final UploadTask uploadTask = storageRef.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    // Monitor upload progress
    uploadTask.snapshotEvents.listen((taskSnapshot) {
      final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
    });

    final TaskSnapshot snapshot = await uploadTask.timeout(
      Duration(seconds: 60),
      onTimeout: () {
        throw Exception(
            'Upload timed out. Please check your internet connection and try again.');
      },
    );

    final String downloadUrl = await snapshot.ref.getDownloadURL();
    print('Download URL obtained: $downloadUrl');

    return downloadUrl;
  }

  // Update user profile picture URL in Firestore
  static Future<void> _updateUserProfilePicture(String downloadUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    print('Updating Firestore document for user: ${user.uid}');

    // Update in Firestore with timeout
    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': downloadUrl,
    }).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Firestore update timed out. Please try again.');
      },
    );

    print('Firestore updated successfully');

    // Also update Firebase Auth profile with timeout
    await user.updatePhotoURL(downloadUrl).timeout(
      Duration(seconds: 30),
      onTimeout: () {
        print(
            'Firebase Auth profile update timed out, but Firestore was updated');
        // Don't throw error here, as Firestore update was successful
      },
    );

    print('Firebase Auth profile updated successfully');
  }

  // Remove profile picture
  static Future<void> _removeProfilePicture(BuildContext context,
      {VoidCallback? onSuccess}) async {
    NavigatorState? navigator = Navigator.of(context);
    ScaffoldMessengerState? scaffoldMessenger;

    // Get scaffold messenger reference before async operations
    try {
      scaffoldMessenger = ScaffoldMessenger.of(context);
    } catch (e) {
      print('Could not get ScaffoldMessenger: $e');
    }

    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7F520)),
              ),
              SizedBox(height: 16),
              Text('Removing profile picture...'),
            ],
          ),
        ),
      );
      dialogShown = true;

      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update in Firestore (set to empty string)
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': '',
      });

      // Update Firebase Auth profile
      await user.updatePhotoURL(null);

      if (dialogShown && navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Text('Profile picture removed'),
          backgroundColor: Colors.orange,
        ),
      );

      // Call success callback
      onSuccess?.call();
    } catch (e) {
      if (dialogShown && navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Text('Failed to remove profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Set default profile picture (useful for testing in emulator)
  static Future<void> _setDefaultProfilePicture(BuildContext context,
      {VoidCallback? onSuccess}) async {
    NavigatorState? navigator = Navigator.of(context);
    ScaffoldMessengerState? scaffoldMessenger;

    // Get scaffold messenger reference before async operations
    try {
      scaffoldMessenger = ScaffoldMessenger.of(context);
    } catch (e) {
      print('Could not get ScaffoldMessenger: $e');
    }

    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7F520)),
              ),
              SizedBox(height: 16),
              Text('Setting default profile picture...'),
            ],
          ),
        ),
      );
      dialogShown = true;

      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Use a default URL or clear the photoUrl to use local asset
      const String defaultPhotoUrl = '';

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': defaultPhotoUrl,
      }); // Update Firebase Auth profile
      await user.updatePhotoURL(null);

      if (dialogShown && navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Text('Default profile picture set'),
          backgroundColor: Colors.green,
        ),
      );

      // Call success callback
      onSuccess?.call();
    } catch (e) {
      if (dialogShown && navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      scaffoldMessenger?.showSnackBar(
        SnackBar(
          content: Text('Failed to set default picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if user has custom profile picture
  static bool _hasCustomProfilePicture() {
    final user = _auth.currentUser;
    return user?.photoURL?.isNotEmpty == true;
  }

  // Get profile picture widget with default fallback
  static Widget getProfilePictureWidget({
    required String? photoUrl,
    required double radius,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CircleAvatar(
                radius: radius - 2,
                backgroundImage: NetworkImage(photoUrl),
                onBackgroundImageError: (exception, stackTrace) {
                  // If network image fails, fall back to default
                  print('Failed to load profile image: $exception');
                },
              )
            : CircleAvatar(
                radius: radius - 2,
                backgroundImage: AssetImage('assets/images/profile.jpg'),
              ),
      ),
    );
  }
}
