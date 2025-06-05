import 'package:flutter/material.dart';
import 'package:map_project/pages/admin_manage_reward.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _tabs = ['Users', 'Clubs', 'Reports', 'Rewards'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFD4FF3D), // Lime green color from the image
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Icon(
              Icons.open_in_new,
              color: Colors.black,
              size: 20,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                int index = entry.key;
                String tab = entry.value;
                bool isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });

                      // Navigate to Rewards Management if Rewards tab is selected
                      if (index == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RewardManagementPage(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildUsersList();
      case 1:
        return _buildClubsList();
      case 2:
        return _buildReportsList();
      case 3:
        // This case should never be reached since we navigate directly
        return Container(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      default:
        return _buildUsersList();
    }
  }

  Widget _buildUsersList() {
    final users = [
      {'name': 'Happy', 'avatar': '😊'},
      {'name': 'Sunny', 'avatar': '☀️'},
      {'name': 'ShinChan', 'avatar': '👦'},
      {'name': 'Curry', 'avatar': '🍛'},
      {'name': 'Tracy', 'avatar': '👩'},
      {'name': 'Siru', 'avatar': '🧑'},
      {'name': 'Bubble', 'avatar': '🫧'},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        user['avatar']!,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Add User',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubsList() {
    final clubs = [
      {'name': 'Badminton Squad', 'icon': '🏸', 'color': Colors.green},
      {'name': 'SmashIt', 'icon': '🎾', 'color': Colors.orange},
      {'name': 'Pick a Ball', 'icon': '⚽', 'color': Colors.blue},
      {'name': 'Tanlet', 'icon': '🏓', 'color': Colors.purple},
      {'name': 'BoBola', 'icon': '⚽', 'color': Colors.indigo},
      {'name': 'BasketBall ProKa', 'icon': '🏀', 'color': Colors.orange},
      {'name': 'Tennis kaki', 'icon': '🎾', 'color': Colors.green},
    ];

    return Column(
      children: [
        // Expanded(
        //   child: ListView.builder(
        //     padding: EdgeInsets.symmetric(horizontal: 16),
        //     itemCount: clubs.length,
        //     itemBuilder: (context, index) {
        //       final club = clubs[index];
        //       return Container(
        //         margin: EdgeInsets.only(bottom: 8),
        //         padding: EdgeInsets.all(16),
        //         decoration: BoxDecoration(
        //           color: Colors.white,
        //           borderRadius: BorderRadius.circular(12),
        //           boxShadow: [
        //             BoxShadow(
        //               color: Colors.black.withOpacity(0.05),
        //               blurRadius: 5,
        //               offset: Offset(0, 2),
        //             ),
        //           ],
        //         ),
        //         child: Row(
        //           children: [
        //             CircleAvatar(
        //               radius: 20,
        //               backgroundColor:
        //                   (club['color'] as Color).withOpacity(0.2),
        //               child: Text(
        //                 club['icon']!,
        //                 style: TextStyle(fontSize: 20),
        //               ),
        //             ),
        //             SizedBox(width: 12),
        //             Expanded(
        //               child: Text(
        //                 club['name']!,
        //                 style: TextStyle(
        //                   fontSize: 16,
        //                   fontWeight: FontWeight.w500,
        //                 ),
        //               ),
        //             ),
        //             IconButton(
        //               icon: Icon(Icons.edit, size: 18),
        //               onPressed: () {},
        //             ),
        //             IconButton(
        //               icon: Icon(Icons.delete, size: 18),
        //               onPressed: () {},
        //             ),
        //           ],
        //         ),
        //       );
        //     },
        //   ),
        // ),
        Container(
          margin: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Add Club',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    final reports = [
      {'user': 'Happy', 'action': 'has reported BoBola', 'time': 'Yesterday'},
      {
        'user': 'ShinChan',
        'action': 'has reported BoBola',
        'time': '2 days ago'
      },
    ];

    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    report['user']![0],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report['user']} ${report['action']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        report['time']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
