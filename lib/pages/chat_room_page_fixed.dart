import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/models/chat_message.dart';
import 'package:map_project/models/app_user.dart';
import 'package:map_project/services/chat_service.dart';
import 'package:map_project/widgets/user_avatar.dart';
import 'package:map_project/services/user_service.dart';
import 'package:map_project/services/unread_message_service.dart';

class ChatRoomPage extends StatefulWidget {
  final Club club;

  const ChatRoomPage({
    super.key,
    required this.club,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser!;
  List<AppUser> clubMembers = [];
  final UnreadMessageService _unreadService = UnreadMessageService();

  @override
  void initState() {
    super.initState();
    _loadClubMembers();

    // Mark messages as read when entering the chat room
    _unreadService.markAsRead(widget.club.id);
  }

  void _loadClubMembers() async {
    final members = await ChatService.getClubMembers(widget.club.members);
    setState(() {
      clubMembers = members;
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      print('🚀 Attempting to send message: $message');
      await ChatService.sendMessage(widget.club.id, message);
      print('✅ Message sent successfully');

      // Scroll to bottom after sending message
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('❌ Failed to send message: $e');

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Put the message back in the text field
      _messageController.text = message;
    }
  }

  Widget _buildMemberProfile(AppUser member) {
    return Container(
      constraints: BoxConstraints(maxWidth: 70),
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getUserDataStream(member.uid),
            builder: (context, snapshot) {
              return UserAvatar(
                userData: snapshot.data,
                radius: 24,
              );
            },
          ),
          SizedBox(height: 4),
          Container(
            width: 70,
            child: Text(
              member.name.split(' ').first,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Show pin indicator if message is pinned
              if (message.isPinned)
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                    bottom: 4,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.push_pin,
                        size: 12,
                        color: Colors.amber[700],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pinned message',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isMe)
                Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe)
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: StreamBuilder<Map<String, dynamic>?>(
                        stream: UserService.getUserDataStream(message.senderId),
                        builder: (context, snapshot) {
                          return UserAvatar(
                            userData: snapshot.data,
                            radius: 16,
                          );
                        },
                      ),
                    ),
                  IntrinsicWidth(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
                      decoration: BoxDecoration(
                        color: isMe ? Color(0xFFD7F520) : Colors.grey[200],
                        border: message.isPinned
                            ? Border.all(color: Colors.amber[700]!, width: 2)
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.black : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatMalaysiaTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isMe ? Colors.black54 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format time for Malaysia timezone (UTC+8)
  String _formatMalaysiaTime(DateTime timestamp) {
    final malaysiaTime = timestamp.add(Duration(hours: 8));
    return DateFormat('h:mm a').format(malaysiaTime);
  }

  // Helper method to check if we should show date header
  bool _shouldShowDateHeader(List<ChatMessage> messages, int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final currentMalaysiaTime =
        currentMessage.timestamp.add(Duration(hours: 8));
    final nextMalaysiaTime = nextMessage.timestamp.add(Duration(hours: 8));

    final currentDate = DateTime(
      currentMalaysiaTime.year,
      currentMalaysiaTime.month,
      currentMalaysiaTime.day,
    );

    final nextDate = DateTime(
      nextMalaysiaTime.year,
      nextMalaysiaTime.month,
      nextMalaysiaTime.day,
    );

    return !currentDate.isAtSameMomentAs(nextDate);
  }

  // Format date for header using Malaysia time
  String _formatDateHeader(DateTime timestamp) {
    final malaysiaTime = timestamp.add(Duration(hours: 8));
    final now = DateTime.now().add(Duration(hours: 8));
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate =
        DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(malaysiaTime);
    }
  }

  // Build date header widget
  Widget _buildDateHeader(DateTime timestamp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Add a method to show pin/unpin options
  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: message.isPinned ? Colors.red : Colors.blue,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    if (message.isPinned) {
                      await ChatService.unpinMessage(
                          widget.club.id, message.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message unpinned')),
                      );
                    } else {
                      await ChatService.pinMessage(widget.club.id, message.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message pinned')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
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
            padding: EdgeInsets.fromLTRB(20, 50, 20, 15),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.club.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 70,
                    child: clubMembers.isEmpty
                        ? Center(
                            child: Text(
                              'Loading members...',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 12),
                            ),
                          )
                        : ClipRect(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: clubMembers.length,
                              itemBuilder: (context, index) {
                                return _buildMemberProfile(clubMembers[index]);
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(15, 15, 15, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Pinned Messages Section
                  StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.getPinnedMessages(widget.club.id),
                    builder: (context, pinnedSnapshot) {
                      if (!pinnedSnapshot.hasData ||
                          pinnedSnapshot.data!.isEmpty) {
                        return SizedBox.shrink();
                      }

                      final pinnedMessages = pinnedSnapshot.data!;
                      return Container(
                        color: Colors.amber[50],
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(Icons.push_pin,
                                      size: 16, color: Colors.amber[700]),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pinned Messages',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: pinnedMessages.length,
                                itemBuilder: (context, index) {
                                  final pinnedMessage = pinnedMessages[index];
                                  return Container(
                                    width: 250,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.amber[300]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pinnedMessage.senderName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Expanded(
                                          child: Text(
                                            pinnedMessage.message,
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          ),
                                        ),
                                        Text(
                                          _formatMalaysiaTime(
                                              pinnedMessage.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Divider(height: 1, color: Colors.amber[200]),
                          ],
                        ),
                      );
                    },
                  ),
                  // Regular Messages Section
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: ChatService.getClubMessages(widget.club.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final messages = snapshot.data!;
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == user.uid;

                            final showDateHeader =
                                _shouldShowDateHeader(messages, index);
                            return Column(
                              children: [
                                if (showDateHeader)
                                  _buildDateHeader(message.timestamp),
                                GestureDetector(
                                  onLongPress: () =>
                                      _showMessageOptions(message),
                                  child: _buildMessageBubble(message, isMe),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Message input
          Container(
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: Color(0xFFD7F520),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
