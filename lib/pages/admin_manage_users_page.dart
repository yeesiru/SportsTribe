import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../services/user_firestore_service.dart';

class AdminManageUsersPage extends StatefulWidget {
  const AdminManageUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserFirestoreService _userService = UserFirestoreService();
  
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedGender = 'All';
  String _selectedSortBy = 'name';
  bool _sortAscending = true;
  bool _isLoading = false;

  final List<String> _roleFilters = ['All', 'admin', 'member'];
  final List<String> _genderFilters = ['All', 'Male', 'Female', 'Prefer not to say'];
  final List<String> _sortOptions = ['name', 'email', 'createdAt'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = FirebaseFirestore.instance.collection('users');
    
    // Apply role filter
    if (_selectedRole != 'All') {
      query = query.where('role', isEqualTo: _selectedRole);
    }
    
    // Apply gender filter
    if (_selectedGender != 'All') {
      query = query.where('gender', isEqualTo: _selectedGender);
    }
    
    // Apply sorting
    query = query.orderBy(_selectedSortBy, descending: !_sortAscending);
    
    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      
      return name.contains(searchLower) || email.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Manage Users'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showCreateUserDialog,
            tooltip: 'Create User',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStatsSection(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
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
                // Role filter
                _buildFilterChip(
                  'Role: $_selectedRole',
                  () => _showRoleFilter(),
                ),
                SizedBox(width: 8),
                
                // Gender filter
                _buildFilterChip(
                  'Gender: $_selectedGender',
                  () => _showGenderFilter(),
                ),
                SizedBox(width: 8),
                
                // Sort filter
                _buildFilterChip(
                  'Sort: $_selectedSortBy ${_sortAscending ? '↑' : '↓'}',
                  () => _showSortFilter(),
                ),
                SizedBox(width: 8),
                
                // Clear filters
                if (_selectedRole != 'All' || _selectedGender != 'All' || _searchQuery.isNotEmpty)
                  _buildFilterChip(
                    'Clear All',
                    _clearFilters,
                    isAction: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, {bool isAction = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAction ? Colors.red[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAction ? Colors.red[200]! : Colors.blue[200]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isAction ? Colors.red[700] : Colors.blue[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final users = snapshot.data!.docs;
        final totalUsers = users.length;
        final adminUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == 'admin';
        }).length;
        final memberUsers = totalUsers - adminUsers;
        
        return Container(
          color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Users', totalUsers.toString(), Icons.people),
              ),
              Expanded(
                child: _buildStatItem('Admins', adminUsers.toString(), Icons.admin_panel_settings),
              ),
              Expanded(
                child: _buildStatItem('Members', memberUsers.toString(), Icons.person),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        SizedBox(height: 2),
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

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading users'),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
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
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No users found'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showCreateUserDialog,
                  child: Text('Create First User'),
                ),
              ],
            ),
          );
        }
        
