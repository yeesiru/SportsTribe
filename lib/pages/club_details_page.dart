import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:map_project/pages/edit_club_page.dart';
import 'package:map_project/pages/create_event.dart';
import 'package:map_project/pages/create_post.dart';
import 'package:map_project/pages/post_details_page.dart';
import 'package:map_project/pages/club_members_page.dart';
import 'package:map_project/widgets/user_avatar.dart';

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
      await _removeUserFromClub(widget.clubId, user.uid);
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
      // Check if user was previously rejected (optional: prevent spam)
      final rejectedRequest = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('clubId', isEqualTo: widget.clubId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (rejectedRequest.docs.isNotEmpty) {
        final rejectedDoc = rejectedRequest.docs.first;
        final rejectedAt = rejectedDoc.data()['createdAt'] as Timestamp?;

        if (rejectedAt != null) {
          final daysSinceRejection =
              DateTime.now().difference(rejectedAt.toDate()).inDays;
          if (daysSinceRejection < 7) {
            // Prevent re-requesting for 7 days after rejection
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'You can request to join again after ${7 - daysSinceRejection} days.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
      }

      // Use transaction to ensure uniqueness
      final success = await _createUniqueRequest();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request sent! Waiting for approval.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('You already have a pending request for this club.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest() async {
    try {
      final existingRequest = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('clubId', isEqualTo: widget.clubId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('joinRequests')
            .doc(existingRequest.docs.first.id)
            .update({'status': 'cancelled'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Join request cancelled.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Show members list
  void _showMembersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubMembersPage(
          clubId: widget.clubId,
          clubData: widget.clubData,
        ),
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
    final bool isMember =
        (widget.clubData['members'] as List).contains(user.uid);
    final DateTime createdAt =
        (widget.clubData['createdAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat('MMMM d, y').format(createdAt);
    final List<String> tabs = isCreator && isPrivateClub
        ? ['Events', 'Posts', 'Requests']
        : ['Events', 'Posts'];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isMember
          ? FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: Icon(Icons.event, color: Colors.black),
                          title: Text('Create Event'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateEventPage(clubId: widget.clubId),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.post_add, color: Colors.black),
                          title: Text('Create Post'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreatePostPage(clubId: widget.clubId),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Icon(Icons.add, color: Colors.white),
              tooltip: 'Actions',
            )
          : null,
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
                    onPressed: () => Navigator.pop(context),                  ),
                  actions: [
                    if (isCreator)
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
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
                    if (!isCreator)
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
                    margin:
                        EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
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
                        // Club Title with privacy indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.clubData['name'] ?? 'Club Name',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPrivateClub
                                    ? Colors.red[100]
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPrivateClub
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    size: 18,
                                    color: isPrivateClub
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isPrivateClub ? 'Private' : 'Public',
                                    style: TextStyle(
                                      color: isPrivateClub
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: _showMembersList,
                                    child: _buildStatItem(
                                      icon: Icons.group,
                                      label: 'Members',
                                      value:
                                          (widget.clubData['members'] as List)
                                              .length
                                              .toString(),
                                      isClickable: true,
                                    ),
                                  ),
                                  _buildStatItem(
                                    icon: Icons.sports,
                                    label: 'Sport',
                                    value: widget.clubData['sport'] ?? 'N/A',
                                  ),
                                  _buildStatItem(
                                    icon: Icons.grade,
                                    label: 'Level',
                                    value:
                                        widget.clubData['skillLevel'] ?? 'N/A',
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
                                            style: TextStyle(
                                                color: Colors.grey[700])),
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Row(
                                      children: [
                                        Icon(Icons.person_outline,
                                            color: Colors.grey[700]),
                                        SizedBox(width: 8),
                                        Text('Error fetching creator',
                                            style: TextStyle(
                                                color: Colors.grey[700])),
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
                                          style: TextStyle(
                                              color: Colors.grey[700]),
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

                        // Join/Leave/Request Button (only one visible at a time)
                        if (!isCreator) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FutureBuilder<bool>(
                              future: hasPendingRequest,
                              builder: (context, snapshot) {
                                final isPending = snapshot.data ?? false;
                                if (isUserMember) {
                                  // Show leave button for members (not creator)
                                  return ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text('Leave Club'),
                                          content: Text(
                                              'Are you sure you want to leave this club?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _leaveClub();
                                              },
                                              child: Text('Leave',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Leave Club',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show join/request button for non-members
                                  return ElevatedButton(
                                    onPressed: isPending
                                        ? _cancelRequest // Allow cancelling pending requests
                                        : isPrivateClub
                                            ? _requestToJoin
                                            : () async {
                                                try {
                                                  await _addUserToClub(
                                                      widget.clubId, user.uid);
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Successfully joined the club!')),
                                                    );
                                                    Navigator.of(context).pop();
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error joining club: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPending
                                          ? Colors.orange[400]
                                          : Color(0xFFD7F520),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      isPending
                                          ? 'Cancel Request'
                                          : isPrivateClub
                                              ? 'Request to Join'
                                              : 'Join Club',
                                      style: TextStyle(
                                        color: isPending
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                        ],

                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFD7F520).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(25),                          ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Builder(
                      builder: (context) {
                        // Check if user can view content (public club or member of private club)
                        bool canViewContent = !isPrivateClub || isUserMember;
                        
                        if (_selectedTabIndex == 0) {
                          if (canViewContent) {
                            return _buildEventsTabWithImages(
                                widget.clubId, isCreator);
                          } else {
                            return _buildPrivateContentMessage('events');
                          }
                        } else if (_selectedTabIndex == 1) {
                          if (canViewContent) {
                            return _buildPostsTabWithImages(
                                widget.clubId, isCreator);
                          } else {
                            return _buildPrivateContentMessage('posts');
                          }
                        } else if (_selectedTabIndex == 2 && isCreator) {
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
            //decoration: isClickable ? TextDecoration.underline : null,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            //decoration: isClickable ? TextDecoration.underline : null,
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

  /*
   * IMPORTANT: To completely prevent duplicate requests at the database level,
   * create a composite index in Firestore console:
   * 
   * Collection: joinRequests
   * Fields: clubId (Ascending), userId (Ascending), status (Ascending)
   * 
   * You can also create a unique constraint by setting up Firestore security rules:
   * 
   * match /joinRequests/{requestId} {
   *   allow create: if !exists(/databases/$(database)/documents/joinRequests/$(request.auth.uid + '_' + resource.data.clubId))
   *     && request.auth != null 
   *     && request.auth.uid == resource.data.userId;
   * }
   */

  // Helper method to ensure unique requests using transactions
  Future<bool> _createUniqueRequest() async {
    try {
      final firestore = FirebaseFirestore.instance;

      return await firestore.runTransaction<bool>((transaction) async {
        // Check for existing pending request within transaction
        final existingRequestQuery = await firestore
            .collection('joinRequests')
            .where('clubId', isEqualTo: widget.clubId)
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .get();

        if (existingRequestQuery.docs.isNotEmpty) {
          return false; // Request already exists
        }

        // Create new request document reference
        final newRequestRef = firestore.collection('joinRequests').doc();

        // Add the new request within transaction
        transaction.set(newRequestRef, {
          'clubId': widget.clubId,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        return true; // Successfully created
      });
    } catch (e) {
      print('Error in transaction: $e');
      return false;
    }  }
  Widget _buildPostsTabWithImages(String clubId, bool isOwner) {
    print('Building posts for club: $clubId');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('club')
          .doc(clubId)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        print('Posts StreamBuilder - ConnectionState: ${snapshot.connectionState}');
        print('Posts StreamBuilder - HasError: ${snapshot.hasError}');
        print('Posts StreamBuilder - HasData: ${snapshot.hasData}');
        
        if (snapshot.hasData) {
          print('Posts count: ${snapshot.data!.docs.length}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Posts - Waiting for data...');
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading posts: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                Text('Error loading posts: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No posts found - showing empty state');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No posts yet'),
                SizedBox(height: 8),
                Text('Be the first to create a post!'),
              ],
            ),
          );
        }        print('Displaying ${snapshot.data!.docs.length} posts');
        return Column(
          children: snapshot.data!.docs.asMap().entries.map((entry) {
            final index = entry.key;
            final post = entry.value;
            final data = post.data() as Map<String, dynamic>;
            
            // Add the document ID to the data for navigation
            data['id'] = post.id;
            data['clubId'] = clubId;
            
            print('Post: ${data.keys.toList()}');
            print('  Title: ${data['title']}');
            print('  Content: ${data['content']}');
            return _buildPostCard(data, index);
          }).toList(),
        );
      },
    );
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

// Helper function to add user to club and update user's communityList
  Future<void> _addUserToClub(String clubId, String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      // Add user to club members
      final clubRef = FirebaseFirestore.instance.collection('club').doc(clubId);
      batch.update(clubRef, {
        'members': FieldValue.arrayUnion([userId])
      });

      // Add club to user's communityList
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      batch.update(userRef, {
        'communityList': FieldValue.arrayUnion([clubId])
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error adding user to club: $e');
      rethrow;
    }
  }

// Helper function to remove user from club and update user's communityList
  Future<void> _removeUserFromClub(String clubId, String userId) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      // Remove user from club members
      final clubRef = FirebaseFirestore.instance.collection('club').doc(clubId);
      batch.update(clubRef, {
        'members': FieldValue.arrayRemove([userId])
      });

      // Remove club from user's communityList
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      batch.update(userRef, {
        'communityList': FieldValue.arrayRemove([clubId])
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error removing user from club: $e');
      rethrow;
    }
  }

  Widget _buildRequestsTab(String clubId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('joinRequests')
          .where('clubId', isEqualTo: clubId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No pending requests'));
        }
        final requests = snapshot.data!.docs;
        return SingleChildScrollView(
          child: Column(
            children: List.generate(requests.length, (index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final requesterId = data['userId'] ?? '';
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(requesterId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Loading...'),
                      subtitle: Text('Requested at: ' +
                          (data['createdAt']?.toDate()?.toString() ?? '')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                        ],
                      ),
                    );
                  }                  String userName = 'Unknown User';

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    userName = userData?['name'] ??
                        userData?['displayName'] ??
                        'Unknown User';
                  }

                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: UserAvatar(
                        userData: userData,
                        radius: 20,
                        fallbackIcon: Icons.person_outline,
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Requested at: ${data['createdAt']?.toDate() != null ? DateFormat('MMM dd, yyyy HH:mm').format(data['createdAt'].toDate()) : 'Unknown'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.check,
                                  color: Colors.green, size: 20),
                              tooltip: 'Accept',
                              onPressed: () async {
                                try {
                                  await _addUserToClub(clubId, requesterId);
                                  await FirebaseFirestore.instance
                                      .collection('joinRequests')
                                      .doc(request.id)
                                      .update({
                                    'status': 'accepted',
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '$userName has been added to the club!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error accepting request: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.red, size: 20),
                              tooltip: 'Reject',
                              onPressed: () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('joinRequests')
                                      .doc(request.id)
                                      .update({
                                    'status': 'rejected',
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Request from $userName has been rejected.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error rejecting request: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data, int index) {
    final createdAt = data['createdAt'] as Timestamp?;
    final imageUrl = data['imageUrl'] as String?;
    final content = data['content'] as String? ?? '';
    final title = data['title'] as String?;
    final category = data['category'] as String?;
    final isImportant = data['isImportant'] as bool? ?? false;
    final likesCount = data['likesCount'] as int? ?? 0;
    final commentsCount = data['commentsCount'] as int? ?? 0;
    final tags = data['tags'] as List?;
    final clubId = data['clubId'] as String?;    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GestureDetector(
        onTap: () {
          // Navigate to post details page
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
            border: isImportant
                ? Border.all(color: Colors.amber, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with club info and timestamp
              _buildPostCardHeader(data, createdAt, clubId),
              
              // Category and importance badges
              if (category != null || isImportant)
                _buildPostBadgeRow(category, isImportant),
              
              // Title
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
                _buildPostCardImage(imageUrl),
              
              // Tags
              if (tags != null && tags.isNotEmpty)
                _buildPostTagsRow(tags),
                // Action buttons (likes, comments, share)
              _buildPostActionButtons(likesCount, commentsCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCardHeader(Map<String, dynamic> data, Timestamp? createdAt, String? clubId) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Club avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green[200],
            backgroundImage: widget.clubData['imageUrl'] != null 
                ? NetworkImage(widget.clubData['imageUrl']) 
                : null,
            child: widget.clubData['imageUrl'] == null
                ? Icon(Icons.sports_tennis, color: Colors.green[800], size: 20)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clubData['name'] ?? 'Unknown Club',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatPostDate(createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert,
            color: Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPostBadgeRow(String? category, bool isImportant) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (category != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFD7F520).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (category != null && isImportant) SizedBox(width: 8),
          if (isImportant)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.amber[800]),
                  SizedBox(width: 4),
                  Text(
                    'Important',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCardImage(String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPostTagsRow(List tags) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.take(3).map((tag) => Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPostActionButtons(int likesCount, int commentsCount) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildPostActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            count: likesCount,
            label: 'Like',
            onTap: () {
              // TODO: Implement like functionality
            },
          ),
          SizedBox(width: 16),
          _buildPostActionButton(
            icon: Icons.comment_outlined,
            activeIcon: Icons.comment,
            count: commentsCount,
            label: 'Comment',
            onTap: () {
              // TODO: Implement comment functionality
            },
          ),
          SizedBox(width: 16),
          _buildPostActionButton(
            icon: Icons.share_outlined,
            activeIcon: Icons.share,
            count: 0,
            label: 'Share',
            onTap: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFD7F520).withOpacity(0.2) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive ? Colors.black87 : Colors.grey[600],
            ),
            if (count > 0) SizedBox(width: 4),
            if (count > 0)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.black87 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatPostDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Widget _buildPrivateContentMessage(String contentType) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Private Club Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This club\'s $contentType are only visible to members.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          if (!isUserMember && isPrivateClub) ...[
            ElevatedButton.icon(
              onPressed: () async {
                // Check if user already has a pending request
                bool hasPending = await hasPendingRequest;
                if (hasPending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You already have a pending join request.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Send join request
                try {
                  await FirebaseFirestore.instance
                      .collection('joinRequests')
                      .add({
                    'clubId': widget.clubId,
                    'userId': user.uid,
                    'status': 'pending',
                    'createdAt': Timestamp.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Join request sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending join request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.group_add),
              label: Text('Request to Join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD7F520),
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}