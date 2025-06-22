import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({Key? key}) : super(key: key);

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _selectedDateRange = 'Last 30 Days';
  bool _isLoading = false;
  final List<String> _dateRangeOptions = [
    'Last 7 Days',
    'Last 30 Days', 
    'Last 90 Days',
    'This Year',
  ];

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate refresh delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],      appBar: AppBar(
        title: Text('Reports & Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Data',
            ),
        ],
      ),body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildDateRangeSelector(),
              _buildOverviewCards(),
              _buildChartsSection(),
              _buildRecentActivitySection(),
              SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Date Range:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedDateRange,
              isExpanded: true,
              items: _dateRangeOptions.map((range) => DropdownMenuItem(
                value: range,
                child: Text(range),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDateRange = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOverviewCards() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                        SizedBox(height: 8),
                        Text(
                          'Error loading data',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('club').snapshots(),
                builder: (context, clubSnapshot) {
                  if (clubSnapshot.hasError) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                            SizedBox(height: 8),
                            Text(
                              'Error loading club data',
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').snapshots(),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.hasError) {
                        return Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                                SizedBox(height: 8),
                                Text(
                                  'Error loading event data',
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (!userSnapshot.hasData || !clubSnapshot.hasData || !eventSnapshot.hasData) {
                        return Container(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final totalUsers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                      final totalClubs = clubSnapshot.hasData ? clubSnapshot.data!.docs.length : 0;
                      final totalEvents = eventSnapshot.hasData ? eventSnapshot.data!.docs.length : 0;
                      
                      // Calculate active users (users who joined clubs)
                      int activeUsers = 0;
                      if (userSnapshot.hasData) {
                        for (var doc in userSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final communityList = data['communityList'] as List? ?? [];
                          if (communityList.isNotEmpty) {
                            activeUsers++;
                          }
                        }
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive grid based on screen width
                          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                          double cardHeight = 140;
                          double gridHeight = (cardHeight * (4 / crossAxisCount)) + 
                                            (12 * ((4 / crossAxisCount) - 1)); // Account for spacing
                          
                          return SizedBox(
                            height: gridHeight,
                            child: GridView.count(
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 1.4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: [
                                _buildOverviewCard(
                                  'Total Users',
                                  totalUsers.toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                                _buildOverviewCard(
                                  'Active Users',
                                  activeUsers.toString(),
                                  Icons.person_outline,
                                  Colors.green,
                                ),
                                _buildOverviewCard(
                                  'Total Clubs',
                                  totalClubs.toString(),
                                  Icons.groups,
                                  Colors.orange,
                                ),
                                _buildOverviewCard(
                                  'Total Events',
                                  totalEvents.toString(),
                                  Icons.calendar_today,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
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
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '↗',
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChartsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Engagement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                        SizedBox(height: 8),
                        Text(
                          'Error loading user data',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData) {
                return Container(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final users = snapshot.data!.docs;
              Map<String, int> sportCounts = {};
              
              for (var doc in users) {
                final data = doc.data() as Map<String, dynamic>;
                final sportsList = data['sportsList'] as List? ?? [];
                for (var sport in sportsList) {
                  sportCounts[sport.toString()] = (sportCounts[sport.toString()] ?? 0) + 1;
                }
              }

              if (sportCounts.isEmpty) {
                return Container(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_basketball, 
                             size: 40, color: Colors.grey[400]),
                        SizedBox(height: 8),
                        Text(
                          'No sports data available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Limit to top 5 sports for better UI
              final sortedEntries = sportCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final topSports = sortedEntries.take(5).toList();

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                  minHeight: 150,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: topSports.length,
                  itemBuilder: (context, index) {
                    final entry = topSports[index];
                    final maxCount = topSports.first.value;
                    final percentage = (entry.value / maxCount);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${entry.value} users',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.withOpacity(0.8),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildRecentActivitySection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                        SizedBox(height: 8),
                        Text(
                          'Error loading recent activity',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData) {
                return Container(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final recentUsers = snapshot.data!.docs;
              
              if (recentUsers.isEmpty) {
                return Container(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, 
                             size: 40, color: Colors.grey[400]),
                        SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: recentUsers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown User';
                  final email = data['email'] ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final role = data['role'] ?? 'member';
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: role == 'admin' ? Colors.orange[100] : Colors.blue[100],
                          child: Icon(
                            role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                            size: 16,
                            color: role == 'admin' ? Colors.orange[700] : Colors.blue[700],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (role == 'admin')
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            SizedBox(height: 4),
                            Text(
                              createdAt != null 
                                  ? DateFormat('MMM dd').format(createdAt.toDate())
                                  : 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
