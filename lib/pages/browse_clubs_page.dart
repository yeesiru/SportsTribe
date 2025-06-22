import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/club_details_page.dart';

class BrowseClubsPage extends StatefulWidget {
  const BrowseClubsPage({Key? key}) : super(key: key);

  @override
  State<BrowseClubsPage> createState() => _BrowseClubsPageState();
}

// Add state for loading and requested clubs
class _BrowseClubsPageState extends State<BrowseClubsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String _searchQuery = '';
  String? _selectedSport;
  String? _selectedSkillLevel;
  Set<String> _loadingClubIds = {};
  Set<String> _requestedClubIds = {};
  bool _isInitializing = true;
  String? _errorMessage;

  final List<String> _sports = [
    'All',
    'Basketball',
    'Tennis',
    'Badminton',
    'Pickleball'
  ];
  final List<String> _skillLevels = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
    'All skills level'
  ];

  Stream<QuerySnapshot> getAvailableClubs() {
    // Get all clubs - we'll filter for non-membership in the StreamBuilder
    return FirebaseFirestore.instance.collection('club').snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  // Load existing pending requests to update the UI state
  Future<void> _loadPendingRequests() async {
    if (!mounted) return;

    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      final pendingRequests = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _requestedClubIds = pendingRequests.docs
              .map((doc) => doc.data()['clubId'] as String)
              .toSet();
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error loading pending requests: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load requests: $e';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Browse Club'),
        backgroundColor: Color(0xFFD7F520),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isInitializing) Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (!_isInitializing && _errorMessage == null) ...[
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search club...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Filter dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSport ?? 'All',
                      items: _sports.map((sport) {
                        return DropdownMenuItem<String>(
                          value: sport,
                          child: Text(sport),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSport = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSkillLevel ?? 'All',
                      items: _skillLevels.map((level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSkillLevel = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Clubs list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getAvailableClubs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No club available',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final clubs = snapshot.data!.docs.where((doc) {
                    final club = doc.data() as Map<String, dynamic>;
                    // First check if user is NOT a member of this club
                    final members = (club['members'] as List?) ?? [];
                    if (members.contains(user.uid)) {
                      return false;
                    }
                    // Filter by sport
                    if (_selectedSport != null && _selectedSport != 'All') {
                      if ((club['sport'] ?? '').toString() != _selectedSport) {
                        return false;
                      }
                    }
                    // Filter by skill level
                    if (_selectedSkillLevel != null &&
                        _selectedSkillLevel != 'All') {
                      if ((club['skillLevel'] ?? '').toString() !=
                          _selectedSkillLevel) {
                        return false;
                      }
                    }
                    // Then apply search filter if there is one
                    if (_searchQuery.isEmpty) {
                      return true;
                    }

                    final name = club['name']?.toString().toLowerCase() ?? '';
                    final sport = club['sport']?.toString().toLowerCase() ?? '';
                    final search = _searchQuery.toLowerCase();
                    return name.contains(search) || sport.contains(search);
                  }).toList();

                  if (clubs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'You\'ve joined all available clubs!'
                                : 'No clubs match your search',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: clubs.length,
                    itemBuilder: (context, index) {
                      final club = clubs[index].data() as Map<String, dynamic>;
                      final clubId = clubs[index].id;

                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClubDetailsPage(
                                  clubId: clubId,
                                  clubData: club,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Club image
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Color(0xFFD7F520),
                                  backgroundImage: club['imageUrl'] != null
                                      ? NetworkImage(club['imageUrl'])
                                      : null,
                                  child: club['imageUrl'] == null
                                      ? Icon(Icons.sports_tennis,
                                          color: Colors.black87)
                                      : null,
                                ),
                                SizedBox(width: 16),
                                // Club info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              club['name'] ?? 'Club Name',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  (club['isPrivate'] ?? false)
                                                      ? Colors.red[100]
                                                      : Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  (club['isPrivate'] ?? false)
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 15,
                                                  color: (club['isPrivate'] ??
                                                          false)
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  (club['isPrivate'] ?? false)
                                                      ? 'Private'
                                                      : 'Public',
                                                  style: TextStyle(
                                                    color: (club['isPrivate'] ??
                                                            false)
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${club['sport']} · ${club['skillLevel']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        club['location'] ?? 'No location',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton(
                                          onPressed: _loadingClubIds
                                                  .contains(clubId)
                                              ? null
                                              : _requestedClubIds
                                                      .contains(clubId)
                                                  ? () async {
                                                      // Cancel existing request
                                                      setState(() {
                                                        _loadingClubIds
                                                            .add(clubId);
                                                      });
                                                      await _cancelRequest(
                                                          clubId);
                                                      if (mounted) {
                                                        setState(() {
                                                          _loadingClubIds
                                                              .remove(clubId);
                                                        });
                                                      }
                                                    }
                                                  : () async {
                                                      setState(() {
                                                        _loadingClubIds
                                                            .add(clubId);
                                                      });
                                                      try {
                                                        if (club['isPrivate'] ??
                                                            false) {
                                                          // Use enhanced request method
                                                          await _requestToJoinClub(
                                                              clubId);
                                                        } else {
                                                          // Direct join for public clubs
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'club')
                                                              .doc(clubId)
                                                              .update({
                                                            'members': FieldValue
                                                                .arrayUnion(
                                                                    [user.uid])
                                                          });
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Successfully joined the club!'),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Error: $e'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() {
                                                            _loadingClubIds
                                                                .remove(clubId);
                                                          });
                                                        }
                                                      }
                                                    },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _requestedClubIds
                                                    .contains(clubId)
                                                ? Colors.orange[400]
                                                : (club['isPrivate'] ?? false)
                                                    ? Color(0xFFD7F520)
                                                    : Color(0xFFD7F520),
                                            foregroundColor: _requestedClubIds
                                                    .contains(clubId)
                                                ? Colors.white
                                                : Colors.black,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _loadingClubIds
                                                  .contains(clubId)
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.black,
                                                  ))
                                              : Text(_requestedClubIds
                                                      .contains(clubId)
                                                  ? 'Cancel Request'
                                                  : (club['isPrivate'] ?? false)
                                                      ? 'Request'
                                                      : 'Join'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow icon
                                Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to ensure unique requests using transactions
  Future<bool> _createUniqueRequest(String clubId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      return await firestore.runTransaction<bool>((transaction) async {
        // Check for existing pending request within transaction
        final existingRequestQuery = await firestore
            .collection('joinRequests')
            .where('clubId', isEqualTo: clubId)
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
          'clubId': clubId,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        return true; // Successfully created
      });
    } catch (e) {
      print('Error in transaction: $e');
      return false;
    }
  }

  // Enhanced request to join method with comprehensive checks
  Future<void> _requestToJoinClub(String clubId) async {
    try {
      // Check if user was previously rejected (optional: prevent spam)
      final rejectedRequest = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('clubId', isEqualTo: clubId)
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
      final success = await _createUniqueRequest(clubId);

      if (mounted) {
        if (success) {
          setState(() {
            _requestedClubIds.add(clubId);
          });
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

  // Method to cancel a pending request
  Future<void> _cancelRequest(String clubId) async {
    try {
      final existingRequest = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('clubId', isEqualTo: clubId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('joinRequests')
            .doc(existingRequest.docs.first.id)
            .update({'status': 'cancelled'});

        if (mounted) {
          setState(() {
            _requestedClubIds.remove(clubId);
          });
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
}
