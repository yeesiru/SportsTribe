import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventPage extends StatefulWidget {
  final String? clubId; // Pass the clubId when navigating to this page
  CreateEventPage({this.clubId});
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String content = '';
  int participants = 1;
  File? _eventImage;
  bool _isLoading = false;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    final ref = FirebaseStorage.instance
        .ref()
        .child('event_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.clubId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in or club not selected.')),
        );
        return;
      }
      String? imageUrl;
      if (_eventImage != null) {
        imageUrl = await _uploadImage(_eventImage!);
      }
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('events')
          .add({
        'content': content,
        'participants': participants,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event Created!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Event', style: TextStyle(color: Colors.black)),
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
                      children: [
                        Center(
                          child: _eventImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(_eventImage!,
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover),
                                )
                              : Icon(Icons.image,
                                  size: 70, color: Color(0xFF4A7AFF)),
                        ),
                        if (_eventImage != null)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _eventImage = null),
                              child: Icon(Icons.close,
                                  color: Colors.black, size: 28),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Content field
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Write your content..',
                    filled: true,
                    fillColor: Color(0xFFF5F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter content'
                      : null,
                  onSaved: (value) => content = value ?? '',
                ),
                SizedBox(height: 24),
                // Number of Participants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number of Participants',
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: 24),
                          onPressed: () {
                            setState(() {
                              if (participants > 1) participants--;
                            });
                          },
                        ),
                        Container(
                          width: 40,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$participants',
                              style: TextStyle(fontSize: 18)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 24),
                          onPressed: () {
                            setState(() {
                              participants++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32),
                // Post button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _createEvent,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Post',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
