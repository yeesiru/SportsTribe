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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String title = '';
  String content = '';
  String category = 'General';
  String tags = '';
  File? _postImage;
  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _allowComments = true;
  bool _isImportant = false;

  static const int _maxContentLength = 1000;

  final List<String> _categories = [
    'General',
    'Announcement',
    'Discussion',
    'Question',
    'Achievement',
    'Event Recap',
    'Tips & Advice',
    'Equipment',
    'Training',
    'Match Results',
  ];

  Map<String, dynamic>? _clubData;
  bool _isLoadingClubData = true;

  @override
  void initState() {
    super.initState();
    _fetchClubData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _fetchClubData() async {
    if (widget.clubId == null) {
      setState(() {
        _isLoadingClubData = false;
      });
      return;
    }

    try {
      final clubDoc = await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .get();
      
      if (clubDoc.exists) {
        setState(() {
          _clubData = clubDoc.data();
          _isLoadingClubData = false;
        });
      } else {
        setState(() {
          _isLoadingClubData = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingClubData = false;
      });
      print('Error fetching club data: $e');
    }
  }

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
  }  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Additional validation for club selection
    if (widget.clubId == null || _clubData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No club selected. Please select a club to post to.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You must be logged in to create a post.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      String? imageUrl;
      if (_postImage != null) {
        imageUrl = await _uploadImage(_postImage!);
      }
      
      // Process tags
      List<String> tagsList = tags.isNotEmpty 
          ? tags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
          : [];

      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .add({
        'title': title,
        'content': content,
        'category': category,
        'tags': tagsList,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'allowComments': _allowComments,
        'isImportant': _isImportant,
        'likes': [],
        'likesCount': 0,
        'commentsCount': 0,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Post Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        if (category != 'General')
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFD7F520).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getCategoryIcon(category),
                                SizedBox(width: 4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (category != 'General') SizedBox(height: 12),
                        
                        // Title
                        if (_titleController.text.isNotEmpty) ...[
                          Text(
                            _titleController.text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        
                        // Content
                        if (_contentController.text.isNotEmpty) ...[
                          Text(
                            _contentController.text,
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 12),
                        ],
                        
                        // Image
                        if (_postImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _postImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        
                        // Tags
                        if (_tagsController.text.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _tagsController.text
                                .split(',')
                                .map((tag) => tag.trim())
                                .where((tag) => tag.isNotEmpty)
                                .map((tag) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                          SizedBox(height: 12),
                        ],
                        
                        // Settings indicators
                        Row(
                          children: [
                            if (_isImportant)
                              Icon(Icons.star, color: Colors.amber, size: 16),
                            if (_isImportant) SizedBox(width: 4),
                            Icon(
                              _allowComments ? Icons.comment : Icons.comments_disabled,
                              color: Colors.grey,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _allowComments ? 'Comments enabled' : 'Comments disabled',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _saveDraft() {
    // This could be expanded to save to local storage or database
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft saved locally'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-save draft every few seconds when user is typing
    // This is a basic implementation - in production, you'd use proper debouncing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFD7F520),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Post',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_clubData != null)
              Text(
                'in ${_clubData!['name'] ?? 'Unknown Club'}',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,actions: [
          IconButton(
            onPressed: () => _saveDraft(),
            icon: Icon(Icons.save_alt, color: Colors.black),
            tooltip: 'Save Draft',
          ),
          IconButton(
            onPressed: () => _showPreview(),
            icon: Icon(Icons.preview, color: Colors.black),
            tooltip: 'Preview Post',
          ),
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              'POST',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [                // Club Info Banner
                if (_isLoadingClubData)
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          child: CircularProgressIndicator(
                            color: Color(0xFFD7F520),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Loading club information...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_clubData != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFD7F520),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Color(0xFFD7F520),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Posting to:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green[200],
                              backgroundImage: _clubData!['imageUrl'] != null
                                  ? NetworkImage(_clubData!['imageUrl'])
                                  : null,
                              child: _clubData!['imageUrl'] == null
                                  ? Icon(
                                      Icons.sports_tennis,
                                      color: Colors.green[800],
                                      size: 20,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _clubData!['name'] ?? 'Unknown Club',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (_clubData!['isPrivate'] ?? false) 
                                              ? Colors.red[100] 
                                              : Colors.green[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (_clubData!['isPrivate'] ?? false) ? 'Private' : 'Public',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: (_clubData!['isPrivate'] ?? false) 
                                                ? Colors.red 
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.sports, size: 12, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        '${_clubData!['sport'] ?? 'Sport'} • ${_clubData!['skillLevel'] ?? 'All Levels'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.group, size: 12, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        '${(_clubData!['members'] as List?)?.length ?? 0} members',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Club information not available. Please make sure you selected a valid club.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Post Title Section
                _buildSectionCard(
                  title: 'Post Title',
                  icon: Icons.title,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter an engaging title for your post...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFD7F520), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a title'
                        : null,
                    onSaved: (value) => title = value ?? '',
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Category Selection
                _buildSectionCard(
                  title: 'Category',
                  icon: Icons.category,
                  child: DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFD7F520), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            _getCategoryIcon(cat),
                            SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        category = newValue!;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: 16),
                  // Post Content Section
                _buildSectionCard(
                  title: 'Content',
                  icon: Icons.article,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind? Share your thoughts, experiences, or questions with the community...',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFD7F520), width: 2),
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        maxLines: 6,
                        maxLength: _maxContentLength,
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild for character counter
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          if (value.length > _maxContentLength) {
                            return 'Content must be less than $_maxContentLength characters';
                          }
                          return null;
                        },
                        onSaved: (value) => content = value ?? '',
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_contentController.text.length}/$_maxContentLength characters',
                        style: TextStyle(
                          color: _contentController.text.length > _maxContentLength * 0.9
                              ? Colors.red
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Image Upload Section
                _buildSectionCard(
                  title: 'Add Image (Optional)',
                  icon: Icons.image,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: _postImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _postImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to add an image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG up to 10MB',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (_postImage != null)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _postImage = null),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (_isPickingImage)
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD7F520),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Tags Section
                _buildSectionCard(
                  title: 'Tags (Optional)',
                  icon: Icons.tag,
                  child: TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      hintText: 'Add tags separated by commas, e.g., tennis, beginner, tips',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFD7F520), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.tag, color: Colors.grey[600]),
                    ),
                    onSaved: (value) => tags = value ?? '',
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Post Settings
                _buildSectionCard(
                  title: 'Post Settings',
                  icon: Icons.settings,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Allow Comments'),
                        subtitle: Text('Let members comment on this post'),
                        value: _allowComments,
                        activeColor: Color(0xFFD7F520),
                        onChanged: (bool value) {
                          setState(() {
                            _allowComments = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: Text('Mark as Important'),
                        subtitle: Text('Highlight this post for better visibility'),
                        value: _isImportant,
                        activeColor: Color(0xFFD7F520),
                        onChanged: (bool value) {
                          setState(() {
                            _isImportant = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Create Post Button
                Container(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD7F520),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _createPost,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating Post...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Create Post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFD7F520), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'Announcement':
        return Icon(Icons.campaign, color: Colors.red, size: 16);
      case 'Discussion':
        return Icon(Icons.forum, color: Colors.blue, size: 16);
      case 'Question':
        return Icon(Icons.help, color: Colors.orange, size: 16);
      case 'Achievement':
        return Icon(Icons.emoji_events, color: Colors.amber, size: 16);
      case 'Event Recap':
        return Icon(Icons.event_note, color: Colors.purple, size: 16);
      case 'Tips & Advice':
        return Icon(Icons.lightbulb, color: Colors.yellow[700]!, size: 16);
      case 'Equipment':
        return Icon(Icons.sports_tennis, color: Colors.brown, size: 16);
      case 'Training':
        return Icon(Icons.fitness_center, color: Colors.green, size: 16);
      case 'Match Results':
        return Icon(Icons.scoreboard, color: Colors.indigo, size: 16);
      default:
        return Icon(Icons.article, color: Colors.grey, size: 16);
    }
  }
}
