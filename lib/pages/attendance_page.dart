import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/points_badge_service.dart';

class AttendancePage extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final List<String> participants;
  final String? clubId;

  const AttendancePage({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.participants,
    this.clubId,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final Map<String, bool> _attendance = {};
  final Map<String, Map<String, dynamic>> _participantData = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
  }

  Future<void> _initializeAttendance() async {
    // Initialize attendance map
    for (String participantId in widget.participants) {
      _attendance[participantId] = false;
    }

    // Fetch participant data
    for (String participantId in widget.participants) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(participantId)
            .get();
        
        if (userDoc.exists) {
          _participantData[participantId] = userDoc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error fetching participant data: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (String participantId in _attendance.keys) {
        _attendance[participantId] = _selectAll;
      }
    });
  }

  void _toggleAttendance(String participantId) {
    setState(() {
      _attendance[participantId] = !(_attendance[participantId] ?? false);
      
      // Update select all state
      _selectAll = _attendance.values.every((present) => present);
    });
  }

  Future<void> _submitAttendance() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      bool success = await PointsBadgeService.markAttendance(
        widget.eventId,
        widget.eventTitle,
        _attendance,
        widget.clubId,
      );

      if (success) {
        // Show success dialog with details
        _showAttendanceResults();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAttendanceResults() {
    int presentCount = _attendance.values.where((present) => present).length;
    int totalCount = _attendance.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Attendance Marked'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance has been successfully recorded for ${widget.eventTitle}.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Present: $presentCount'),
                  Text('Absent: ${totalCount - presentCount}'),
                  Text('Total: $totalCount'),
                  SizedBox(height: 8),
                  Text(
                    'Points and badges have been awarded to attendees!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close attendance page
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Mark Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (!_isLoading && !_isSubmitting)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _selectAll ? 'Unselect All' : 'Select All',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Event Info Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Colors.blue[600], size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.eventTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            '${widget.participants.length} participants',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Participants List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.participants.length,
                    itemBuilder: (context, index) {
                      String participantId = widget.participants[index];
                      Map<String, dynamic>? userData = _participantData[participantId];
                      bool isPresent = _attendance[participantId] ?? false;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent ? Colors.green[300]! : Colors.grey[200]!,
                            width: isPresent ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: userData?['photoUrl'] != null && userData!['photoUrl'].isNotEmpty
                                ? NetworkImage(userData['photoUrl']) as ImageProvider
                                : null,
                            child: userData?['photoUrl'] == null || userData!['photoUrl'].isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          title: Text(
                            userData?['name'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: userData?['email'] != null
                              ? Text(
                                  userData!['email'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                          trailing: GestureDetector(
                            onTap: () => _toggleAttendance(participantId),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPresent ? Colors.green[500] : Colors.grey[300],
                                border: Border.all(
                                  color: isPresent ? Colors.green[700]! : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: isPresent
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                          onTap: () => _toggleAttendance(participantId),
                        ),
                      );
                    },
                  ),
                ),

                // Submit Button
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Marking Attendance...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Mark Attendance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
