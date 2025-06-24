import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/models/chat_message.dart';
import 'package:map_project/services/chat_service.dart';
import 'package:map_project/widgets/user_avatar.dart';
import 'package:map_project/services/user_service.dart';

class PinnedMessagesPage extends StatelessWidget {
  final Club club;

  const PinnedMessagesPage({
    super.key,
    required this.club,
  });

  // Format time for Malaysia timezone (UTC+8)
  String _formatMalaysiaTime(DateTime timestamp) {
    final malaysiaTime = timestamp.add(Duration(hours: 8));
    return DateFormat('MMM dd, yyyy • h:mm a').format(malaysiaTime);
  }

  Widget _buildPinnedMessageCard(ChatMessage message) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber[300]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar, name, and pin icon
            Row(
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: UserService.getUserDataStream(message.senderId),
                  builder: (context, snapshot) {
                    return UserAvatar(
                      userData: snapshot.data,
                      radius: 20,
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatMalaysiaTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.push_pin,
                  color: Colors.amber[700],
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Message content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.push_pin,
                  color: Colors.black,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinned Messages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ), // Pinned Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getPinnedMessages(club.id),
              builder: (context, snapshot) {
                print(
                    '🏠 PinnedMessagesPage - StreamBuilder state: ${snapshot.connectionState}');
                print('🏠 PinnedMessagesPage - Has data: ${snapshot.hasData}');
                if (snapshot.hasData) {
                  print(
                      '🏠 PinnedMessagesPage - Data length: ${snapshot.data!.length}');
                  for (var message in snapshot.data!) {
                    print(
                        '🏠 PinnedMessagesPage - Message: ${message.message}, isPinned: ${message.isPinned}');
                  }
                }
                if (snapshot.hasError) {
                  print('🏠 PinnedMessagesPage - Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading pinned messages',
                          style: TextStyle(
                            color: Colors.red[500],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.push_pin_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pinned messages',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Long press on any message in the chat to pin it',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final pinnedMessages = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: pinnedMessages.length,
                  itemBuilder: (context, index) {
                    final message = pinnedMessages[index];
                    return _buildPinnedMessageCard(message);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
