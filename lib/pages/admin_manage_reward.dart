import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardManagementPage extends StatefulWidget {
  @override
  _RewardManagementPageState createState() => _RewardManagementPageState();
}

class _RewardManagementPageState extends State<RewardManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _rewardsCollection;
  
  @override
  void initState() {
    super.initState();
    _rewardsCollection = _firestore.collection('rewards');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFD4FF3D),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reward Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Stats
          _buildHeaderStats(),
          
          // Rewards List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _rewardsCollection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading rewards',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading rewards...',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                        Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No rewards found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first reward',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final rewards = snapshot.data!.docs;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final rewardData = reward.data() as Map<String, dynamic>;
                    return _buildRewardCard(rewardData, reward.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRewardDialog(),
        backgroundColor: Color(0xFFD4FF3D),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _rewardsCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Rewards', '-', Icons.card_giftcard),
                _buildStatCard('Active', '-', Icons.check_circle),
                _buildStatCard('Categories', '-', Icons.category),
              ],
            ),
          );
        }

        final rewards = snapshot.data!.docs;
        final totalRewards = rewards.length;
        final activeRewards = rewards.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['availability'] == 'Available';
        }).length;
        
        final categories = rewards.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['category'];
        }).toSet().length;

        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Rewards', '$totalRewards', Icons.card_giftcard),
              _buildStatCard('Active', '$activeRewards', Icons.check_circle),
              _buildStatCard('Categories', '$categories', Icons.category),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue[600]),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, String documentId) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with points and actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reward['pointsCost']} pts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                      onPressed: () => _showEditRewardDialog(reward, documentId),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20, color: Colors.red[600]),
                      onPressed: () => _deleteReward(documentId, reward['name']),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  reward['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip('Category', reward['category']),
                    _buildInfoChip('Remaining',
                        '${reward['remainingQuantity']}/${reward['totalQuantity']}'),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reward['availability'] == 'Available'
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reward['availability'],
                    style: TextStyle(
                      color: reward['availability'] == 'Available'
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddRewardDialog() {
    _showRewardDialog();
  }

  void _showEditRewardDialog(Map<String, dynamic> reward, String documentId) {
    _showRewardDialog(reward: reward, documentId: documentId);
  }

  void _showRewardDialog({Map<String, dynamic>? reward, String? documentId}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: reward?['name'] ?? '');
    final _descriptionController =
        TextEditingController(text: reward?['description'] ?? '');
    final _pointsController =
        TextEditingController(text: reward?['pointsCost']?.toString() ?? '');
    final _quantityController =
        TextEditingController(text: reward?['totalQuantity']?.toString() ?? '');

    String _selectedCategory = reward?['category'] ?? 'Training';
    String _selectedAvailability = reward?['availability'] ?? 'Available';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    reward == null ? Icons.add : Icons.edit,
                    color: Colors.blue[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    reward == null ? 'Add New Reward' : 'Edit Reward',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reward Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Reward Name *',
                            prefixIcon: Icon(Icons.card_giftcard),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter reward name';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Description Field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter description';
                            }
                            if (value.trim().length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Points Cost Field
                        TextFormField(
                          controller: _pointsController,
                          decoration: InputDecoration(
                            labelText: 'Points Cost *',
                            prefixIcon: Icon(Icons.stars),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            suffixText: 'pts',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter points cost';
                            }
                            final points = int.tryParse(value.trim());
                            if (points == null || points <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            if (points > 10000) {
                              return 'Points cost cannot exceed 10,000';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Quantity Field
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Total Quantity *',
                            prefixIcon: Icon(Icons.inventory),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            suffixText: 'items',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter total quantity';
                            }
                            final quantity = int.tryParse(value.trim());
                            if (quantity == null || quantity <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            if (quantity > 1000) {
                              return 'Quantity cannot exceed 1,000';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Category Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'Training', child: Text('🏋️ Training')),
                            DropdownMenuItem(
                                value: 'Merchandise',
                                child: Text('👕 Merchandise')),
                            DropdownMenuItem(
                                value: 'Subscription',
                                child: Text('💎 Subscription')),
                            DropdownMenuItem(
                                value: 'Equipment', child: Text('⚽ Equipment')),
                            DropdownMenuItem(
                                value: 'Voucher', child: Text('🎫 Voucher')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCategory = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Availability Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedAvailability,
                          decoration: InputDecoration(
                            labelText: 'Availability Status *',
                            prefixIcon: Icon(Icons.visibility),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'Available', child: Text('✅ Available')),
                            DropdownMenuItem(
                                value: 'Unavailable',
                                child: Text('❌ Unavailable')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedAvailability = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select availability status';
                            }
                            return null;
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
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        await _saveReward(
                          reward: reward,
                          documentId: documentId,
                          name: _nameController.text.trim(),
                          description: _descriptionController.text.trim(),
                          pointsCost: int.parse(_pointsController.text.trim()),
                          totalQuantity: int.parse(_quantityController.text.trim()),
                          category: _selectedCategory,
                          availability: _selectedAvailability,
                        );
                        
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close form dialog

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              reward == null
                                  ? 'Reward added successfully!'
                                  : 'Reward updated successfully!',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context); // Close loading dialog
                        
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error saving reward: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4FF3D),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(reward == null ? Icons.add : Icons.update),
                      SizedBox(width: 8),
                      Text(
                        reward == null ? 'Add Reward' : 'Update Reward',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveReward({
    Map<String, dynamic>? reward,
    String? documentId,
    required String name,
    required String description,
    required int pointsCost,
    required int totalQuantity,
    required String category,
    required String availability,
  }) async {
    final now = DateTime.now();
    final rewardData = {
      'name': name,
      'description': description,
      'pointsCost': pointsCost,
      'category': category,
      'availability': availability,
      'totalQuantity': totalQuantity,
      'remainingQuantity': reward?['remainingQuantity'] ?? totalQuantity,
      'updatedAt': Timestamp.fromDate(now),
    };

    if (documentId != null) {
      // Update existing reward
      await _rewardsCollection.doc(documentId).update(rewardData);
    } else {
      // Add new reward
      rewardData['createdAt'] = Timestamp.fromDate(now);
      await _rewardsCollection.add(rewardData);
    }
  }

  void _deleteReward(String documentId, String rewardName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[600],
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Delete Reward',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this reward?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  rewardName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await _rewardsCollection.doc(documentId).delete();
                  
                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close confirmation dialog

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Reward deleted successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close loading dialog
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting reward: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_forever),
                  SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}