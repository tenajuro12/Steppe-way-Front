// lib/screens/blogs/blog_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/blogs.dart';
import '../../services/blogs_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final int blogId;

  const BlogDetailScreen({Key? key, required this.blogId}) : super(key: key);

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogService _blogService = BlogService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Future<Blog> _blogFuture;
  bool _isLoading = false;
  bool _isLiking = false;
  bool _isCommenting = false;
  int? _userId;
  String? _username;

  final TextEditingController _commentController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  Comment? _editingComment;

  @override
  void initState() {
    super.initState();
    _loadBlog();
    _getUserInfo();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    final userId = await _storage.read(key: 'user_id');
    final username = await _storage.read(key: 'username');
    if (userId != null && username != null) {
      setState(() {
        _userId = int.parse(userId);
        _username = username;
      });
    }
  }

  Future<void> _loadBlog() async {
    setState(() {
      _isLoading = true;
      _blogFuture = _blogService.getBlogDetails(widget.blogId);
    });

    try {
      await _blogFuture;
    } catch (e) {} finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(Blog blog) async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      await _blogService.likeBlog(blog.id!);
      _loadBlog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
            pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _addComment(int blogId) async {
    if (_commentController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() {
      _isCommenting = true;
    });

    try {
      print("Selected images count: ${_selectedImages.length}");
      for (var i = 0; i < _selectedImages.length; i++) {
        print("Image path ${i + 1}: ${_selectedImages[i].path}");
      }

      if (_editingComment != null) {
        // Make sure we have an ID and the user is the comment's author
        if (_editingComment!.id == null) {
          throw Exception('Cannot update comment: Invalid comment ID');
        }

        if (_editingComment!.userId != _userId) {
          throw Exception('You can only edit your own comments');
        }

        await _blogService.updateComment(
          _editingComment!.id!,
          _commentController.text.trim(),
          images: _selectedImages,
        );
      } else {
        // Create a new comment
        await _blogService.addComment(
          blogId,
          _commentController.text.trim(),
          images: _selectedImages,
        );
      }

      // Clear form and reload
      _commentController.clear();
      setState(() {
        _selectedImages.clear();
        _editingComment = null;
      });
      _loadBlog();
    } catch (e) {
      print("Error adding/updating comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isCommenting = false;
      });
    }
  }

  void _startEditingComment(Comment comment) {
    print("Starting to edit comment: ${comment.id}");

    if (comment.id == null) {
      print("Error: Cannot edit comment with null ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit this comment - missing ID')),
      );
      return;
    }

    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
    });
  }

  Future<void> _deleteComment(Comment comment) async {
    print("DEBUG: Comment object: ${comment.toJson()}");

    // Check if we have a valid ID
    if (comment.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Missing comment ID')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
                'Are you sure you want to delete this comment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Print the exact URL and method being called
        print("Calling delete for comment ID: ${comment.id}");

        await _blogService.deleteComment(comment.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully')),
        );

        // Reload the comments
        _loadBlog();
      } catch (e) {
        print("ERROR: Failed to delete comment: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e')),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
      _selectedImages.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Blog>(
        future: _blogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBlog,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Blog not found'));
          }

          final blog = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (blog.images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: blog.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          '${_blogService.baseUrl}${blog.images[index].url}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              blog.category,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Theme
                                .of(context)
                                .primaryColor
                                .withOpacity(0.1),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap,
                          ),
                          Text(
                            blog.formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        blog.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme
                                .of(context)
                                .primaryColor
                                .withOpacity(0.2),
                            child: Text(
                              blog.username.isNotEmpty ? blog.username[0]
                                  .toUpperCase() : '?',
                              style: TextStyle(
                                color: Theme
                                    .of(context)
                                    .primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'By ${blog.username}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _userId != null
                                ? () => _toggleLike(blog)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${blog.likes}',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        blog.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Comments (${blog.comments.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _userId != null
                          ? _buildCommentForm(blog.id!)
                          : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Please log in to comment',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: blog.comments.length,
                        itemBuilder: (context, index) {
                          final comment = blog.comments[index];
                          return _buildCommentCard(comment);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentForm(int blogId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingComment != null ? 'Edit Comment' : 'Add a Comment',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Write your comment...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo),
              label: const Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
            const Spacer(),
            if (_editingComment != null)
              TextButton(
                onPressed: _cancelEditing,
                child: const Text('CANCEL'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isCommenting ? null : () => _addComment(blogId),
              style: ElevatedButton.styleFrom(
                backgroundColor: _editingComment != null ? Colors.blue : Theme
                    .of(context)
                    .primaryColor,
              ),
              child: _isCommenting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(_editingComment != null ? 'UPDATE' : 'COMMENT'),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateComment(Comment comment, String content,
      {List<File>? images}) async {
    if (comment.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot update comment: Invalid comment ID')),
      );
      return;
    }

    try {
      await _blogService.updateComment(
        comment.id!, // Use ! after null check
        content,
        images: images,
      );

      // Clear form and reload
      _commentController.clear();
      setState(() {
        _selectedImages.clear();
        _editingComment = null;
      });
      _loadBlog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating comment: $e')),
      );
    }
  }

  Widget _buildCommentCard(Comment comment) {
    // Debug logs
    print("Rendering comment card for ID: ${comment.id}, userID: ${comment
        .userId}");
    print("Current user ID: $_userId");

    final isAuthor = _userId != null && comment.userId == _userId;
    print("Is author: $isAuthor");

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────────────────────────────────────────────────────  Header row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme
                      .of(context)
                      .primaryColor
                      .withOpacity(0.2),
                  child: Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme
                          .of(context)
                          .primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Username + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      comment.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Actions for the author
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) =>
                            SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Edit Comment'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _startEditingComment(comment);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                        Icons.delete, color: Colors.red),
                                    title: const Text(
                                      'Delete Comment',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (comment.id != null) {
                                        _deleteComment(comment); // Just pass the ID, no casting
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ──────────────────────────────────────────────────────────  Comment body
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),

            // ──────────────────────────────────────────────────────────  Images
            if (comment.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text("Images (${comment.images.length}):",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: comment.images.length,
                  itemBuilder: (context, index) {
                    // Using localhost version instead of baseUrl
                    final imageUrl = 'http://localhost:8080${comment.images[index].url}';
                    print("Comment image URL ($index): $imageUrl");
                    print("Comment ${comment.id} has ${comment.images.length} images to display");

                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Error loading image $imageUrl: $error");
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.red),
                                  Text("Cannot load image", style: TextStyle(fontSize: 12)),
                                  Text(imageUrl.split('/').last, style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}