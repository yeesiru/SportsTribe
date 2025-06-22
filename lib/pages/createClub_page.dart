import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:map_project/pages/home_page.dart';

class CreateclubPage extends StatefulWidget {
  final int initialTabIndex;

  const CreateclubPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CreateclubPage> createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateclubPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedSport;
  String? _selectedSkillLevel;
  bool _isPrivate = false;
  File? _clubImage;
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

  Future<void> _createClub() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You need to be logged in to create a club')),
        );
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_clubImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('club_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_clubImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save club to Firestore
      await FirebaseFirestore.instance.collection('club').add({
        'name': _clubNameController.text.trim(),
        'sport': _selectedSport,
        'skillLevel': _selectedSkillLevel,
        'location': _locationController.text.trim(),
        'isPrivate': _isPrivate,
        'imageUrl': imageUrl,
        'creatorId': user.uid,
        'createdAt': Timestamp.now(),
        'members': [user.uid],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club created successfully!')),
      );

      // Navigate to home page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating club: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _clubImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _clubImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: const Color(0xFFD7F94A), // Bright yellow-green background
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.only(left: 40.0, top: 8.0),
                  child: Text(
                    'Create your club',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 40.0, top: 4.0),
                  child: Text(
                    'Set your club profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Club image selection area
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[200],
                          child: _clubImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _clubImage!,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey[700],
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _clubImage != null ? _removeImage : _pickImage,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _clubImage != null ? Icons.delete : Icons.edit,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Form container with white background and rounded corners
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            // Club name field
                            TextFormField(
                              controller: _clubNameController,
                              decoration: InputDecoration(
                                labelText: 'Club Name',
                                hintText: 'Enter club name',
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.sports_tennis,
                                    color: Colors.grey.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.black, width: 2),
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Sport',
                                prefixIcon: Icon(Icons.sports,
                                    color: Colors.grey.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.black, width: 2),
                                ),
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
                              decoration: InputDecoration(
                                labelText: 'Skill Level',
                                prefixIcon: Icon(Icons.trending_up,
                                    color: Colors.grey.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.black, width: 2),
                                ),
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

                            // Location field
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Location',
                                hintText: 'Enter club location',
                                hintStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.location_on,
                                    color: Colors.grey.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.black, width: 2),
                                ),
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

                            // Create button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _createClub,
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
                                        'Create',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
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
}
