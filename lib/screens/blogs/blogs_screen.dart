// lib/screens/blogs/blogs_screen.dart
import 'package:flutter/material.dart';

import '../../models/blogs.dart';
import '../../services/blogs_service.dart';
import 'blogs_detailed_screen.dart';


class BlogsScreen extends StatefulWidget {
  const BlogsScreen({Key? key}) : super(key: key);

  @override
  _BlogsScreenState createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final BlogService _blogService = BlogService();
  late Future<List<Blog>> _blogsFuture;
  String? _selectedCategory;
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  List<Blog> _blogs = [];

  final List<String> _categories = [
    'Travel',
    'Adventure',
    'Food',
    'Culture',
    'Tips',
    'Photography',
    'Nature',
    'City Life',
  ];

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs({bool refresh = false}) async {
    setState(() {
      if (refresh) {
        _currentPage = 1;
        _blogs = [];
        _hasMorePages = true;
      }
      _isLoading = true;
      _blogsFuture = _blogService.getBlogs(
        category: _selectedCategory,
        page: _currentPage,
      );
    });

    try {
      final newBlogs = await _blogsFuture;
      setState(() {
        if (newBlogs.isEmpty) {
          _hasMorePages = false;
        } else {
          _blogs.addAll(newBlogs);
          _currentPage++;
        }
      });
    } catch (e) {
      // Error handling in the FutureBuilder
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBlogs() async {
    await _loadBlogs(refresh: true);
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
      });
    } else {
      setState(() {
        _selectedCategory = category;
      });
    }
    _loadBlogs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Blogs'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _blogs.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blogs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No blogs available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshBlogs,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshBlogs,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoading &&
                      _hasMorePages &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                    _loadBlogs();
                    return true;
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blogs.length + (_hasMorePages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _blogs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final blog = _blogs[index];
                    return _buildBlogCard(blog);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _selectCategory(category),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme
                  .of(context)
                  .primaryColor
                  .withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme
                    .of(context)
                    .primaryColor
                    : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogCard(Blog blog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailScreen(blogId: blog.id!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16/9,
                child: blog.images.isNotEmpty
                    ? Image.network(
                  '${_blogService.baseUrl}${blog.images.first.url}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.article,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and date row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          blog.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        blog.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      blog.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Summary
                  Text(
                    blog.shortContent,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Author and stats
                  Row(
                    children: [
                      // Author
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Text(
                          blog.username.isNotEmpty ? blog.username[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        blog.username,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const Spacer(),

                      // Stats
                      Row(
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
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.comment,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${blog.comments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }}