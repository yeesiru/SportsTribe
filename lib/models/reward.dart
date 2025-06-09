import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  String id;
  String title;
  String description;
  String imageUrl;
  int pointsCost;
  bool isActive;
  int? quantity; // Optional field for limited quantity rewards
  int? redeemedCount; // Track how many times the reward has been redeemed
  final Timestamp createdAt;
  Timestamp updatedAt;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    required this.isActive,
    this.quantity,
    this.redeemedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Reward.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Reward(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pointsCost: data['pointsCost'] ?? 0,
      isActive: data['isActive'] ?? false,
      quantity: data['quantity'],
      redeemedCount: data['redeemedCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'pointsCost': pointsCost,
      'isActive': isActive,
      'quantity': quantity,
      'redeemedCount': redeemedCount ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Check if reward is available (has stock)
  bool get hasStock {
    if (quantity == null) return true; // Unlimited quantity
    return quantity! > (redeemedCount ?? 0);
  }

  // Get available quantity
  int? get availableQuantity {
    if (quantity == null) return null; // Unlimited quantity
    return quantity! - (redeemedCount ?? 0);
  }
}