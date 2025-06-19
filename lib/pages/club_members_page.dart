import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/widgets/user_avatar.dart';

class ClubMembersPage extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic> clubData;

  const ClubMembersPage({
    Key? key,
    required this.clubId,
    required this.clubData,
  }) : super(key: key);

  @override
  State<ClubMembersPage> createState() => _ClubMembersPageState();
}

class _ClubMembersPageState extends State<ClubMembersPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;

  bool get isCreator => widget.clubData['creatorId'] == user.uid;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final memberIds = widget.clubData['members'] as List? ?? [];
      
      List<Map<String, dynamic>> membersList = [];
      
      for (String memberId in memberIds) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        
        if (doc.exists) {
          membersList.add({
            'id': memberId,
            'name': doc.data()?['name'] ?? 'Unknown',
            'photoUrl': doc.data()?['photoUrl'],
            'email': doc.data()?['email'] ?? '',
          });
        }
      }
      
      setState(() {
        members = membersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading members: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    // Prevent creator from removing themselves
    if (memberId == widget.clubData['creatorId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove the club creator'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName from the club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove member from club
        await FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .update({
          'members': FieldValue.arrayRemove([memberId])
        });

        // Update local state
        setState(() {
          members.removeWhere((member) => member['id'] == memberId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$memberName has been removed from the club'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMemberDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the email address of the user you want to add:'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addMemberByEmail(emailController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD7F520),
              foregroundColor: Colors.black87,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMemberByEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    try {
      // Find user by email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user found with this email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = userQuery.docs.first;
      final userId = userData.id;

      // Check if user is already a member
      if (members.any((member) => member['id'] == userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User is already a member of this club'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add user to club
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Add to local state
      setState(() {
        members.add({
          'id': userId,
          'name': userData.data()['name'] ?? 'Unknown',
          'photoUrl': userData.data()['photoUrl'],
          'email': userData.data()['email'] ?? '',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Member added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD7F520),
      appBar: AppBar(
        backgroundColor: Color(0xFFD7F520),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Club members',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black, size: 28),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : members.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No members yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.only(top: 20, bottom: 120),
                          itemCount: members.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 80,
                            endIndent: 20,
                            color: Colors.grey[200],
                          ),                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isMemberCreator = member['id'] == widget.clubData['creatorId'];
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [                                  UserAvatar(
                                    userData: member,
                                    radius: 25,
                                    fallbackIcon: Icons.person,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              member['name'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (isMemberCreator) ...[
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFD7F520),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Creator',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (member['email'].isNotEmpty)
                                          Text(
                                            member['email'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isCreator && !isMemberCreator)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _removeMember(member['id'], member['name']),
                                        child: Text(
                                          'Remove',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
          if (isCreator)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showAddMemberDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Add member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
