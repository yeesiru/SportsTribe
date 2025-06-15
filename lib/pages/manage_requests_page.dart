import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageRequestsPage extends StatelessWidget {
  final String clubId;
  final Map<String, dynamic> clubData;

  const ManageRequestsPage({
    Key? key,
    required this.clubId,
    required this.clubData,
  }) : super(key: key);

  Future<void> _handleRequest(String requestId, String userId, bool approved) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update request status
      batch.update(
        FirebaseFirestore.instance.collection('joinRequests').doc(requestId),
        {'status': approved ? 'approved' : 'rejected'},
      );
      
      // If approved, add user to club members
      if (approved) {
        batch.update(
          FirebaseFirestore.instance.collection('club').doc(clubId),
          {
            'members': FieldValue.arrayUnion([userId])
          },
        );
      }
      
      await batch.commit();
    } catch (e) {
      print('Error handling request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Join Requests'),
        backgroundColor: Color(0xFFD7F520),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('joinRequests')
            .where('clubId', isEqualTo: clubId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending join requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final userId = request['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final userPhoto = userData['photoUrl'];

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: userPhoto != null
                                ? NetworkImage(userPhoto)
                                : null,
                            child: userPhoto == null
                                ? Icon(Icons.person)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Requested to join',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check_circle_outline,
                                    color: Colors.green),
                                onPressed: () => _handleRequest(
                                    request.id, userId, true),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel_outlined,
                                    color: Colors.red),
                                onPressed: () => _handleRequest(
                                    request.id, userId, false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
