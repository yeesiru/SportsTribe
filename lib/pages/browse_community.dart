import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/club_details_page.dart';

class BrowseCommunityPage extends StatefulWidget {
  @override
  State<BrowseCommunityPage> createState() => _BrowseCommunityPageState();
}

class _BrowseCommunityPageState extends State<BrowseCommunityPage> {
  String searchQuery = '';
  String? selectedLocation;
  String? selectedSport;
  String? selectedSkill;

  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Browse Community', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search clubs...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Sports', selectedSport == null, () {
                    setState(() => selectedSport = null);
                  }),
                  _buildFilterChip('Badminton', selectedSport == 'Badminton',
                      () {
                    setState(() => selectedSport = 'Badminton');
                  }),
                  _buildFilterChip('Tennis', selectedSport == 'Tennis', () {
                    setState(() => selectedSport = 'Tennis');
                  }),
                  _buildFilterChip('Basketball', selectedSport == 'Basketball',
                      () {
                    setState(() => selectedSport = 'Basketball');
                  }),
                  _buildFilterChip('Pickleball', selectedSport == 'Pickleball',
                      () {
                    setState(() => selectedSport = 'Pickleball');
                  }),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Clubs list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredClubsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No clubs found'));
                  }

                  final filteredClubs = snapshot.data!.docs.where((doc) {
                    final club = doc.data() as Map<String, dynamic>;
                    final clubName =
                        (club['name'] ?? '').toString().toLowerCase();
                    return clubName.contains(searchQuery.toLowerCase());
                  }).toList();

                  if (filteredClubs.isEmpty) {
                    return Center(child: Text('No clubs found'));
                  }

                  return ListView.builder(
                    itemCount: filteredClubs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredClubs[index];
                      final club = doc.data() as Map<String, dynamic>;
                      final members = club['members'] as List? ?? [];
                      final isJoined = members.contains(user.uid);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: club['imageUrl'] != null
                                ? NetworkImage(club['imageUrl'])
                                : null,
                            child: club['imageUrl'] == null
                                ? Icon(Icons.sports_tennis)
                                : null,
                          ),
                          title: Text(club['name'] ?? 'Unknown Club'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${club['sport']} • ${club['skillLevel']}'),
                              Text('${members.length} members'),
                            ],
                          ),
                          trailing: isJoined
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Joined',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _joinClub(doc.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Join',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.black,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredClubsStream() {
    Query query = FirebaseFirestore.instance
        .collection('club')
        .where('isPrivate', isEqualTo: false);

    if (selectedSport != null) {
      query = query.where('sport', isEqualTo: selectedSport);
    }

    return query.snapshots();
  }

  Future<void> _joinClub(String clubId) async {
    try {
      await FirebaseFirestore.instance.collection('club').doc(clubId).update({
        'members': FieldValue.arrayUnion([user.uid])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined the club!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining club: $e')),
      );
    }
  }
}
