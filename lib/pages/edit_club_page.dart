import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditClubPage extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic> clubData;

  const EditClubPage({
    Key? key,
    required this.clubId,
    required this.clubData,
  }) : super(key: key);

  @override
  State<EditClubPage> createState() => _EditClubPageState();
}

class _EditClubPageState extends State<EditClubPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clubNameController;
  late TextEditingController _locationController;
  String? _selectedSport;
  String? _selectedSkillLevel;
  bool _isPrivate = false;
  String? _currentImageUrl;
  File? _newClubImage;
  bool _isLoading = false;

  final List<String> _sports = [
    "Badminton",
    "Tennis",
    "Pickleball",
    "Basketball",
  ];

  final List<String> _skillLevels = [
    "Beginner",
    "Intermediate",
    "Advanced",
    "All skills level"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _clubNameController = TextEditingController(text: widget.clubData['name']);
    _locationController = TextEditingController(text: widget.clubData['location']);
    _selectedSport = widget.clubData['sport'];
    _selectedSkillLevel = widget.clubData['skillLevel'];
    _isPrivate = widget.clubData['isPrivate'] ?? false;
    _currentImageUrl = widget.clubData['imageUrl'];
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _newClubImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _newClubImage = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _updateClub() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _currentImageUrl;

      // If a new image was selected, upload it
      if (_newClubImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('club_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_newClubImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Update club data in Firestore
      await FirebaseFirestore.instance.collection('club').doc(widget.clubId).update({
        'name': _clubNameController.text.trim(),
        'sport': _selectedSport,
        'skillLevel': _selectedSkillLevel,
        'location': _locationController.text.trim(),
        'isPrivate': _isPrivate,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating club: $e')),
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
      backgroundColor: const Color(0xFFD7F520),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Club',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Club image selection
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _newClubImage != null
                          ? FileImage(_newClubImage!)
                          : (_currentImageUrl != null
                              ? NetworkImage(_currentImageUrl!)
                              : null) as ImageProvider?,
                      child: (_newClubImage == null && _currentImageUrl == null)
                          ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey[700],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: (_newClubImage != null || _currentImageUrl != null)
                          ? _removeImage
                          : _pickImage,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (_newClubImage != null || _currentImageUrl != null)
                              ? Icons.delete
                              : Icons.edit,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Form
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _clubNameController,
                          decoration: const InputDecoration(
                            labelText: 'Club Name',
                            prefixIcon: Icon(Icons.sports_tennis),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a club name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Sports dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedSport,
                          decoration: const InputDecoration(
                            labelText: 'Sport',
                            prefixIcon: Icon(Icons.sports),
                          ),
                          items: _sports.map((String sport) {
                            return DropdownMenuItem<String>(
                              value: sport,
                              child: Text(sport),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSport = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a sport';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Skill level dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedSkillLevel,
                          decoration: const InputDecoration(
                            labelText: 'Skill Level',
                            prefixIcon: Icon(Icons.grade),
                          ),
                          items: _skillLevels.map((String level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSkillLevel = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a skill level';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Private toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.grey.shade400),
                              const SizedBox(width: 15),
                              const Text(
                                'Set as private',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isPrivate,
                                onChanged: (value) {
                                  setState(() => _isPrivate = value);
                                },
                                activeColor: Colors.black,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Update button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateClub,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Update Club',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
    );
  }
}
