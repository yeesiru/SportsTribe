import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/models/chat_message.dart';
import 'package:map_project/models/app_user.dart';
import 'package:map_project/services/chat_service.dart';
import 'package:map_project/services/firebase_test_service.dart';
import 'package:map_project/widgets/user_avatar.dart';
import 'package:map_project/services/user_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadClubMembers();
  }

  void _loadClubMembers() async {
    final members = await ChatService.getClubMembers(
        widget.club.members); // Changed from memberIds to members
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getUserDataStream(member.uid),
            builder: (context, snapshot) {
              return UserAvatar(
                userData: snapshot.data,
                radius: 20,
              );
            },
          ),
          SizedBox(height: 4),
          Text(
            member.name.split(' ').first,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
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
                          radius: 12,
                        );
                      },
                    ),
                  ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Color(0xFFD7F520) : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 8 : 0,
                    right: isMe ? 0 : 8,
                    bottom: 2,
                  ),
                  child: Text(
                    ChatService.formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
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
            padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                    // Debug button for testing messages
                    IconButton(
                      onPressed: () async {
                        await FirebaseTestService.testSendMessage(
                            widget.club.id);
                      },
                      icon:
                          Icon(Icons.bug_report, size: 20, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 16), // Member profiles
                Container(
                  height: 60,
                  child: clubMembers.isEmpty
                      ? Center(
                          child: Text(
                            'Loading members...',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: clubMembers.length,
                          itemBuilder: (context, index) {
                            return _buildMemberProfile(clubMembers[index]);
                          },
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
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.getClubMessages(widget.club.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
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
