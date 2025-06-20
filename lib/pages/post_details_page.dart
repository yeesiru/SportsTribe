import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:map_project/widgets/user_avatar.dart';
import 'package:map_project/services/user_service.dart';

class PostDetailsPage extends StatefulWidget {
  final String clubId;
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({
    Key? key,
    required this.clubId,
    required this.postId,
    required this.postData,
  }) : super(key: key);

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
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
  bool _isLoading = false;
  bool _isCommentLoading = false;
  bool _isEditing = false;
  bool _isPostLoading = false;
  Map<String, dynamic>? _clubData;
  Map<String, dynamic>? _authorData;
  final _editTitleController = TextEditingController();
  final _editContentController = TextEditingController();
  String? _editCategory;
  String? _editTags;
  Map<String, bool> _likedComments = {};
  Map<String, int> _commentLikes = {};
  Set<String> _editingComments = {};
  Map<String, TextEditingController> _commentEditControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchAdditionalData();
    _initializeEditControllers();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _editTitleController.dispose();
    _editContentController.dispose();
    super.dispose();
  }

  void _initializeEditControllers() {
    _editTitleController.text = widget.postData['title'] ?? '';
    _editContentController.text = widget.postData['content'] ?? '';
    _editCategory = widget.postData['category'];
    final tags = widget.postData['tags'] as List?;
    _editTags = tags?.join(', ') ?? '';
  }

  Future<void> _fetchAdditionalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch club data
      final clubDoc = await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .get();

      if (clubDoc.exists) {
        _clubData = clubDoc.data();
      }

      // Fetch author data
      final authorId = widget.postData['createdBy'] as String?;
      if (authorId != null) {
        final authorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authorId)
            .get();

        if (authorDoc.exists) {
          _authorData = authorDoc.data();
        }
      }
    } catch (e) {
      print('Error fetching additional data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId);

      final likes = List<String>.from(widget.postData['likes'] ?? []);
      final isLiked = likes.contains(user.uid);

      if (isLiked) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await postRef.update({
        'likes': likes,
        'likesCount': likes.length,
      });

      setState(() {
        widget.postData['likes'] = likes;
        widget.postData['likesCount'] = likes.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isCommentLoading = true;
    });

    try {
      final commentText = _commentController.text.trim();

      // Use a transaction to ensure atomic operations
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Add comment to subcollection
        final commentRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(); // This creates a new document reference

        // Get current post data to ensure we have the latest count
        final postRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('posts')
            .doc(widget.postId);

        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentCount = postDoc.data()?['commentsCount'] as int? ?? 0;
        final newCount = currentCount + 1;

        // Add the comment
        transaction.set(commentRef, {
          'text': commentText,
          'createdBy': user.uid,
          'createdAt': Timestamp.now(),
        });

        // Update the post's comment count
        transaction.update(postRef, {
          'commentsCount': newCount,
        });
        // Update local state
        setState(() {
          widget.postData['commentsCount'] = newCount;
        });
      });

      print(
          'Comment added successfully. New count: ${widget.postData['commentsCount']}'); // Debug log

      _commentController.clear();

      // Scroll to bottom to show new comment
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCommentLoading = false;
      });
    }
  }

  // Check if current user can edit/delete the post
  bool get _canEditPost {
    final authorId = widget.postData['createdBy'] as String?;
    final clubCreatorId = _clubData?['creatorId'] as String?;
    return user.uid == authorId || user.uid == clubCreatorId;
  }

  Future<void> _editPost() async {
    if (!_canEditPost) return;

    setState(() {
      _isPostLoading = true;
    });

    try {
      // Process tags
      List<String> tagsList = _editTags?.isNotEmpty == true
          ? _editTags!
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList()
          : [];

      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .update({
        'title': _editTitleController.text.trim(),
        'content': _editContentController.text.trim(),
        'category': _editCategory,
        'tags': tagsList,
        'updatedAt': Timestamp.now(),
      });

      // Update local data
      setState(() {
        widget.postData['title'] = _editTitleController.text.trim();
        widget.postData['content'] = _editContentController.text.trim();
        widget.postData['category'] = _editCategory;
        widget.postData['tags'] = tagsList;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPostLoading = false;
      });
    }
  }

  Future<void> _deletePost() async {
    if (!_canEditPost) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isPostLoading = true;
    });

    try {
      // Delete all comments first
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .get();

      for (final comment in commentsSnapshot.docs) {
        await comment.reference.delete();
      }

      // Delete the post
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPostLoading = false;
      });
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      final likes = List<String>.from(commentDoc.data()?['likes'] ?? []);
      final isLiked = likes.contains(user.uid);

      if (isLiked) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await commentRef.update({
        'likes': likes,
        'likesCount': likes.length,
      });

      setState(() {
        _likedComments[commentId] = !isLiked;
        _commentLikes[commentId] = likes.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating comment like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editComment(String commentId) async {
    final controller = _commentEditControllers[commentId];
    if (controller == null || controller.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'text': controller.text.trim(),
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      });

      setState(() {
        _editingComments.remove(commentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Comment'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Use a transaction to ensure atomic operations
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId);

        final postRef = FirebaseFirestore.instance
            .collection('club')
            .doc(widget.clubId)
            .collection('posts')
            .doc(widget.postId);

        // Get current post data to ensure we have the latest count
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentCount = postDoc.data()?['commentsCount'] as int? ?? 0;
        final newCount = math.max(0, currentCount - 1);

        // Delete the comment
        transaction.delete(commentRef);

        // Update the post's comment count
        transaction.update(postRef, {
          'commentsCount': newCount,
        });

        // Update local state
        setState(() {
          widget.postData['commentsCount'] = newCount;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting comment: $e'); // Debug logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPostHeader() {
    final createdAt = widget.postData['createdAt'] as Timestamp?;
    final isImportant = widget.postData['isImportant'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Club and author info
          Row(
            children: [
              // Club avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green[200],
                backgroundImage: _clubData?['imageUrl'] != null
                    ? NetworkImage(_clubData!['imageUrl'])
                    : null,
                child: _clubData?['imageUrl'] == null
                    ? Icon(Icons.sports_tennis,
                        color: Colors.green[800], size: 20)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clubData?['name'] ?? 'Unknown Club',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'by ${_authorData?['name'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatTimestamp(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), // More options
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      setState(() {
                        _isEditing = true;
                      });
                      break;
                    case 'delete':
                      _deletePost();
                      break;
                    case 'share':
                      _sharePost();
                      break;
                    case 'report':
                      _reportPost();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (_canEditPost) ...[
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Post'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Post',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Report', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          // Category and importance badges
          Row(
            children: [
              if (isImportant)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber[800]),
                      SizedBox(width: 4),
                      Text(
                        'Important',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              if (isImportant && widget.postData['category'] != null)
                SizedBox(width: 8),
              if (widget.postData['category'] != null &&
                  widget.postData['category'] != 'General')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.postData['category'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getCategoryColor(widget.postData['category']),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getCategoryIcon(widget.postData['category']),
                      SizedBox(width: 4),
                      Text(
                        widget.postData['category'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(widget.postData['category']),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    if (_isEditing) {
      return _buildEditForm();
    }

    final title = widget.postData['title'] as String?;
    final content = widget.postData['content'] as String? ?? '';
    final imageUrl = widget.postData['imageUrl'] as String?;
    final tags = widget.postData['tags'] as List?;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            SizedBox(height: 16),
          ],

          // Content
          if (content.isNotEmpty) ...[
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
          ],

          // Image
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD7F520),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey[400]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],

          // Tags
          if (tags != null && tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFD7F520).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '#${tag.toString()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit header
          Row(
            children: [
              Icon(Icons.edit, color: Color(0xFFD7F520), size: 20),
              SizedBox(width: 8),
              Text(
                'Edit Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initializeEditControllers(); // Reset to original values
                  });
                },
                child: Text('Cancel'),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Title field
          TextFormField(
            controller: _editTitleController,
            decoration: InputDecoration(
              labelText: 'Title',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _editCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _editCategory = newValue;
              });
            },
          ),
          SizedBox(height: 16),

          // Content field
          TextFormField(
            controller: _editContentController,
            decoration: InputDecoration(
              labelText: 'Content',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 5,
          ),
          SizedBox(height: 16),

          // Tags field
          TextFormField(
            initialValue: _editTags,
            decoration: InputDecoration(
              labelText: 'Tags (comma separated)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              _editTags = value;
            },
          ),
          SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isPostLoading ? null : _editPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD7F520),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isPostLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final likes = List<String>.from(widget.postData['likes'] ?? []);
    final isLiked = likes.contains(user.uid);
    final likesCount = widget.postData['likesCount'] as int? ?? 0;
    final commentsCount = widget.postData['commentsCount'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isLiked ? Colors.red[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLiked ? Colors.red : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isLiked ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    likesCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isLiked ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 12),

          // Comment count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  commentsCount.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // Share button
          GestureDetector(
            onTap: _sharePost,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Icon(
                Icons.share_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    final allowComments = widget.postData['allowComments'] as bool? ?? true;

    if (!allowComments) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.comments_disabled, color: Colors.grey[400]),
            SizedBox(width: 8),
            Text(
              'Comments are disabled for this post',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFD7F520)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'No comments yet. Be the first to comment!',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final comments = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Comments (${comments.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final commentData = comment.data() as Map<String, dynamic>;
                return _buildCommentItem(comment.id, commentData);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(String commentId, Map<String, dynamic> commentData) {
    final text = commentData['text'] as String? ?? '';
    final createdAt = commentData['createdAt'] as Timestamp?;
    final authorId = commentData['createdBy'] as String?;
    final isEdited = commentData['isEdited'] as bool? ?? false;
    final likes = List<String>.from(commentData['likes'] ?? []);
    final isLiked = likes.contains(user.uid);
    final likesCount = commentData['likesCount'] as int? ?? 0;

    final canEdit = user.uid == authorId || user.uid == _clubData?['creatorId'];
    final isEditingThis = _editingComments.contains(commentId);

    return FutureBuilder<DocumentSnapshot>(
      future: authorId != null
          ? FirebaseFirestore.instance.collection('users').doc(authorId).get()
          : null,
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final authorName = userData?['name'] ?? 'Unknown User';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author avatar
              UserAvatar(
                userData: userData,
                radius: 16,
              ),
              SizedBox(width: 12),
              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name, time, and actions
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatTimestamp(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isEdited) ...[
                          SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        Spacer(),
                        if (canEdit)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 16, color: Colors.grey[600]),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _commentEditControllers[commentId] =
                                      TextEditingController(text: text);
                                  setState(() {
                                    _editingComments.add(commentId);
                                  });
                                  break;
                                case 'delete':
                                  _deleteComment(commentId);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Comment text or edit field
                    if (isEditingThis) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentEditControllers[commentId],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(12),
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _editComment(commentId),
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _editingComments.remove(commentId);
                                    _commentEditControllers.remove(commentId);
                                  });
                                },
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Like button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleCommentLike(commentId),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color:
                                      isLiked ? Colors.red : Colors.grey[600],
                                ),
                                if (likesCount > 0) ...[
                                  SizedBox(width: 4),
                                  Text(
                                    likesCount.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLiked
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    final allowComments = widget.postData['allowComments'] as bool? ?? true;

    if (!allowComments) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User avatar with current user data
          StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getCurrentUserDataStream(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              return UserAvatar(
                userData: userData,
                radius: 16,
              );
            },
          ),
          SizedBox(width: 12),
          // Comment input
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Color(0xFFD7F520), width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isCommentLoading ? null : _addComment,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFD7F520),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isCommentLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      size: 20,
                      color: Colors.black,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Announcement':
        return Colors.red;
      case 'Discussion':
        return Colors.blue;
      case 'Question':
        return Colors.orange;
      case 'Achievement':
        return Colors.amber;
      case 'Event Recap':
        return Colors.purple;
      case 'Tips & Advice':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Announcement':
        return Icon(Icons.campaign, size: 12, color: Colors.red);
      case 'Discussion':
        return Icon(Icons.forum, size: 12, color: Colors.blue);
      case 'Question':
        return Icon(Icons.help_outline, size: 12, color: Colors.orange);
      case 'Achievement':
        return Icon(Icons.emoji_events, size: 12, color: Colors.amber);
      case 'Event Recap':
        return Icon(Icons.photo_library, size: 12, color: Colors.purple);
      case 'Tips & Advice':
        return Icon(Icons.lightbulb_outline,
            size: 12, color: Colors.yellow[700]);
      default:
        return Icon(Icons.label, size: 12, color: Colors.grey);
    }
  }

  void _sharePost() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _reportPost() {
    // TODO: Implement report functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Post'),
        content: Text('Are you sure you want to report this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Post reported. Thank you for your feedback.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPostData() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('club')
          .doc(widget.clubId)
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (postDoc.exists) {
        final freshData = postDoc.data()!;
        setState(() {
          // Update the comment count and other post data
          widget.postData['commentsCount'] = freshData['commentsCount'] ?? 0;
          widget.postData['likesCount'] = freshData['likesCount'] ?? 0;
          // Update other fields if needed
          widget.postData.addAll(freshData);
        });

        print(
            'Post data refreshed. Comment count: ${freshData['commentsCount']}'); // Debug log
      }
    } catch (e) {
      print('Error refreshing post data: $e');
    }
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
        ),
        title: Text(
          'Post Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug refresh button (can be removed in production)
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshPostData,
            tooltip: 'Refresh post data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFFD7F520)),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPostHeader(),
                          _buildPostContent(),
                          _buildActionBar(),
                          _buildCommentsList(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildCommentInput(),
              ],
            ),
    );
  }
}
