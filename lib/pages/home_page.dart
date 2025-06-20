import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/browse_clubs_page.dart';
import 'package:map_project/pages/createClub_page.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/club_details_page.dart';
import 'package:map_project/pages/create_event.dart';
import 'package:map_project/pages/create_post.dart';
import 'package:map_project/pages/my_clubs_page.dart';
import 'package:map_project/pages/post_details_page.dart';
import 'package:map_project/widgets/user_avatar.dart';
import 'package:map_project/services/user_service.dart';

class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  late int _currentTabIndex; // 0 = home, 1 = chat, 2 = leaderboard, 3 = profile

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  // Get user data stream for real-time updates
  Stream<Map<String, dynamic>?> getUserDataStream() {
    return UserService.getCurrentUserDataStream();
  }

  Stream<QuerySnapshot> getUserRelatedClubs() {
    final uid = user.uid;
    return FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .snapshots();
  }

  // Fetch only user's joined clubs (not public clubs)
  Future<List<String>> _getRelevantClubIds() async {
    final uid = user.uid;
    final userClubsSnap = await FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .get();
    return userClubsSnap.docs.map((doc) => doc.id).toList();
  }

  Future<List<Map<String, dynamic>>> _getAllClubItems(
      {required bool isEvent}) async {
    final clubIds = await _getRelevantClubIds();
    List<Map<String, dynamic>> allItems = [];
    for (final clubId in clubIds) {
      final snap = await FirebaseFirestore.instance
          .collection('club')
          .doc(clubId)
          .collection(isEvent ? 'events' : 'posts')
          .orderBy('createdAt', descending: true)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        data['clubId'] = clubId;
        data['id'] = doc.id;
        allItems.add(data);
      }
    }
    return allItems;
  }

  Widget _buildEventsOrPostsTab(bool isEvent) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllClubItems(isEvent: isEvent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFD7F520),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading ${isEvent ? 'events' : 'posts'}...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEvent ? Icons.event_busy : Icons.article_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  isEvent ? 'No events found' : 'No posts found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isEvent
                      ? 'Join some clubs to see their events!'
                      : 'Join some clubs to see their posts!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Sort items by creation date (newest first)
        items.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return RefreshIndicator(
          color: Color(0xFFD7F520),
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh data
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final data = items[idx];
              return _buildEventOrPostCard(data, isEvent, idx);
            },
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPage(int index) {
    if (index == _currentTabIndex) return; // Already on this page

    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1: // Chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(initialTabIndex: 1)),
        );
        break;
      case 2: // Leaderboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LeaderboardPage(initialTabIndex: 2)),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(initialTabIndex: 3)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            // Navigate to Create Event page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateEventPage()),
            );
          } else {
            // Navigate to Create Post page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostPage()),
            );
          }
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: getUserDataStream(),
                      builder: (context, snapshot) {
                        final userData = snapshot.data;

                        return Row(
                          children: [
                            _buildUserAvatar(userData),
                            SizedBox(width: 10),
                            Text(
                              'Hi, ${userData?['name'] ?? user.displayName ?? user.email!.split('@')[0]}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.notifications_outlined),
                                onPressed: () {},
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateclubPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 5),
                        Text('520 pts',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Scrollable joined clubs section (left side)
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: getUserRelatedClubs(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.green[200],
                                      child: CircularProgressIndicator(),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.data == null ||
                                snapshot.data!.docs.isEmpty) {
                              // No communities joined, show placeholder
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.grey[300],
                                            child: Icon(Icons.groups_outlined,
                                                color: Colors.grey[600]),
                                          ),
                                          SizedBox(height: 8),
                                          Text('No clubs yet',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Show all clubs the user is related to in a scrollable row
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: snapshot.data!.docs.map((doc) {
                                  final club =
                                      doc.data() as Map<String, dynamic>;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ClubDetailsPage(
                                            clubId: doc.id,
                                            clubData: club,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.green[200],
                                            backgroundImage: club['imageUrl'] !=
                                                    null
                                                ? NetworkImage(club['imageUrl'])
                                                : null,
                                            child: club['imageUrl'] == null
                                                ? Icon(Icons.sports_tennis,
                                                    color: Colors.green[800])
                                                : null,
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            width: 60,
                                            child: Text(
                                              club['name'] ?? 'My Club',
                                              style: TextStyle(fontSize: 12),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                      // Fixed Join Community button (right side)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrowseClubsPage(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: Icon(Icons.group_add,
                                  color: Colors.grey[800]),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 60,
                              child: Text(
                                'Join Club',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10), // Fixed arrow button (right side)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyClubsPage(),
                            ),
                          );
                        },
                        child: Icon(Icons.chevron_right,
                            size: 30, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs for Events and Posts
          Container(
            margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Events',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedIndex == 0 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Posts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedIndex == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildEventsOrPostsTab(true)
                : _buildEventsOrPostsTab(false),
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
                  onTap: () => _navigateToPage(0)),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  isActive: _currentTabIndex == 1,
                  onTap: () => _navigateToPage(1)),
              _buildNavItem(
                  icon: Icons.rocket,
                  isActive: _currentTabIndex == 2,
                  onTap: () => _navigateToPage(2),
                  hasNotification: true),
              _buildNavItem(
                  icon: Icons.person_outline,
                  isActive: _currentTabIndex == 3,
                  onTap: () => _navigateToPage(3)),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build user avatar
  Widget _buildUserAvatar(Map<String, dynamic>? userData,
      {double radius = 20}) {
    return UserAvatar(
      userData: userData,
      radius: radius,
    );
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

  Widget _buildEventOrPostCard(
      Map<String, dynamic> data, bool isEvent, int index) {
    final createdAt = data['createdAt'] as Timestamp?;
    final imageUrl = data['imageUrl'] as String?;
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final category = data['category'] as String?;
    final isImportant = data['isImportant'] as bool? ?? false;
    final likesCount = data['likesCount'] as int? ?? 0;
    final commentsCount = data['commentsCount'] as int? ?? 0;
    final tags = data['tags'] as List?;
    final clubId = data['clubId'] as String?;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (!isEvent) {
            // Navigate to post details page for posts only
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsPage(
                  clubId: clubId!,
                  postId: data['id'],
                  postData: data,
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border:
                isImportant ? Border.all(color: Colors.amber, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with club info and timestamp
              _buildCardHeader(data, isEvent, createdAt, clubId),

              // Category and importance badges
              if (category != null || isImportant)
                _buildBadgeRow(category, isImportant, isEvent),

              // Title (for posts)
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

              // Content
              if (content.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                _buildCardImage(imageUrl),

              // Tags
              if (tags != null && tags.isNotEmpty) _buildTagsRow(tags),

              // Event specific info
              if (isEvent) _buildEventInfo(data),

              // Action buttons (likes, comments, share)
              _buildActionButtons(likesCount, commentsCount, isEvent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> data, bool isEvent,
      Timestamp? createdAt, String? clubId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: clubId != null
          ? FirebaseFirestore.instance.collection('club').doc(clubId).get()
          : null,
      builder: (context, clubSnapshot) {
        final clubData = clubSnapshot.data?.data() as Map<String, dynamic>?;
        final clubName = clubData?['name'] ?? 'Unknown Club';
        final clubImage = clubData?['imageUrl'];

        return Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Club avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green[200],
                backgroundImage:
                    clubImage != null ? NetworkImage(clubImage) : null,
                child: clubImage == null
                    ? Icon(Icons.sports_tennis,
                        color: Colors.green[800], size: 20)
                    : null,
              ),
              SizedBox(width: 12),
              // Club name and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clubName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isEvent ? Icons.event : Icons.article,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatTimestamp(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More options
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onPressed: () {
                  // TODO: Show options menu
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeRow(String? category, bool isImportant, bool isEvent) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (isImportant)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber[800]),
                  SizedBox(width: 4),
                  Text(
                    'Important',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
          if (isImportant && category != null) SizedBox(width: 8),
          if (category != null && category != 'General')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _getCategoryColor(category), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getCategoryIcon(category),
                  SizedBox(width: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage(String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD7F520),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagsRow(List tags) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.take(5).map((tag) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFD7F520).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${tag.toString()}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventInfo(Map<String, dynamic> data) {
    final eventDate = data['eventDate'] as Timestamp?;
    final location = data['location'] as String?;
    final maxParticipants = data['maxParticipants'] as int?;
    final participants = data['participants'] as List?;

    if (eventDate == null && location == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFD7F520).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD7F520).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eventDate != null)
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  _formatEventDate(eventDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          if (eventDate != null && location != null) SizedBox(height: 8),
          if (location != null)
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.black87),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          if (maxParticipants != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    '${participants?.length ?? 0}/$maxParticipants participants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int likesCount, int commentsCount, bool isEvent) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            count: likesCount,
            label: 'Like',
            onTap: () {
              // TODO: Implement like functionality
            },
          ),
          SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.comment_outlined,
            activeIcon: Icons.comment,
            count: commentsCount,
            label: 'Comment',
            onTap: () {
              // TODO: Implement comment functionality
            },
          ),
          SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.share_outlined,
            activeIcon: Icons.share,
            count: 0,
            label: 'Share',
            onTap: () {
              // TODO: Implement share functionality
            },
          ),
          Spacer(),
          if (isEvent)
            ElevatedButton(
              onPressed: () {
                // TODO: Implement join event functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD7F520),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Join Event',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 20,
            color: isActive ? Colors.red : Colors.grey[600],
          ),
          if (count > 0) ...[
            SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatEventDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;
    final isTomorrow = date.difference(now).inDays == 1;

    if (isToday) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (isTomorrow) {
      return 'Tomorrow at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Announcement':
        return Colors.red;
      case 'Discussion':
        return Colors.blue;
      case 'Question':
        return Colors.orange;
      case 'Achievement':
        return Colors.amber;
      case 'Event Recap':
        return Colors.purple;
      case 'Tips & Advice':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Announcement':
        return Icon(Icons.campaign, size: 12, color: Colors.red);
      case 'Discussion':
        return Icon(Icons.forum, size: 12, color: Colors.blue);
      case 'Question':
        return Icon(Icons.help_outline, size: 12, color: Colors.orange);
      case 'Achievement':
        return Icon(Icons.emoji_events, size: 12, color: Colors.amber);
      case 'Event Recap':
        return Icon(Icons.photo_library, size: 12, color: Colors.purple);
      case 'Tips & Advice':
        return Icon(Icons.lightbulb_outline,
            size: 12, color: Colors.yellow[700]);
      default:
        return Icon(Icons.label, size: 12, color: Colors.grey);
    }
  }
}
