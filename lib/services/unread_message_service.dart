import 'package:flutter/foundation.dart';

class UnreadMessageService {
  static final UnreadMessageService _instance =
      UnreadMessageService._internal();

  factory UnreadMessageService() {
    return _instance;
  }

  UnreadMessageService._internal();

  final Set<String> _readClubs = <String>{};
  final Map<String, DateTime> _lastReadTimes = <String, DateTime>{};
  final Map<String, ValueNotifier<bool>> _unreadNotifiers =
      <String, ValueNotifier<bool>>{};

  // Get or create a notifier for a specific club
  ValueNotifier<bool> getUnreadNotifier(String clubId) {
    if (!_unreadNotifiers.containsKey(clubId)) {
      _unreadNotifiers[clubId] = ValueNotifier<bool>(false);
    }
    return _unreadNotifiers[clubId]!;
  }

  // Mark a club as read
  void markAsRead(String clubId) {
    _readClubs.add(clubId);
    _lastReadTimes[clubId] = DateTime.now();

    // Update the notifier
    if (_unreadNotifiers.containsKey(clubId)) {
      _unreadNotifiers[clubId]!.value = false;
    }
  }

  // Check if a club has unread messages
  bool hasUnreadMessages(String clubId, DateTime lastMessageTime) {
    if (!_lastReadTimes.containsKey(clubId)) {
      // If we've never read this club, it has unread messages if it has any messages
      return true;
    }

    final lastReadTime = _lastReadTimes[clubId]!;
    return lastMessageTime.isAfter(lastReadTime);
  }

  // Update unread status for a club
  void updateUnreadStatus(String clubId, DateTime lastMessageTime) {
    final hasUnread = hasUnreadMessages(clubId, lastMessageTime);

    // Update the notifier
    if (_unreadNotifiers.containsKey(clubId)) {
      _unreadNotifiers[clubId]!.value = hasUnread;
    }
  }

  // Clean up resources
  void dispose() {
    for (final notifier in _unreadNotifiers.values) {
      notifier.dispose();
    }
    _unreadNotifiers.clear();
  }
}
