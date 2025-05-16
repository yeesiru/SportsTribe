import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/home_page.dart';

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
  final List<ChatItem> _chats = [
    ChatItem(
      name: 'Badminton Squad',
      lastMessage: 'Send your first message!',
      time: '16:33',
      image: 'assets/images/badminton.jpg',
      isGroup: true,
    ),
    ChatItem(
      name: 'Happy',
      lastMessage: 'Happy: Are you free?',
      time: '10:15',
      image: 'assets/images/profile.jpg', // Placeholder image
    ),
    ChatItem(
      name: 'Steven',
      lastMessage: 'You: I\'m coming.',
      time: 'Yesterday',
      image: 'assets/images/profile.jpg', // Placeholder image
    ),
  ];
  
  // Filtered chats based on search
  List<ChatItem> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    
    return _chats.where((chat) {
      final name = chat.name.toLowerCase();
      final message = chat.lastMessage.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || message.contains(query);
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
          MaterialPageRoute(builder: (context) => LeaderboardPage(initialTabIndex: 2)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ProfilePage(initialTabIndex: 3)),
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
                  color: isActive ? Colors.black.withOpacity(0.1) : Colors.transparent,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              color: Color(0xFFCCE945),
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back),
                    ),
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
                                      icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
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
                    child: _filteredChats.isEmpty && _searchQuery.isNotEmpty
                      ? Center(
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
                        )
                      : ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(chat.image),
                              ),
                              title: Text(
                                chat.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                chat.lastMessage,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                chat.time,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              onTap: () {
                                // Navigate to individual chat
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
                }
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline, 
                isActive: _currentTabIndex == 1,
                onTap: () {
                }
              ),
              _buildNavItem(
                icon: Icons.rocket, 
                isActive: _currentTabIndex == 2,
                onTap: () {
                  _navigateToPage(2);
                },
                hasNotification: true
              ),
              _buildNavItem(
                icon: Icons.person_outline, 
                isActive: _currentTabIndex == 3,
                onTap: () {
                  _navigateToPage(3);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatItem {
  final String name;
  final String lastMessage;
  final String time;
  final String image;
  final bool isGroup;
  
  ChatItem({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.image,
    this.isGroup = false,
  });
} 