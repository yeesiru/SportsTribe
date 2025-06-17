import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrowseCommunityPage extends StatefulWidget {
  @override
  State<BrowseCommunityPage> createState() => _BrowseCommunityPageState();
}

class _BrowseCommunityPageState extends State<BrowseCommunityPage> {
  String searchQuery = '';
  String? selectedLocation;
  String? selectedSport;
  String? selectedSkill;

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
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            SizedBox(height: 12),
            // Filters
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Johor', 'Kuala Lumpur', 'Penang']
                      .map((loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(loc),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedLocation = val),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  decoration: InputDecoration(
                    labelText: 'Sport',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Badminton', 'Football', 'Tennis']
                      .map((sport) => DropdownMenuItem(
                            value: sport,
                            child: Text(sport),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSport = val),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSkill,
                  decoration: InputDecoration(
                    labelText: 'Skill',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Beginner', 'Intermediate', 'Advanced']
                      .map((skill) => DropdownMenuItem(
                            value: skill,
                            child: Text(skill),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSkill = val),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Community list from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('club').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No communities found.'));
                  }
                  // Filter Firestore data
                  final filtered = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesName = searchQuery.isEmpty ||
                        (data['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase());
                    final matchesLocation = selectedLocation == null ||
                        data['location'] == selectedLocation;
                    final matchesSport =
                        selectedSport == null || data['sport'] == selectedSport;
                    final matchesSkill = selectedSkill == null ||
                        data['skillLevel'] == selectedSkill;
                    return matchesName &&
                        matchesLocation &&
                        matchesSport &&
                        matchesSkill;
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text('No communities found.'));
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final doc = filtered[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[200],
                            backgroundImage: data['imageUrl'] != null &&
                                    data['imageUrl'] != ''
                                ? NetworkImage(data['imageUrl'])
                                : null,
                            child: (data['imageUrl'] == null ||
                                    data['imageUrl'] == '')
                                ? Icon(Icons.sports_tennis,
                                    color: Colors.green[800])
                                : null,
                          ),
                          title: Text(data['name'] ?? ''),
                          subtitle: Text(
                              '${data['location']} • ${data['sport']} • ${data['skillLevel']}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              // TODO: Implement join logic (add user to members array)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Joined ${data['name']}!')),
                              );
                            },
                            child: Text('Join',
                                style: TextStyle(color: Colors.white)),
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
      ),
    );
  }
}
