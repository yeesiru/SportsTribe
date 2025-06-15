import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_project/pages/edit_club_page.dart';
import 'package:map_project/pages/manage_requests_page.dart';

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
    final bool isCreator = widget.clubData['creatorId'] == user.uid;
    final DateTime createdAt = (widget.clubData['createdAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat('MMMM d, y').format(createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
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
                    if (isCreator)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) async {                          if (value == 'edit') {
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
                          } else if (value == 'requests') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageRequestsPage(
                                  clubId: widget.clubId,
                                  clubData: widget.clubData,
                                ),
                              ),
                            );
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
                          if (isPrivateClub)
                            PopupMenuItem(
                              value: 'requests',
                              child: Text('Manage Requests'),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Club',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    if (!isCreator)
                      IconButton(
                        icon:
                            Icon(Icons.report_problem_outlined, color: Colors.black),
                        onPressed: _reportClub,
                      ),
                  ],
                ),
        
                // Club Info
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20),
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
                        if (isPrivateClub)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  'Private Community',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 20),
        
                        // Club Stats with clickable members
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
                                  // Members count (clickable)
                                  GestureDetector(
                                    onTap: _showMembersList,
                                    child: _buildStatItem(
                                      icon: Icons.group,
                                      label: 'Members',
                                      value: (widget.clubData['members'] as List).length.toString(),
                                      isClickable: true,
                                    ),
                                  ),
                                  // Other stats
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
                                future: _creatorNameFuture, // <-- Ensure this is set!
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
                                  Icon(Icons.calendar_today, color: Colors.grey[700]),
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
        
                        // Join/Leave Button
                        if (!isCreator)
                          FutureBuilder<bool>(
                            future: hasPendingRequest,
                            builder: (context, snapshot) {
                              final isPending = snapshot.data ?? false;
                              
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isUserMember
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text('Leave Community'),
                                              content: Text(
                                                  'Are you sure you want to leave this community?'),
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
                                        }
                                      : isPending
                                          ? null
                                          : isPrivateClub
                                              ? _requestToJoin
                                              : () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('club')
                                                      .doc(widget.clubId)
                                                      .update({
                                                    'members':
                                                        FieldValue.arrayUnion([user.uid])
                                                  });

                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Successfully joined the community!')),
                                                    );
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUserMember
                                        ? Colors.red
                                        : isPending
                                            ? Colors.grey[400]
                                            : Color(0xFFD7F520),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isUserMember
                                        ? 'Leave Community'
                                        : isPending
                                            ? 'Request Pending'
                                            : isPrivateClub
                                                ? 'Request to Join'
                                                : 'Join Community',
                                    style: TextStyle(
                                      color: isUserMember || isPending
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
        
                        SizedBox(height: 20),
        
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFD7F520).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              _buildTab('Events', 0),
                              _buildTab('Posts', 1),
                            ],
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
                    child: _selectedTabIndex == 0
                        ? _buildEventsTab(widget.clubId)
                        : _buildPostsTab(widget.clubId),
                  ),
                ),
              ],
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     height: 200,
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [Color(0xFFD7F520), Colors.white],
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //       ),
            //     ),
            //   ),
            // ),
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

Widget _buildEventsTab(String clubId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('events')
        .where('clubId', isEqualTo: clubId)
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
            return ListTile(
              title: Text(event['title'] ?? 'Untitled'),
              subtitle: Text(event['description'] ?? 'No description'),
              leading: Icon(Icons.event),
            );
          },
        );
      }
    },
  );
}

Widget _buildPostsTab(String clubId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('posts')
        .where('clubId', isEqualTo: clubId)
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
            return ListTile(
              title: Text(post['title'] ?? 'Untitled'),
              subtitle: Text(post['content'] ?? 'No content'),
              leading: Icon(Icons.article),
            );
          },
        );
      }
    },
  );
}
