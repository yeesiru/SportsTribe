import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_project/pages/createClub_page.dart';
import 'package:map_project/pages/profile_page.dart';
import 'package:map_project/pages/chat_page.dart';
import 'package:map_project/pages/leaderboard_page.dart';
import 'package:map_project/pages/club_details_page.dart';
import 'package:map_project/pages/create_event.dart';
import 'package:map_project/pages/create_post.dart';
import 'package:map_project/pages/browse_community.dart';
import 'package:map_project/pages/view_event_page.dart';

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

  // Fetch club where creatorID match userID
  Stream<QuerySnapshot> getUserRelatedClubs() {
    final uid = user.uid;
    return FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .snapshots();
  }

  // Fetch all public and user clubs
  Future<List<String>> _getRelevantClubIds() async {
    final uid = user.uid;
    final userClubsSnap = await FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: uid)
        .get();
    final publicClubsSnap = await FirebaseFirestore.instance
        .collection('club')
        .where('isPrivate', isEqualTo: false)
        .get();
    final userClubIds = userClubsSnap.docs.map((doc) => doc.id).toSet();
    final publicClubIds = publicClubsSnap.docs.map((doc) => doc.id).toSet();
    return {...userClubIds, ...publicClubIds}.toList();
  }

  Future<List<Map<String, dynamic>>> _getAllClubItems(
      {required bool isEvent}) async {
    final clubIds = await _getRelevantClubIds();
    List<Map<String, dynamic>> allItems = [];

    // Get club events/posts
    for (final clubId in clubIds) {
      try {
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
          data['type'] = 'club';
          allItems.add(data);
        }
      } catch (e) {
        print(
            'Error fetching ${isEvent ? 'events' : 'posts'} for club $clubId: $e');
        // Continue with other clubs even if one fails
      }
    }

    // Also fetch personal events if we're looking for events
    if (isEvent) {
      try {
        // Get ALL personal events for the current user (both public and private)
        final userPersonalEventsSnap = await FirebaseFirestore.instance
            .collection('events')
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in userPersonalEventsSnap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['type'] = 'personal';
          allItems.add(data);
        }
      } catch (e) {
        print('Error fetching user personal events: $e');
      }

      try {
        // Get all PUBLIC personal events from OTHER users (not current user to avoid duplicates)
        final publicPersonalEventsSnap = await FirebaseFirestore.instance
            .collection('events')
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in publicPersonalEventsSnap.docs) {
          final data = doc.data();
          // Skip if this event is already added (created by current user)
          if (data['createdBy'] != user.uid) {
            data['id'] = doc.id;
            data['type'] = 'personal';
            allItems.add(data);
          }
        }
      } catch (e) {
        print('Error fetching public personal events: $e');
      }
    }

    // Sort all items by creation date
    allItems.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bTime = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return allItems;
  }

  Widget _buildEventsOrPostsTab(bool isEvent) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllClubItems(isEvent: isEvent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
              child: Text(isEvent ? 'No events found.' : 'No posts found.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final data = items[idx];
            final bool isUserEvent = data['createdBy'] == user.uid;

            if (isEvent) {
              return _buildEventCard(data, isUserEvent);
            } else {
              return _buildPostCard(data);
            }
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data, bool isUserEvent) {
    // Fix the type cast error - handle both int and List for participants
    final dynamic participantsData = data['participants'];
    final List<dynamic> participants = participantsData is List
        ? participantsData
        : participantsData is int
            ? [
                data['createdBy']
              ] // If it's an int, convert to list with creator
            : []; // Default to empty list
    final maxParticipants = data['maxParticipants'] ?? 0;
    final isUserJoined = participants.contains(user.uid);
    final eventType = data['type'] ?? 'personal';
    final sport = data['sport'] ?? 'Unknown';
    final level = data['level'] ?? 'All levels';
    final location = data['location'] ?? 'Location TBD';

    // Parse date and time
    String dateTimeText = 'Date TBD';
    if (data['date'] != null) {
      final date = (data['date'] as Timestamp).toDate();
      final time = data['time'] ?? '';
      dateTimeText = '${date.day}/${date.month}/${date.year}';
      if (time.isNotEmpty) {
        dateTimeText += ' at $time';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image with overlay
              if (data['imageUrl'] != null && data['imageUrl'] != '')
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          data['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      // Event type badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: eventType == 'personal'
                                ? Color(0xFFD7F520).withOpacity(0.9)
                                : Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            eventType == 'personal' ? 'Personal' : 'Club',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Menu button for user events
                      if (isUserEvent)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.black),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editEvent(data);
                                } else if (value == 'delete') {
                                  _deleteEvent(data);
                                } else if (value == 'view') {
                                  _viewEvent(data);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 20),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                // Placeholder when no image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD7F520).withOpacity(0.3),
                        Color(0xFFD7F520).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      ),
                      // Event type badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: eventType == 'personal'
                                ? Color(0xFFD7F520)
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            eventType == 'personal' ? 'Personal' : 'Club',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Menu button for user events
                      if (isUserEvent)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: PopupMenuButton<String>(
                            icon:
                                Icon(Icons.more_vert, color: Colors.grey[700]),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editEvent(data);
                              } else if (value == 'delete') {
                                _deleteEvent(data);
                              } else if (value == 'view') {
                                _viewEvent(data);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              // Event content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title
                    Text(
                      data['title'] ?? data['content'] ?? 'Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 12),

                    // Event details in info cards
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildEventInfoRow(
                            icon: Icons.calendar_today,
                            text: dateTimeText,
                            color: Colors.blue[600]!,
                          ),
                          SizedBox(height: 8),
                          _buildEventInfoRow(
                            icon: Icons.location_on,
                            text: location,
                            color: Colors.red[600]!,
                          ),
                          SizedBox(height: 8),
                          _buildEventInfoRow(
                            icon: Icons.sports,
                            text: '$sport • $level',
                            color: Colors.green[600]!,
                          ),
                          SizedBox(height: 8),
                          _buildEventInfoRow(
                            icon: Icons.group,
                            text:
                                '${participants.length}/$maxParticipants participants',
                            color: participants.length >= maxParticipants
                                ? Colors.red[600]!
                                : Colors.orange[600]!,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _viewEvent(data),
                            icon: Icon(Icons.visibility, size: 18),
                            label: Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isUserJoined ||
                                    participants.length >= maxParticipants
                                ? null
                                : () => _joinEvent(data),
                            icon: Icon(
                              isUserJoined
                                  ? Icons.check_circle
                                  : participants.length >= maxParticipants
                                      ? Icons.block
                                      : Icons.add_circle,
                              size: 18,
                            ),
                            label: Text(
                              isUserJoined
                                  ? 'Joined'
                                  : participants.length >= maxParticipants
                                      ? 'Full'
                                      : 'Join',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUserJoined
                                  ? Colors.green[400]
                                  : participants.length >= maxParticipants
                                      ? Colors.grey[400]
                                      : Color(0xFFD7F520),
                              foregroundColor: isUserJoined ||
                                      participants.length >= maxParticipants
                                  ? Colors.white
                                  : Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: isUserJoined ||
                                      participants.length >= maxParticipants
                                  ? 0
                                  : 2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Time ago
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          data['createdAt'] != null
                              ? _formatDate(
                                  (data['createdAt'] as Timestamp).toDate())
                              : '',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        leading: data['imageUrl'] != null && data['imageUrl'] != ''
            ? CircleAvatar(backgroundImage: NetworkImage(data['imageUrl']))
            : CircleAvatar(child: Icon(Icons.article)),
        title: Text(data['content'] ?? ''),
        subtitle: Text(data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate().toString()
            : ''),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _joinEvent(Map<String, dynamic> eventData) async {
    try {
      if (eventData['type'] == 'personal') {
        // Personal event
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventData['id'])
            .update({
          'participants': FieldValue.arrayUnion([user.uid])
        });
      } else {
        // Club event
        await FirebaseFirestore.instance
            .collection('club')
            .doc(eventData['clubId'])
            .collection('events')
            .doc(eventData['id'])
            .update({
          'participants': FieldValue.arrayUnion([user.uid])
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined event successfully!')),
      );
      setState(() {}); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
    }
  }

  void _editEvent(Map<String, dynamic> eventData) {
    // Navigate to edit event page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventPage(
          clubId: eventData['type'] == 'club' ? eventData['clubId'] : null,
          eventData: eventData,
        ),
      ),
    );
  }

  void _deleteEvent(Map<String, dynamic> eventData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (eventData['type'] == 'personal') {
                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventData['id'])
                      .delete();
                } else {
                  await FirebaseFirestore.instance
                      .collection('club')
                      .doc(eventData['clubId'])
                      .collection('events')
                      .doc(eventData['id'])
                      .delete();
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Event deleted successfully!')),
                );
                setState(() {}); // Refresh the list
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting event: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewEvent(Map<String, dynamic> eventData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewEventPage(
          eventId: eventData['id'],
          eventData: eventData,
          clubId: eventData['type'] == 'club' ? eventData['clubId'] : null,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage('assets/images/profile.jpg'),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Hi, ${user.displayName ?? user.email!.split('@')[0]}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // User's created communities (clubs)
                      StreamBuilder<QuerySnapshot>(
                        stream: getUserRelatedClubs(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.green[200],
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.data == null ||
                              snapshot.data!.docs.isEmpty) {
                            // No communities joined, show only Join Community
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BrowseCommunityPage(),
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
                                      Text('Join community',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.chevron_right),
                              ],
                            );
                          }
                          // Show all clubs the user is related to
                          return Row(
                            children: [
                              ...snapshot.data!.docs.map((doc) {
                                final club = doc.data() as Map<String, dynamic>;
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
                                    padding: const EdgeInsets.only(right: 16.0),
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
                                        Text(club['name'] ?? 'My Club',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              SizedBox(width: 10),
                              // Join community column (static)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BrowseCommunityPage(),
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
                                    Text('Join community',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.chevron_right),
                            ],
                          );
                        },
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
}
