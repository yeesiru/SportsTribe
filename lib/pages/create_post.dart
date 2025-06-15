import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  final String? clubId; // Pass the clubId when navigating to this page
  CreatePostPage({this.clubId});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  String content = '';
  File? _postImage;
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
          _postImage = File(picked.path);
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
        .child('post_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _createPost() async {
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
      if (_postImage != null) {
        imageUrl = await _uploadImage(_postImage!);
      }
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .add({
        'content': content,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post Created!')),
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
        title: Text('Create Post', style: TextStyle(color: Colors.black)),
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
                          child: _postImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(_postImage!,
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover),
                                )
                              : Icon(Icons.image,
                                  size: 70, color: Color(0xFF4A7AFF)),
                        ),
                        if (_postImage != null)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _postImage = null),
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
                    hintText: 'Write your posts..',
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
                  onPressed: _isLoading ? null : _createPost,
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
