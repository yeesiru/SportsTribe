import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/browse_clubs_page.dart';
import 'package:map_project/pages/club_details_page.dart';

class MyClubsPage extends StatefulWidget {
  const MyClubsPage({Key? key}) : super(key: key);

  @override
  State<MyClubsPage> createState() => _MyClubsPageState();
}

class _MyClubsPageState extends State<MyClubsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String _searchQuery = '';

  Stream<QuerySnapshot> getUserJoinedClubs() {
    return FirebaseFirestore.instance
        .collection('club')
        .where('members', arrayContains: user.uid)
        .snapshots();
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFFD7F520), size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFD7F520),
        elevation: 0,
        title: Text(
          'My Clubs',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search your clubs...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          
          // Statistics section
          StreamBuilder<QuerySnapshot>(
            stream: getUserJoinedClubs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox.shrink();
              
              final clubs = snapshot.data!.docs;
              final totalClubs = clubs.length;
              final createdByUser = clubs.where((doc) {
                final club = doc.data() as Map<String, dynamic>;
                return club['creatorId'] == user.uid;
              }).length;
              final joinedClubs = totalClubs - createdByUser;
              
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Clubs', totalClubs.toString(), Icons.groups),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatItem('Created', createdByUser.toString(), Icons.create),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatItem('Joined', joinedClubs.toString(), Icons.group_add),
                  ],
                ),
              );
            },
          ),
          
          // Clubs list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUserJoinedClubs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD7F520),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading clubs',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Clubs Joined Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Join some clubs to see them here!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD7F520),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Browse Clubs',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter clubs based on search query
                final clubs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  
                  final club = doc.data() as Map<String, dynamic>;
                  final name = club['name']?.toString().toLowerCase() ?? '';
                  final sport = club['sport']?.toString().toLowerCase() ?? '';
                  final description = club['description']?.toString().toLowerCase() ?? '';
                  final search = _searchQuery.toLowerCase();
                  
                  return name.contains(search) || 
                         sport.contains(search) || 
                         description.contains(search);
                }).toList();

                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No clubs found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final doc = clubs[index];
                    final club = doc.data() as Map<String, dynamic>;
                    final members = (club['members'] as List?) ?? [];
                    final isCreator = club['creatorId'] == user.uid;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
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
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: isCreator ? Color(0xFFD7F520) : Colors.green[200],
                          backgroundImage: club['imageUrl'] != null
                              ? NetworkImage(club['imageUrl'])
                              : null,
                          child: club['imageUrl'] == null
                              ? Icon(
                                  Icons.sports_tennis,
                                  color: isCreator ? Colors.black : Colors.green[800],
                                  size: 28,
                                )
                              : null,
                        ),
                        title: Row(
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
                            if (isCreator)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFD7F520),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'CREATOR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (club['isPrivate'] ?? false) 
                                    ? Colors.red[100] 
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (club['isPrivate'] ?? false) 
                                        ? Icons.lock 
                                        : Icons.lock_open,
                                    size: 12,
                                    color: (club['isPrivate'] ?? false) 
                                        ? Colors.red 
                                        : Colors.green,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    (club['isPrivate'] ?? false) ? 'Private' : 'Public',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (club['isPrivate'] ?? false) 
                                          ? Colors.red 
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.sports, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  '${club['sport'] ?? 'Sport'} • ${club['skillLevel'] ?? 'All Levels'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  '${members.length} member${members.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (club['description'] != null && club['description'].toString().isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                club['description'],
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrowseClubsPage()
                            ),
                          ); // Go back to home page where user can tap "Join Community"
        },
        backgroundColor: Color(0xFFD7F520),
        foregroundColor: Colors.black,
        icon: Icon(Icons.group_add),
        label: Text(
          'Join More Clubs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
