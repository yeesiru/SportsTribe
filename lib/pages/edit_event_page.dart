import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String? clubId;

  const EditEventPage({
    super.key,
    required this.eventId,
    required this.eventData,
    this.clubId,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
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
  bool _isPublic = true;
  File? _eventImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _isUploadingImage = false;

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
    _populateFields();
    _checkFirebaseStorageConnection();
  }

  void _populateFields() {
    // Populate form fields with existing data
    _titleController.text = widget.eventData['title'] ?? '';
    _descriptionController.text = widget.eventData['description'] ?? '';
    _locationController.text = widget.eventData['location'] ?? '';
    
    // Safely set sport and level with validation
    final eventSport = widget.eventData['sport'];
    _selectedSport = _sports.contains(eventSport) ? eventSport : null;
    
    final eventLevel = widget.eventData['level'];
    _selectedLevel = _levels.contains(eventLevel) ? eventLevel : null;
      _maxParticipants = widget.eventData['maxParticipants'] ?? 1;
    _isPublic = widget.eventData['isPublic'] ?? true;    // Safely handle image URL
    final imageUrl = widget.eventData['imageUrl'];
    print('Loading event image URL: $imageUrl');
    
    if (_isValidImageUrl(imageUrl?.toString())) {
      _existingImageUrl = imageUrl.toString();
      print('Valid image URL set: $_existingImageUrl');
    } else {
      _existingImageUrl = null;
      print('Invalid or empty image URL, set to null');
    }

    // Parse date and time if available
    if (widget.eventData['date'] != null) {
      _selectedDate = (widget.eventData['date'] as Timestamp).toDate();
    }
    if (widget.eventData['time'] != null) {
      final timeString = widget.eventData['time'] as String;
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Good quality for event images
        maxWidth: 1920,   // Higher resolution for better quality
        maxHeight: 1920,  // Higher resolution for better quality
      );
      if (picked != null) {
        final file = File(picked.path);
        
        // Validate the file
        if (await file.exists()) {
          final fileSize = await file.length();
          const maxFileSize = 10 * 1024 * 1024; // 10MB limit
          
          if (fileSize > maxFileSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image is too large. Please select an image smaller than 10MB.')),
              );
            }
            return;
          }
          
          setState(() {
            _eventImage = file;
          });
          print('Image selected: ${file.path}, size: $fileSize bytes');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selected image file is not accessible')),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }Future<String?> _uploadImage(File imageFile) async {
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      // Validate file exists and has content
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      
      // Create unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.eventId}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('event_images')
          .child(fileName);
      
      // Upload with metadata and better error handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'eventId': widget.eventId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      print('Starting upload of file: ${imageFile.path}, size: $fileSize bytes');
      
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      // Wait for upload to complete
      await uploadTask;
      
      final downloadUrl = await ref.getDownloadURL();
      print('Upload successful! Download URL: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error during upload: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.message}')),
        );
      }
      rethrow;
    } catch (e) {
      print('General error during upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
  }  Future<void> _updateEvent() async {
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
      String? imageUrl = _existingImageUrl;

      // Only upload new image if user selected a new one
      if (_eventImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        try {
          imageUrl = await _uploadImage(_eventImage!);
          print('Image uploaded successfully: $imageUrl');
        } catch (uploadError) {
          print('Image upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $uploadError'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // Continue without image if upload fails
          imageUrl = _existingImageUrl;
        }
      }

      // Prepare event data
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'sport': _selectedSport,
        'level': _selectedLevel,
        'date': Timestamp.fromDate(_selectedDate!),
        'time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'maxParticipants': _maxParticipants,
        'updatedAt': Timestamp.now(),
        'isPublic': _isPublic,
      };

      // Only include imageUrl if it's not null
      if (imageUrl != null && imageUrl.isNotEmpty) {
        eventData['imageUrl'] = imageUrl;
      }

      // Update event in Firestore
      DocumentReference eventRef;
      if (widget.clubId != null) {
        eventRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('events')
            .doc(widget.eventId);
      } else {
        eventRef = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId);
      }

      print('Updating event in Firestore...');
      await eventRef.update(eventData);
      print('Event updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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

  // Diagnostic function to test Firebase Storage connection
  Future<void> _checkFirebaseStorageConnection() async {
    try {
      print('Testing Firebase Storage connection...');
      final ref = FirebaseStorage.instance.ref().child('test').child('connection_test.txt');
      
      // Try to get metadata or download URL (this will fail if Storage isn't properly configured)
      await ref.getMetadata().timeout(const Duration(seconds: 5));
      print('Firebase Storage connection test: SUCCESS');
    } on FirebaseException catch (e) {
      print('Firebase Storage error: ${e.code} - ${e.message}');
      if (e.code == 'object-not-found') {
        print('Firebase Storage is connected but test file doesn\'t exist (this is expected)');
      }
    } catch (e) {
      print('Firebase Storage connection test failed: $e');
    }
  }

  // Helper method to validate image URLs
  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    
    // Check if it's a valid HTTP/HTTPS URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    
    // Try to parse as URI to check validity
    try {
      final uri = Uri.parse(url);
      return uri.hasAbsolutePath && uri.host.isNotEmpty;
    } catch (e) {
      return false;
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
          'Edit Event',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image upload area
                GestureDetector(
                  onTap: _isLoading || _isUploadingImage ? null : _pickImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Center(                          child: _eventImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(
                                    _eventImage!,
                                    width: double.infinity,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                )                              : _isValidImageUrl(_existingImageUrl)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        _existingImageUrl!,
                                        width: double.infinity,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading image: $error');
                                          print('Stack trace: $stackTrace');
                                          
                                          // Show specific error message
                                          String errorMessage = 'Failed to load image';
                                          if (error.toString().contains('host')) {
                                            errorMessage = 'Invalid image URL';
                                          } else if (error.toString().contains('network')) {
                                            errorMessage = 'Network error';
                                          }
                                          
                                          return Container(
                                            width: double.infinity,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  errorMessage,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ): _isPickingImage
                                      ? const CircularProgressIndicator()
                                      : _isUploadingImage
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const CircularProgressIndicator(),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Uploading...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 70,
                                              color: Color(0xFF4A7AFF),
                                            ),
                        ),
                        if (_eventImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _eventImage = null;
                                _existingImageUrl = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'Enter event title',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter event title'
                      : null,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your event',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
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
                const SizedBox(height: 16),

                // Date and Time row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                              const SizedBox(width: 8),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey[600]),
                              const SizedBox(width: 8),
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
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter event location',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter location'
                      : null,
                ),
                const SizedBox(height: 16),

                // Sport and Level dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSport,
                        decoration: InputDecoration(
                          labelText: 'Sport',
                          filled: true,
                          fillColor: const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          filled: true,
                          fillColor: const Color(0xFFF5F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 16),

                // Max participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Max Participants',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => setState(() {
                            if (_maxParticipants > 1) _maxParticipants--;
                          }),
                        ),
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_maxParticipants',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _maxParticipants++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Public/Private toggle (only for personal events)
                if (widget.clubId == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Public Event', style: TextStyle(fontSize: 16)),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) => setState(() => _isPublic = value),
                          activeColor: Colors.black,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Update button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),                  onPressed: _isLoading || _isUploadingImage ? null : _updateEvent,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingImage ? 'Uploading Image...' : 'Updating Event...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Update Event',
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
