import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminManageClubsPage extends StatefulWidget {
  const AdminManageClubsPage({Key? key}) : super(key: key);

  @override
  State<AdminManageClubsPage> createState() => _AdminManageClubsPageState();
}

class _AdminManageClubsPageState extends State<AdminManageClubsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Public', 'Private'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilter(),
          
          // Clubs List
          Expanded(
            child: _buildClubsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search clubs...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          SizedBox(height: 12),
            // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Color(0xFFD4FF3D),
                    checkmarkColor: Colors.black,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('club')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error loading clubs: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
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
                Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No clubs found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text('Create the first club to get started!'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showCreateClubDialog(),
                  child: Text('Create Club'),
                ),
              ],
            ),
          );
        }

        // Filter clubs based on search and filter
        var filteredClubs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          
          // Search filter
          bool matchesSearch = _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              description.contains(_searchQuery);
          
          // Category filter
          bool matchesFilter = true;
          switch (_selectedFilter) {
            case 'Public':
              matchesFilter = !(data['isPrivate'] ?? false);
              break;
            case 'Private':
              matchesFilter = data['isPrivate'] ?? false;
              break;
            case 'Active':
              // Consider a club active if it has recent activity or members
              matchesFilter = (data['members'] as List?)?.isNotEmpty ?? false;
              break;
            case 'Inactive':
              matchesFilter = (data['members'] as List?)?.isEmpty ?? true;
              break;
          }
          
          return matchesSearch && matchesFilter;
        }).toList();

        if (filteredClubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No clubs match your search',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text('Try adjusting your search or filters'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredClubs.length,
          itemBuilder: (context, index) {
            final doc = filteredClubs[index];
            final clubData = doc.data() as Map<String, dynamic>;
            final clubId = doc.id;
            
            return _buildClubCard(clubId, clubData);
          },
        );
      },
    );
  }

  Widget _buildClubCard(String clubId, Map<String, dynamic> clubData) {
    final name = clubData['name'] ?? 'Unnamed Club';
    final description = clubData['description'] ?? 'No description';
    final sport = clubData['sport'] ?? 'Unknown';
    final isPrivate = clubData['isPrivate'] ?? false;
    final members = clubData['members'] as List? ?? [];
    final createdAt = clubData['createdAt'] as Timestamp?;
    final imageUrl = clubData['imageUrl'] as String?;
    
    String formattedDate = 'Unknown';
    if (createdAt != null) {
      formattedDate = DateFormat('MMM d, y').format(createdAt.toDate());
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Club Image/Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.grey[200],
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.groups, color: Colors.grey[600]);
                            },
                          ),
                        )
                      : Icon(Icons.groups, color: Colors.grey[600]),
                ),
                SizedBox(width: 12),
                
                // Club Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPrivate ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPrivate ? Icons.lock : Icons.public,
                                  size: 12,
                                  color: isPrivate ? Colors.red : Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isPrivate ? 'Private' : 'Public',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPrivate ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
              // Club Stats
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatChip(Icons.sports, sport, Colors.blue),
                _buildStatChip(Icons.group, '${members.length} members', Colors.orange),
                _buildStatChip(Icons.calendar_today, formattedDate, Colors.purple),
              ],
            ),
            
            SizedBox(height: 12),            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View', overflow: TextOverflow.ellipsis),
                    onPressed: () => _viewClubDetails(clubId, clubData),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit', overflow: TextOverflow.ellipsis),
                    onPressed: () => _editClub(clubId, clubData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4FF3D),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteClub(clubId, name),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _viewClubDetails(String clubId, Map<String, dynamic> clubData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(clubData['name'] ?? 'Club Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', clubData['description'] ?? 'No description'),
              _buildDetailRow('Sport', clubData['sport'] ?? 'Unknown'),
              _buildDetailRow('Skill Level', clubData['skillLevel'] ?? 'Unknown'),
              _buildDetailRow('Privacy', (clubData['isPrivate'] ?? false) ? 'Private' : 'Public'),
              _buildDetailRow('Members', '${(clubData['members'] as List?)?.length ?? 0}'),
              _buildDetailRow('Location', clubData['location'] ?? 'Not specified'),
              if (clubData['createdAt'] != null)
                _buildDetailRow('Created', 
                  DateFormat('MMM d, y \'at\' h:mm a').format((clubData['createdAt'] as Timestamp).toDate())),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  void _editClub(String clubId, Map<String, dynamic> clubData) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController(text: clubData['name'] ?? '');
    final TextEditingController _descriptionController = TextEditingController(text: clubData['description'] ?? '');
    final TextEditingController _locationController = TextEditingController(text: clubData['location'] ?? '');
    String _selectedSport = clubData['sport'] ?? 'Badminton';
    String _selectedSkillLevel = clubData['skillLevel'] ?? 'Beginner';
    bool _isPrivate = clubData['isPrivate'] ?? false;

    final List<String> _sports = [
      'Badminton', 'Basketball', 'Tennis', 'Pickleball' 
    ];
    
    final List<String> _skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Mixed'];    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Club'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Club Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Club name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSport,
                    decoration: InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(),
                    ),
                    items: _sports.map((sport) => DropdownMenuItem(
                      value: sport,
                      child: Text(sport),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) _selectedSport = value;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSkillLevel,
                    decoration: InputDecoration(
                      labelText: 'Skill Level',
                      border: OutlineInputBorder(),
                    ),
                    items: _skillLevels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) _selectedSkillLevel = value;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  StatefulBuilder(
                    builder: (context, setState) => SwitchListTile(
                      title: Text('Private Club'),
                      subtitle: Text('Only members can see club content'),
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _updateClub(
                  clubId: clubId,
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  sport: _selectedSport,
                  skillLevel: _selectedSkillLevel,
                  location: _locationController.text.trim(),
                  isPrivate: _isPrivate,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD4FF3D),
              foregroundColor: Colors.black,
            ),
            child: Text('Update Club'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateClub({
    required String clubId,
    required String name,
    required String description,
    required String sport,
    required String skillLevel,
    required String location,
    required bool isPrivate,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating club...'),
            ],
          ),
        ),
      );

      // Update club document
      final updateData = {
        'name': name,
        'description': description,
        'sport': sport,
        'skillLevel': skillLevel,
        'location': location.isNotEmpty ? location : null,
        'isPrivate': isPrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('club')
          .doc(clubId)
          .update(updateData);

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Club "$name" updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating club: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteClub(String clubId, String clubName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Club'),
        content: Text('Are you sure you want to delete "$clubName"?\n\nThis action cannot be undone and will remove all club data, events, and posts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteClub(clubId, clubName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<void> _performDeleteClub(String clubId, String clubName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Deleting club and related data...')),
            ],
          ),
        ),
      );

      // Use a batch to ensure all operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();

      // Delete the club document
      final clubRef = FirebaseFirestore.instance.collection('club').doc(clubId);
      batch.delete(clubRef);

      // Find and delete related events
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('clubId', isEqualTo: clubId)
          .get();
      
      for (var eventDoc in eventsQuery.docs) {
        batch.delete(eventDoc.reference);
      }

      // Find and delete related posts (if they exist)
      try {
        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('clubId', isEqualTo: clubId)
            .get();
        
        for (var postDoc in postsQuery.docs) {
          batch.delete(postDoc.reference);
        }
      } catch (e) {
        // Posts collection might not exist or have different structure
        print('Note: Could not delete posts for club $clubId: $e');
      }

      // Find and delete join requests (if they exist)
      try {
        final requestsQuery = await FirebaseFirestore.instance
            .collection('join_requests')
            .where('clubId', isEqualTo: clubId)
            .get();
        
        for (var requestDoc in requestsQuery.docs) {
          batch.delete(requestDoc.reference);
        }
      } catch (e) {
        // Join requests might not exist
        print('Note: Could not delete join requests for club $clubId: $e');
      }

      // Commit the batch
      await batch.commit();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Club "$clubName" and all related data deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting club: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
  void _showCreateClubDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    final TextEditingController _locationController = TextEditingController();
    String _selectedSport = 'Badminton';
    String _selectedSkillLevel = 'Beginner';
    bool _isPrivate = false;

    final List<String> _sports = [
      'Badminton', 'Basketball', 'Tennis', 'Pickleball'
    ];
    
    final List<String> _skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Mixed'];    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Club'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Club Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Club name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSport,
                    decoration: InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(),
                    ),
                    items: _sports.map((sport) => DropdownMenuItem(
                      value: sport,
                      child: Text(sport),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) _selectedSport = value;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSkillLevel,
                    decoration: InputDecoration(
                      labelText: 'Skill Level',
                      border: OutlineInputBorder(),
                    ),
                    items: _skillLevels.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) _selectedSkillLevel = value;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: Text('Private Club'),
                    subtitle: Text('Only members can see club content'),
                    value: _isPrivate,
                    onChanged: (value) {
                      _isPrivate = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createClub(
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  sport: _selectedSport,
                  skillLevel: _selectedSkillLevel,
                  location: _locationController.text.trim(),
                  isPrivate: _isPrivate,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD4FF3D),
              foregroundColor: Colors.black,
            ),
            child: Text('Create Club'),
          ),
        ],
      ),
    );
  }

  Future<void> _createClub({
    required String name,
    required String description,
    required String sport,
    required String skillLevel,
    required String location,
    required bool isPrivate,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating club...'),
            ],
          ),
        ),
      );

      // Get current user (admin)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create club document
      final clubData = {
        'name': name,
        'description': description,
        'sport': sport,
        'skillLevel': skillLevel,
        'location': location.isNotEmpty ? location : null,
        'isPrivate': isPrivate,
        'ownerId': user.uid,
        'members': [user.uid], // Admin is automatically a member
        'admins': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('club')
          .add(clubData);

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Club "$name" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating club: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
