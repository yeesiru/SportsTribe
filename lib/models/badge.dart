import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int requiredEvents;
  final String category;
  final int points;
  final bool isActive;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.requiredEvents,
    required this.category,
    required this.points,
    this.isActive = true,
  });

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? '',
      requiredEvents: data['requiredEvents'] ?? 0,
      category: data['category'] ?? '',
      points: data['points'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'requiredEvents': requiredEvents,
      'category': category,
      'points': points,
      'isActive': isActive,
    };
  }

  // Predefined badges
  static List<Badge> getDefaultBadges() {
    return [
      Badge(
        id: 'first_timer',
        name: 'First Timer',
        description: 'Attended your first event',
        iconPath: '🥉',
        requiredEvents: 1,
        category: 'participation',
        points: 10,
      ),
      Badge(
        id: 'regular_player',
        name: 'Regular Player',
        description: 'Attended 5 events',
        iconPath: '🥈',
        requiredEvents: 5,
        category: 'participation',
        points: 25,
      ),
      Badge(
        id: 'event_master',
        name: 'Event Master',
        description: 'Attended 10 events',
        iconPath: '🥇',
        requiredEvents: 10,
        category: 'participation',
        points: 50,
      ),
      Badge(
        id: 'sports_champion',
        name: 'Sports Champion',
        description: 'Attended 20 events',
        iconPath: '🏆',
        requiredEvents: 20,
        category: 'participation',
        points: 100,
      ),
      Badge(
        id: 'organizer',
        name: 'Event Organizer',
        description: 'Created and completed an event',
        iconPath: '📋',
        requiredEvents: 0,
        category: 'organizing',
        points: 30,
      ),
    ];
  }
}
