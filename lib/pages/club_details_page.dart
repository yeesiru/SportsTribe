import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_project/pages/edit_club_page.dart';
import 'package:map_project/pages/create_event.dart';
import 'package:map_project/pages/create_post.dart';

class ClubDetailsPage extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic> clubData;

  const ClubDetailsPage({
    Key? key,
    required this.clubId,
    required this.clubData,
  }) : super(key: key);

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedTabIndex = 0;

  late Future<String> _creatorNameFuture;
  bool get isUserMember =>
      (widget.clubData['members'] as List?)?.contains(user.uid) ?? false;
  
  bool get isPrivateClub => widget.clubData['isPrivate'] ?? false;
  
  Future<bool> get hasPendingRequest async {
    final doc = await FirebaseFirestore.instance
        .collection('joinRequests')
        .where('clubId', isEqualTo: widget.clubId)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return doc.docs.isNotEmpty;
  }

  Future<String> _getCreatorName() async {
    try {
      final creatorId = widget.clubData['creatorId'];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    _creatorNameFuture = _getCreatorName();
  }

  Future<void> _leaveClub() async {
    try {
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .update({
        'members': FieldValue.arrayRemove([user.uid])
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        Navigator.of(context).pop(); // Pop the details page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving club: $e')),
        );
      }
    }
  }
  // Removed unused _joinClub method as joining is now handled directly in the button handler

  Future<void> _requestToJoin() async {
    try {
      await FirebaseFirestore.instance.collection('joinRequests').add({
        'clubId': widget.clubId,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent! Waiting for approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    }
  }

  // Show members list
  void _showMembersList() async {
    final members = widget.clubData['members'] as List? ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No members yet')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Community Members'),
        content: Container(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              members.map((memberId) async {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .get();
                return {
                  'id': memberId,
                  'name': doc.data()?['name'] ?? 'Unknown',
                  'photoUrl': doc.data()?['photoUrl'],
                };
              }),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return Text('No members found');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final member = snapshot.data![index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['photoUrl'] != null
                          ? NetworkImage(member['photoUrl'])
                          : null,
                      child: member['photoUrl'] == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(member['name']),
                    trailing: member['id'] == widget.clubData['creatorId']
                        ? Chip(
                            label: Text('Creator'),
                            backgroundColor: Color(0xFFD7F520),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reportClub() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Club'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting this club?'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement report functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report submitted')),
                );
              },
              child: Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.clubData['creatorId'] == user.uid;
    final bool isMember =
        (widget.clubData['members'] as List).contains(user.uid);
    final DateTime createdAt =
        (widget.clubData['createdAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat('MMMM d, y').format(createdAt);
    final tabs =
        isOwner ? ['Events', 'Posts', 'Requests'] : ['Events', 'Posts'];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isMember
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'event',
                  backgroundColor: Colors.black,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateEventPage(clubId: widget.clubId),
                      ),
                    );
                  },
                  child: Icon(Icons.event, color: Colors.white),
                  tooltip: 'Create Event',
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'post',
                  backgroundColor: Colors.black,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreatePostPage(clubId: widget.clubId),
                      ),
                    );
                  },
                  child: Icon(Icons.post_add, color: Colors.white),
                  tooltip: 'Create Post',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Club Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Color(0xFFD7F520),
              flexibleSpace: FlexibleSpaceBar(
                background: Center(
                  child: widget.clubData['imageUrl'] != null
                      ? CircleAvatar(
                          radius: 70,
                          backgroundImage:
                              NetworkImage(widget.clubData['imageUrl']),
                          backgroundColor: Colors.white,
                        )
                      : CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.sports_tennis,
                              size: 50, color: Colors.grey[400]),
                        ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditClubPage(
                              clubId: widget.clubId,
                              clubData: widget.clubData,
                            ),
                          ),
                        );
                        // Refresh the page if club was updated
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Club'),
                            content: Text(
                                'Are you sure you want to delete this club? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('club')
                              .doc(widget.clubId)
                              .delete();
                          if (mounted) Navigator.of(context).pop();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Club'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Club',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                if (!isOwner)
                  IconButton(
                    icon: Icon(Icons.report_problem_outlined,
                        color: Colors.black),
                    onPressed: _reportClub,
                  ),
              ],
            ),

            // Club Info
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Title
                    Text(
                      widget.clubData['name'] ?? 'Club Name',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Club Stats
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFD7F520).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Club Details Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.group,
                                label: 'Members',
                                value: (widget.clubData['members'] as List)
                                    .length
                                    .toString(),
                              ),
                              _buildStatItem(
                                icon: Icons.sports,
                                label: 'Sport',
                                value: widget.clubData['sport'] ?? 'N/A',
                              ),
                              _buildStatItem(
                                icon: Icons.grade,
                                label: 'Level',
                                value: widget.clubData['skillLevel'] ?? 'N/A',
                              ),
                            ],
                          ),
                          Divider(height: 30, color: Color(0xFFD7F520)),
                          // Creator Info
                          FutureBuilder<String>(
                            future:
                                _creatorNameFuture, // <-- Ensure this is set!
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text('Loading...',
                                        style:
                                            TextStyle(color: Colors.grey[700])),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                return Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text('Error fetching creator',
                                        style:
                                            TextStyle(color: Colors.grey[700])),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        color: Colors.grey[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Created by: ${snapshot.data}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),

                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.grey[700]),
                              SizedBox(width: 8),
                              Text(
                                'Created on: $formattedDate',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Leave Button (if not owner)
                    if (!isOwner)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Leave Club'),
                                content: Text(
                                    'Are you sure you want to leave this club?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _leaveClub();
                                    },
                                    child: Text('Leave',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Leave Club',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFD7F520).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: List.generate(
                            tabs.length, (i) => _buildTab(tabs[i], i)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Builder(
                  builder: (context) {
                    if (_selectedTabIndex == 0) {
                      return _buildEventsTabWithImages(widget.clubId, isOwner);
                    } else if (_selectedTabIndex == 1) {
                      return _buildPostsTabWithImages(widget.clubId, isOwner);
                    } else if (_selectedTabIndex == 2 && isOwner) {
                      return _buildRequestsTab(widget.clubId);
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
  }) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFFD7F520).withOpacity(0.7),
          child: Icon(icon, color: Colors.black87),
          radius: 22,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            decoration: isClickable ? TextDecoration.underline : null,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            decoration: isClickable ? TextDecoration.underline : null,
          ),
        ),
        if (isClickable)
          Text(
            'Click to view',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFD7F520) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildEventsTabWithImages(String clubId, bool isOwner) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('club')
        .doc(clubId)
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No events yet'));
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var event = snapshot.data!.docs[index];
            final data = event.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null && data['imageUrl'] != '')
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        data['imageUrl'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ListTile(
                    leading: Icon(Icons.event),
                    title: Text(data['content'] ?? 'Untitled'),
                    subtitle:
                        Text('Participants: ${data['participants'] ?? '-'}'),
                    trailing: isOwner &&
                            data['createdBy'] ==
                                FirebaseAuth.instance.currentUser?.uid
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              // TODO: Implement edit, delete, archive, view participants
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit')
                                  ])),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Delete')
                                  ])),
                              PopupMenuItem(
                                  value: 'archive',
                                  child: Row(children: [
                                    Icon(Icons.archive),
                                    SizedBox(width: 8),
                                    Text('Archive')
                                  ])),
                              PopupMenuItem(
                                  value: 'participants',
                                  child: Row(children: [
                                    Icon(Icons.group),
                                    SizedBox(width: 8),
                                    Text('View participants')
                                  ])),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      }
    },
  );
}

Widget _buildPostsTabWithImages(String clubId, bool isOwner) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('club')
        .doc(clubId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No posts yet'));
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var post = snapshot.data!.docs[index];
            final data = post.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null && data['imageUrl'] != '')
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        data['imageUrl'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ListTile(
                    leading: Icon(Icons.article),
                    title: Text(data['content'] ?? 'Untitled'),
                    trailing: isOwner &&
                            data['createdBy'] ==
                                FirebaseAuth.instance.currentUser?.uid
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              // TODO: Implement edit, delete, archive
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit')
                                  ])),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Delete')
                                  ])),
                              PopupMenuItem(
                                  value: 'archive',
                                  child: Row(children: [
                                    Icon(Icons.archive),
                                    SizedBox(width: 8),
                                    Text('Archive')
                                  ])),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      }
    },
  );
}

Widget _buildRequestsTab(String clubId) {
  // Placeholder for requests tab. You can implement join requests logic here.
  return Center(
    child: Text('Requests tab (for join requests management)'),
  );
}
