import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/club_details_page.dart';

class BrowseClubsPage extends StatefulWidget {
  const BrowseClubsPage({Key? key}) : super(key: key);

  @override
  State<BrowseClubsPage> createState() => _BrowseClubsPageState();
}

class _BrowseClubsPageState extends State<BrowseClubsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String _searchQuery = '';  Stream<QuerySnapshot> getAvailableClubs() {
    // Get all clubs - we'll filter for non-membership in the StreamBuilder
    return FirebaseFirestore.instance
        .collection('club')
        .snapshots();
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
                        Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No club available',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      club['name'] ?? 'Club Name',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
      ),
    );
  }
}
