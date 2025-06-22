import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final double radius;
  final String? fallbackImagePath;
  final IconData? fallbackIcon;

  const UserAvatar({
    Key? key,
    required this.userData,
    this.radius = 20,
    this.fallbackImagePath = 'assets/images/profile.jpg',
    this.fallbackIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: _getBackgroundImage(),
      child: _getBackgroundImage() == null ? _getFallbackChild() : null,
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (userData == null) return null;

    // Check for base64 image first (priority)
    final photoBase64 = userData!['photoBase64'] as String?;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(photoBase64);
        return MemoryImage(imageBytes);
      } catch (e) {
        print('Error decoding base64 image: $e');
        // Continue to check other image sources
      }
    }

    // Check for photoUrl (fallback)
    final photoUrl = userData!['photoUrl'] as String?;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }

    // Check for fallback asset image
    if (fallbackImagePath != null) {
      return AssetImage(fallbackImagePath!);
    }

    return null;
  }

  Widget? _getFallbackChild() {
    if (fallbackIcon != null) {
      return Icon(
        fallbackIcon,
        color: Colors.grey[600],
        size: radius * 0.6,
      );
    }

    // Show first letter of name if available
    if (userData != null) {
      final name = userData!['name'] as String?;
      if (name != null && name.isNotEmpty) {
        return Text(
          name[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.5,
            color: Colors.grey[700],
          ),
        );
      }
    }

    return Icon(
      Icons.person,
      color: Colors.grey[600],
      size: radius * 0.6,
    );
  }
}
