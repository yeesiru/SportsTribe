import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/home_page.dart';
import 'package:map_project/pages/chat_room_page.dart';
import 'package:map_project/models/club.dart';
import 'package:map_project/services/chat_service.dart';
import 'package:map_project/services/unread_message_service.dart';

class ChatPage extends StatefulWidget {
  final int initialTabIndex;

  const ChatPage({
    super.key,
    this.initialTabIndex = 1,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late int _currentTabIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final UnreadMessageService _unreadService = UnreadMessageService();
  List<Club> _getFilteredClubs(List<Club> clubs) {
    if (_searchQuery.isEmpty) {
      return clubs;
    }

    return clubs.where((club) {
      final name = club.name.toLowerCase().trim();
      final query = _searchQuery.toLowerCase().trim();

      // Get the first word of the club name
      final firstWord = name.split(' ').first;

      return firstWord.startsWith(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _currentTabIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _navigateToPage(int index) {
    if (index == _currentTabIndex) return; // Already on this page

    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(initialTabIndex: 0)),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LeaderboardPage(initialTabIndex: 2)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(initialTabIndex: 3)),
        );
        break;
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.black.withOpacity(0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
              if (hasNotification)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          if (isActive)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520), // Replaced color
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 16),
                    Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey[400], size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Club>>(
                      stream: ChatService.getUserJoinedClubs(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                  'Error loading clubs',
                                  style: TextStyle(
                                    color: Colors.red[500],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 12,
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
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No chat group',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please join a club to start chatting',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final clubs = _getFilteredClubs(snapshot.data!);

                        if (clubs.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No results found for "$_searchQuery"',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  child: Text('Clear search'),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: clubs.length,
                          itemBuilder: (context, index) {
                            final club = clubs[index];

                            // Update unread status for this club
                            _unreadService.updateUnreadStatus(
                                club.id, club.lastMessageTime);

                            return ValueListenableBuilder<bool>(
                              valueListenable:
                                  _unreadService.getUnreadNotifier(club.id),
                              builder: (context, hasUnread, child) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.green[200],
                                    backgroundImage: club.imageUrl.isNotEmpty
                                        ? NetworkImage(club.imageUrl)
                                        : null,
                                    child: club.imageUrl.isEmpty
                                        ? Icon(Icons.sports_tennis,
                                            color: Colors.green[800], size: 20)
                                        : null,
                                  ),
                                  title: Text(
                                    club.name,
                                    style: TextStyle(
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: hasUnread
                                          ? Colors.black
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    club.lastMessage.isEmpty
                                        ? 'No messages yet'
                                        : club.lastMessage,
                                    style: TextStyle(
                                      color: hasUnread
                                          ? Colors.black87
                                          : Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: hasUnread
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        ChatService.formatTimestamp(
                                            club.lastMessageTime),
                                        style: TextStyle(
                                          color: hasUnread
                                              ? Colors.black87
                                              : Colors.grey[500],
                                          fontSize: 12,
                                          fontWeight: hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (hasUnread)
                                        Container(
                                          margin: EdgeInsets.only(top: 4),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(0xFFD7F520),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Mark as read when tapping
                                    _unreadService.markAsRead(club.id);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChatRoomPage(club: club),
                                      ),
                                    );
                                  },
                                );
                              },
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
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  icon: Icons.group,
                  isActive: _currentTabIndex == 0,
                  onTap: () {
                    _navigateToPage(0);
                  }),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  isActive: _currentTabIndex == 1,
                  onTap: () {}),
              _buildNavItem(
                  icon: Icons.rocket,
                  isActive: _currentTabIndex == 2,
                  onTap: () {
                    _navigateToPage(2);
                  }),
              _buildNavItem(
                  icon: Icons.person_outline,
                  isActive: _currentTabIndex == 3,
                  onTap: () {
                    _navigateToPage(3);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
