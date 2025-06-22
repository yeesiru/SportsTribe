import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:map_project/pages/create_event.dart';

class ViewEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String? clubId;

  const ViewEventPage({
    Key? key,
    required this.eventId,
    required this.eventData,
    this.clubId,
  }) : super(key: key);

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late Map<String, dynamic> eventData;

  @override
  void initState() {
    super.initState();
    eventData = Map.from(widget.eventData);
  }

  bool get isEventCreator => eventData['createdBy'] == user.uid;

  List<dynamic> get participants {
    final participantsData = eventData['participants'];
    if (participantsData is List) {
      return participantsData;
    } else if (participantsData is int) {
      // If it's stored as an int (legacy data), convert to list with creator
      return [eventData['createdBy']];
    }
    return []; // Default to empty list
  }

  bool get isUserJoined => participants.contains(user.uid);

  int get maxParticipants => eventData['maxParticipants'] ?? 0;

  bool get isEventFull => participants.length >= maxParticipants;

  Future<void> _joinEvent() async {
    try {
      DocumentReference eventRef;
      if (widget.clubId != null) {
        eventRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('events')
            .doc(widget.eventId);
      } else {
        eventRef =
            FirebaseFirestore.instance.collection('events').doc(widget.eventId);
      }

      await eventRef.update({
        'participants': FieldValue.arrayUnion([user.uid])
      });

      setState(() {
        eventData['participants'] = [...participants, user.uid];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined the event!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
    }
  }

  Future<void> _leaveEvent() async {
    try {
      DocumentReference eventRef;
      if (widget.clubId != null) {
        eventRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('events')
            .doc(widget.eventId);
      } else {
        eventRef =
            FirebaseFirestore.instance.collection('events').doc(widget.eventId);
      }

      await eventRef.update({
        'participants': FieldValue.arrayRemove([user.uid])
      });

      setState(() {
        eventData['participants'] =
            participants.where((id) => id != user.uid).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left the event')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving event: $e')),
      );
    }
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventPage(
          clubId: widget.clubId,
          eventData: {...eventData, 'id': widget.eventId},
        ),
      ),
    );

    if (result == true) {
      // Refresh event data
      _refreshEventData();
    }
  }

  Future<void> _refreshEventData() async {
    try {
      DocumentSnapshot eventDoc;
      if (widget.clubId != null) {
        eventDoc = await FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('events')
            .doc(widget.eventId)
            .get();
      } else {
        eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get();
      }

      if (eventDoc.exists) {
        setState(() {
          eventData = eventDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error refreshing event data: $e');
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text(
            'Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (widget.clubId != null) {
          await FirebaseFirestore.instance
              .collection('club')
              .doc(widget.clubId)
              .collection('events')
              .doc(widget.eventId)
              .delete();
        } else {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .delete();
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = eventData['date'] != null
        ? (eventData['date'] as Timestamp).toDate()
        : null;
    final time = eventData['time'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image
          SliverAppBar(
            expandedHeight:
                eventData['imageUrl'] != null && eventData['imageUrl'] != ''
                    ? 300
                    : 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (isEventCreator)
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEvent();
                      } else if (value == 'delete') {
                        _deleteEvent();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit Event'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Event',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (eventData['imageUrl'] != null &&
                      eventData['imageUrl'] != '')
                    Image.network(
                      eventData['imageUrl'],
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFD7F520),
                            Color(0xFFD7F520).withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.event,
                          size: 80,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  // Event type badge
                  Positioned(
                    top: 100,
                    left: 20,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            eventData['type'] == 'personal'
                                ? Icons.person
                                : Icons.group,
                            size: 16,
                            color: eventData['type'] == 'personal'
                                ? Colors.orange[600]
                                : Colors.blue[600],
                          ),
                          SizedBox(width: 6),
                          Text(
                            eventData['type'] == 'personal'
                                ? 'Personal Event'
                                : 'Club Event',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Event Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      eventData['title'] ?? 'Event',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Participants Status
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: participants.length >= maxParticipants
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: participants.length >= maxParticipants
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            participants.length >= maxParticipants
                                ? Icons.people_alt
                                : Icons.people_outline,
                            size: 16,
                            color: participants.length >= maxParticipants
                                ? Colors.red[600]
                                : Colors.green[600],
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${participants.length}/$maxParticipants participants',
                            style: TextStyle(
                              color: participants.length >= maxParticipants
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Event Details Cards
                    _buildDetailCard(
                      icon: Icons.calendar_today,
                      title: 'Date & Time',
                      content: date != null
                          ? '${date.day}/${date.month}/${date.year} at $time'
                          : 'Date not set',
                      color: Colors.blue[600]!,
                    ),
                    SizedBox(height: 16),

                    _buildDetailCard(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: eventData['location'] ?? 'Location not set',
                      color: Colors.red[600]!,
                    ),
                    SizedBox(height: 16),

                    _buildDetailCard(
                      icon: Icons.sports,
                      title: 'Sport & Level',
                      content:
                          '${eventData['sport'] ?? 'N/A'} • ${eventData['level'] ?? 'N/A'}',
                      color: Colors.green[600]!,
                    ),

                    SizedBox(height: 32),

                    // Description Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description,
                                  color: Colors.purple[600], size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            eventData['description'] ??
                                'No description provided',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),

                    // Action Button for Non-Creators
                    if (!isEventCreator)
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isEventFull && !isUserJoined
                              ? null
                              : isUserJoined
                                  ? _leaveEvent
                                  : _joinEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUserJoined
                                ? Colors.red[400]
                                : isEventFull
                                    ? Colors.grey[400]
                                    : Color(0xFFD7F520),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isUserJoined
                                    ? Icons.exit_to_app
                                    : isEventFull
                                        ? Icons.block
                                        : Icons.add_circle,
                                color: isUserJoined || isEventFull
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              SizedBox(width: 12),
                              Text(
                                isUserJoined
                                    ? 'Leave Event'
                                    : isEventFull
                                        ? 'Event Full'
                                        : 'Join Event',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isUserJoined || isEventFull
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
