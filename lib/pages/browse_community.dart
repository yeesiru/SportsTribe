import 'package:flutter/material.dart';

class BrowseCommunityPage extends StatefulWidget {
  @override
  State<BrowseCommunityPage> createState() => _BrowseCommunityPageState();
}

class _BrowseCommunityPageState extends State<BrowseCommunityPage> {
  String searchQuery = '';
  String? selectedLocation;
  String? selectedSport;
  String? selectedSkill;

  // Dummy data for demonstration
  final List<Map<String, String>> communities = [
    {
      'name': 'Badminton Squad',
      'location': 'Johor',
      'sport': 'Badminton',
      'skill': 'Intermediate',
      'imageUrl': '',
    },
    {
      'name': 'Football United',
      'location': 'Kuala Lumpur',
      'sport': 'Football',
      'skill': 'Beginner',
      'imageUrl': '',
    },
    {
      'name': 'Tennis Champs',
      'location': 'Penang',
      'sport': 'Tennis',
      'skill': 'Advanced',
      'imageUrl': '',
    },
  ];

  List<Map<String, String>> get filteredCommunities {
    return communities.where((c) {
      final matchesName = searchQuery.isEmpty ||
          c['name']!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesLocation =
          selectedLocation == null || c['location'] == selectedLocation;
      final matchesSport = selectedSport == null || c['sport'] == selectedSport;
      final matchesSkill = selectedSkill == null || c['skill'] == selectedSkill;
      return matchesName && matchesLocation && matchesSport && matchesSkill;
    }).toList();
  }

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
            // Community list
            Expanded(
              child: filteredCommunities.isEmpty
                  ? Center(child: Text('No communities found.'))
                  : ListView.builder(
                      itemCount: filteredCommunities.length,
                      itemBuilder: (context, idx) {
                        final c = filteredCommunities[idx];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[200],
                              child: Icon(Icons.sports_tennis,
                                  color: Colors.green[800]),
                            ),
                            title: Text(c['name'] ?? ''),
                            subtitle: Text(
                                '${c['location']} • ${c['sport']} • ${c['skill']}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                // TODO: Implement join logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Joined ${c['name']}!')),
                                );
                              },
                              child: Text('Join',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
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
