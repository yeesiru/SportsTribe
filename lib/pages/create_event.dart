import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventPage extends StatefulWidget {
  final String? clubId; // Pass the clubId when navigating to this page

  const CreateEventPage({super.key, this.clubId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Form variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSport;
  String? _selectedLevel;
  int _maxParticipants = 1;
  bool _isPublic = true; // For personal events
  File? _eventImage;
  bool _isLoading = false;
  bool _isPickingImage = false;

  final List<String> _sports = [
    "Badminton",
    "Tennis",
    "Pickleball",
    "Basketball",
    "Football",
    "Volleyball"
  ];
  final List<String> _levels = [
    "Beginner",
    "Intermediate",
    "Advanced",
    "All levels"
  ];
  @override
  void initState() {
    super.initState();
    // No need to populate fields for create event
  }
  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70, // Reduced for faster upload
        maxWidth: 1200,   // Limit width for faster upload
        maxHeight: 1200,  // Limit height for faster upload
      );
      if (picked != null) {
        setState(() {
          _eventImage = File(picked.path);
        });
      }
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }
  Future<String?> _uploadImage(File imageFile) async {
    // Upload with better metadata and compression
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_new_event.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('event_images')
        .child(fileName);
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    
    await ref.putFile(imageFile, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? imageUrl;      if (_eventImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        imageUrl = await _uploadImage(_eventImage!);
      }

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'sport': _selectedSport,
        'level': _selectedLevel,
        'date': Timestamp.fromDate(_selectedDate!),
        'time':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'maxParticipants': _maxParticipants,
        'participants': [user.uid],
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'imageUrl': imageUrl,
      };

      if (widget.clubId != null) {
        // Club event
        eventData['isPublic'] = _isPublic;
        await FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('events')
            .add(eventData);
      } else {
        // Personal event - store in main events collection
        eventData['isPublic'] = _isPublic;
        eventData['type'] = 'personal';
        await FirebaseFirestore.instance.collection('events').add(eventData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event Created!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Event',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image upload area
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [                        Center(
                          child: _eventImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(_eventImage!,
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover),
                                )
                              : _isPickingImage
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.image,
                                      size: 70, color: Color(0xFF4A7AFF)),
                        ),
                        if (_eventImage != null)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _eventImage = null),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),                                child: const Icon(Icons.close,
                                    color: Colors.black, size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),                ),
                const SizedBox(height: 24),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'Enter event title',
                    filled: true,
                    fillColor: Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter event title'
                      : null,
                ),
                SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your event',
                    filled: true,
                    fillColor: Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter description'
                      : null,
                ),
                SizedBox(height: 16),

                // Date and Time row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: TextStyle(
                                  color: _selectedTime != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter event location',
                    filled: true,
                    fillColor: Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter location'
                      : null,
                ),
                SizedBox(height: 16),

                // Sport and Level dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSport,
                        decoration: InputDecoration(
                          labelText: 'Sport',
                          filled: true,
                          fillColor: Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _sports.map((sport) {
                          return DropdownMenuItem<String>(
                            value: sport,
                            child: Text(sport),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSport = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select sport' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          filled: true,
                          fillColor: Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _levels.map((level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select level' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Max participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Participants',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () => setState(() {
                            if (_maxParticipants > 1) _maxParticipants--;
                          }),
                        ),
                        Container(
                          width: 50,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$_maxParticipants',
                              textAlign: TextAlign.center),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => setState(() => _maxParticipants++),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Public/Private toggle (only for personal events or club events)
                if (widget.clubId == null || widget.clubId!.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Public Event', style: TextStyle(fontSize: 16)),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) =>
                              setState(() => _isPublic = value),
                          activeColor: Colors.black,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 32),

                // Save button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveEvent,                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
