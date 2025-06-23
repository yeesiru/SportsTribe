import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
  final Map<String, bool> _alreadyMarked = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _selectAll = false;
  bool _attendanceAlreadyRecorded = false;
  Timer? _submitTimer;
  int _timeoutCountdown = 30;
  @override
  void initState() {
    super.initState();
    _initializeAttendance();
  }

  @override
  void dispose() {
    _submitTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAttendance() async {
    // Initialize attendance map
    for (String participantId in widget.participants) {
      _attendance[participantId] = false;
      _alreadyMarked[participantId] = false;
    }

    // Check if attendance has already been recorded for this event
    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists) {
        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;

        // Check if attendance field exists and has been recorded
        if (eventData.containsKey('attendance') &&
            eventData['attendance'] is Map) {
          Map<String, dynamic> attendanceData = eventData['attendance'];

          // Check if any participant already has attendance marked
          for (String participantId in widget.participants) {
            if (attendanceData.containsKey(participantId)) {
              _alreadyMarked[participantId] = true;
              _attendance[participantId] =
                  attendanceData[participantId] ?? false;
            }
          }

          // If any participant has been marked, consider attendance as recorded
          if (_alreadyMarked.values.any((marked) => marked)) {
            _attendanceAlreadyRecorded = true;
          }
        }
      }
    } catch (e) {
      print('Error checking existing attendance: $e');
    }

    // Fetch participant data
    for (String participantId in widget.participants) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(participantId)
            .get();

        if (userDoc.exists) {
          _participantData[participantId] =
              userDoc.data() as Map<String, dynamic>;
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
    if (_attendanceAlreadyRecorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance has already been recorded for this event'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectAll = !_selectAll;
      for (String participantId in _attendance.keys) {
        if (!_alreadyMarked[participantId]!) {
          _attendance[participantId] = _selectAll;
        }
      }
    });
  }

  void _toggleAttendance(String participantId) {
    if (_alreadyMarked[participantId]!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('This participant\'s attendance has already been recorded'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _attendance[participantId] = !(_attendance[participantId] ?? false);

      // Update select all state (only consider unmarked participants)
      bool allUnmarkedSelected = true;
      for (String id in _attendance.keys) {
        if (!_alreadyMarked[id]! && !_attendance[id]!) {
          allUnmarkedSelected = false;
          break;
        }
      }
      _selectAll = allUnmarkedSelected;
    });
  }

  Future<void> _submitAttendance() async {
    // Check if all participants are already marked
    if (_alreadyMarked.values.every((marked) => marked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('All participants\' attendance has already been recorded'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create a map with only unmarked participants
    Map<String, bool> newAttendance = {};
    for (String participantId in _attendance.keys) {
      if (!_alreadyMarked[participantId]!) {
        newAttendance[participantId] = _attendance[participantId]!;
      }
    }

    if (newAttendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No new attendance to record'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _timeoutCountdown = 30;
    });

    // Start countdown timer
    _submitTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeoutCountdown--;
      });
      if (_timeoutCountdown <= 0) {
        timer.cancel();
      }
    });

    try {
      // Add timeout to prevent indefinite loading
      bool success = await PointsBadgeService.markAttendance(
        widget.eventId,
        widget.eventTitle,
        newAttendance,
        widget.clubId,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timed out. Please check your internet connection.');
        },
      );

      _submitTimer?.cancel();

      if (success) {
        // Show success dialog with details
        _showAttendanceResults(newAttendance);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _submitTimer?.cancel();

      String errorMessage;
      if (e.toString().contains('timed out')) {
        errorMessage =
            'Request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
        _timeoutCountdown = 30;
      });
    }
  }

  void _showAttendanceResults([Map<String, bool>? newAttendanceData]) {
    Map<String, bool> attendanceToShow = newAttendanceData ?? _attendance;
    int presentCount =
        attendanceToShow.values.where((present) => present).length;
    int totalCount = attendanceToShow.length;
    int alreadyMarkedCount =
        _alreadyMarked.values.where((marked) => marked).length;

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
                  Text('Total processed: $totalCount'),
                  if (alreadyMarkedCount > 0)
                    Text('Already marked: $alreadyMarkedCount',
                        style: TextStyle(color: Colors.orange[700])),
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
                // Warning message if some participants are already marked
                if (_alreadyMarked.values.any((marked) => marked))
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[600]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Some participants already have their attendance recorded. They cannot be marked again.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      Map<String, dynamic>? userData =
                          _participantData[participantId];
                      bool isPresent = _attendance[participantId] ?? false;
                      bool isAlreadyMarked =
                          _alreadyMarked[participantId] ?? false;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAlreadyMarked
                                ? Colors.orange[300]!
                                : isPresent
                                    ? Colors.green[300]!
                                    : Colors.grey[200]!,
                            width: (isAlreadyMarked || isPresent) ? 2 : 1,
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
                            backgroundImage: userData?['photoUrl'] != null &&
                                    userData!['photoUrl'].isNotEmpty
                                ? NetworkImage(userData['photoUrl'])
                                    as ImageProvider
                                : null,
                            child: userData?['photoUrl'] == null ||
                                    userData!['photoUrl'].isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userData?['name'] ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isAlreadyMarked
                                        ? Colors.grey[600]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isAlreadyMarked)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Already Marked',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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
                            onTap: isAlreadyMarked
                                ? null
                                : () => _toggleAttendance(participantId),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAlreadyMarked
                                    ? Colors.orange[300]
                                    : isPresent
                                        ? Colors.green[500]
                                        : Colors.grey[300],
                                border: Border.all(
                                  color: isAlreadyMarked
                                      ? Colors.orange[600]!
                                      : isPresent
                                          ? Colors.green[700]!
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: isAlreadyMarked
                                  ? Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : isPresent
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                            ),
                          ),
                          onTap: isAlreadyMarked
                              ? null
                              : () => _toggleAttendance(participantId),
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
                        onPressed: (_isSubmitting ||
                                _alreadyMarked.values.every((marked) => marked))
                            ? null
                            : _submitAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
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
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Timeout in ${_timeoutCountdown}s',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
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