        final filteredUsers = _filterUsers(snapshot.data!.docs);
        
        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No users match your search'),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Clear filters'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final doc = filteredUsers[index];
            final userData = doc.data() as Map<String, dynamic>;
            return _buildUserCard(doc.id, userData);
          },
        );
      },
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final user = AppUser.fromMap(userData);
    final isAdmin = user.role == 'admin';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: isAdmin ? Border.all(color: Colors.orange[200]!, width: 1) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with avatar and actions
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isAdmin ? Colors.orange[100] : Colors.blue[100],
                  backgroundImage: user.photoUrl.isNotEmpty 
                      ? NetworkImage(user.photoUrl) 
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: isAdmin ? Colors.orange[700] : Colors.blue[700],
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name.isNotEmpty ? user.name : 'No Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Action buttons - always in one row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.visibility, size: 18, color: Colors.blue),
                      onPressed: () => _showUserDetailsDialog(userId, user),
                      tooltip: 'View Details',
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: Colors.green),
                      onPressed: () => _showEditUserDialog(userId, user),
                      tooltip: 'Edit User',
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _showDeleteUserDialog(userId, user),
                      tooltip: 'Delete User',
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // User info row
            Row(
              children: [
                if (user.gender.isNotEmpty) ...[
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    user.gender,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                ],
                if (user.createdAt != null) ...[
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Joined ${DateFormat('MMM dd, yyyy').format(user.createdAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            
            if (user.sportsList.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Sports: ${user.sportsList.join(', ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (user.communityList.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                'Communities: ${user.communityList.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRoleFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _roleFilters.map((role) {
            return RadioListTile<String>(
              title: Text(role),
              value: role,
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showGenderFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _genderFilters.map((gender) {
            return RadioListTile<String>(
              title: Text(gender),
              value: gender,
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSortFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._sortOptions.map((option) {
              return RadioListTile<String>(
                title: Text(option.replaceFirst(option[0], option[0].toUpperCase())),
                value: option,
                groupValue: _selectedSortBy,
                onChanged: (value) {
                  setState(() {
                    _selectedSortBy = value!;
                  });
                },
              );
            }),
            Divider(),
            SwitchListTile(
              title: Text('Ascending Order'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedRole = 'All';
      _selectedGender = 'All';
      _selectedSortBy = 'name';
      _sortAscending = true;
    });
    _searchController.clear();
  }

  void _showUserDetailsDialog(String userId, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: user.role == 'admin' ? Colors.orange[100] : Colors.blue[100],
                        backgroundImage: user.photoUrl.isNotEmpty 
                            ? NetworkImage(user.photoUrl) 
                            : null,
                        child: user.photoUrl.isEmpty
                            ? Icon(
                                user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                color: user.role == 'admin' ? Colors.orange[700] : Colors.blue[700],
                                size: 30,
                              )
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty ? user.name : 'No Name',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (user.role == 'admin')
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  _buildDetailRow('User ID', userId),
                  _buildDetailRow('Birth Date', user.birthDate.isNotEmpty ? user.birthDate : 'Not set'),
                  _buildDetailRow('Gender', user.gender.isNotEmpty ? user.gender : 'Not set'),
                  _buildDetailRow('Role', user.role),
                  if (user.createdAt != null)
                    _buildDetailRow('Created At', DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt!)),
                  
                  if (user.sportsList.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Sports',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: user.sportsList.map((sport) => Chip(
                        label: Text(sport),
                        backgroundColor: Colors.blue[50],
                      )).toList(),
                    ),
                  ],
                  
                  if (user.communityList.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Communities (${user.communityList.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Member of ${user.communityList.length} communities',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditUserDialog(userId, user);
                        },
                        child: Text('Edit User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(String userId, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final birthDateController = TextEditingController(text: user.birthDate);
    String selectedGender = user.gender;
    String selectedRole = user.role;
    List<String> selectedSports = List.from(user.sportsList);

    final availableSports = ['Badminton', 'Basketball', 'Tennis', 'Pickleball'];
    final genderOptions = ['Male', 'Female', 'Prefer not to say'];
    final roleOptions = ['member', 'admin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit User',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 24),
                    
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: birthDateController,
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedGender.isEmpty ? null : selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: genderOptions.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGender = value ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: roleOptions.map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value ?? 'member';
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    Text('Sports:', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: availableSports.map((sport) {
                        final isSelected = selectedSports.contains(sport);
                        return FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedSports.add(sport);
                              } else {
                                selectedSports.remove(sport);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _updateUser(
                            userId,
                            nameController.text,
                            emailController.text,
                            birthDateController.text,
                            selectedGender,
                            selectedRole,
                            selectedSports,
                            context,
                          ),
                          child: _isLoading 
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteUserDialog(String userId, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this user?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.red[100],
                    child: Icon(Icons.person, color: Colors.red[700]),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : 'No Name',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone. The user will be permanently removed from the system.',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _deleteUser(userId, context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: _isLoading 
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Delete User', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final birthDateController = TextEditingController();
    String selectedGender = '';
    String selectedRole = 'member';
    List<String> selectedSports = [];

    final availableSports = ['Badminton', 'Basketball', 'Tennis', 'Pickleball'];
    final genderOptions = ['Male', 'Female', 'Prefer not to say'];
    final roleOptions = ['member', 'admin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create New User',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 24),
                    
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: birthDateController,
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedGender.isEmpty ? null : selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: genderOptions.map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGender = value ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: roleOptions.map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value ?? 'member';
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    Text('Sports:', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: availableSports.map((sport) {
                        final isSelected = selectedSports.contains(sport);
                        return FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedSports.add(sport);
                              } else {
                                selectedSports.remove(sport);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _createUser(
                            nameController.text,
                            emailController.text,
                            passwordController.text,
                            birthDateController.text,
                            selectedGender,
                            selectedRole,
                            selectedSports,
                            context,
                          ),
                          child: _isLoading 
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text('Create User'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateUser(
    String userId,
    String name,
    String email,
    String birthDate,
    String gender,
    String role,
    List<String> sports,
    BuildContext context,
  ) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name and email are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'name': name.trim(),
        'email': email.trim(),
        'birthDate': birthDate,
        'gender': gender,
        'role': role,
        'sportsList': sports,
      };

      await _userService.editProfile(userId, updateData);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId, BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      await _userService.deleteAccount(userId);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUser(
    String name,
    String email,
    String password,
    String birthDate,
    String gender,
    String role,
    List<String> sports,
    BuildContext context,
  ) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name, email, and password are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Create AppUser object
        final appUser = AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          birthDate: birthDate,
          gender: gender,
          photoUrl: '',
          sportsList: sports,
          communityList: [],
          eventList: [],
          role: role,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _userService.addUserWithProfile(appUser);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
