// lib/models/blog.dart
import 'package:intl/intl.dart';

class Blog {
  final int? id;
  final String title;
  final String content;
  final int userId;
  final String username;
  final int likes;
  final String category;
  final DateTime createdAt;
  final List<BlogImage> images;
  final List<Comment> comments;

  Blog({
    this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.username,
    this.likes = 0,
    required this.category,
    DateTime? createdAt,
    this.images = const [],
    this.comments = const [],
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Blog.fromJson(Map<String, dynamic> json) {
    // Handle different possible date formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date string: $dateValue');
          return DateTime.now();
        }
      }

      return DateTime.now();
    }

    try {
      final id = json['ID'] ?? json['id'] ?? 0;
      final title = json['title'] ?? 'Untitled Blog';
      final content = json['content'] ?? '';
      final userId = json['user_id'] ?? 0;
      final username = json['username'] ?? 'Anonymous';
      final likes = json['likes'] ?? 0;
      final category = json['category'] ?? 'General';
      final createdAt = parseDate(json['CreatedAt'] ?? json['created_at']);

      List<BlogImage> imagesList = [];
      if (json['images'] != null && json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((imageJson) => BlogImage.fromJson(imageJson))
            .toList();
      }

      List<Comment> commentsList = [];
      if (json['comments'] != null && json['comments'] is List) {
        commentsList = (json['comments'] as List)
            .map((commentJson) => Comment.fromJson(commentJson))
            .toList();
      }

      return Blog(
        id: id,
        title: title,
        content: content,
        userId: userId,
        username: username,
        likes: likes,
        category: category,
        createdAt: createdAt,
        images: imagesList,
        comments: commentsList,
      );
    } catch (e) {
      print('Error creating Blog from JSON: $e');
      // Return a fallback blog object rather than crashing
      return Blog(
        id: 0,
        title: json['title'] ?? 'Error Parsing Blog',
        content: 'There was an error parsing this blog post.',
        userId: 0,
        username: 'System',
        category: 'Unknown',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'user_id': userId,
      'username': username,
      'category': category,
    };
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  String get shortContent {
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }
}

class BlogImage {
  final int? id;
  final int? blogId;
  final String url;

  BlogImage({
    this.id,
    this.blogId,
    required this.url,
  });

  factory BlogImage.fromJson(Map<String, dynamic> json) {
    try {
      return BlogImage(
        id: json['id'],
        blogId: json['blog_id'],
        url: json['url'] ?? '',
      );
    } catch (e) {
      print('Error parsing BlogImage: $e');
      return BlogImage(url: '');
    }
  }
}

class Comment {
  final int? id;
  final String content;
  final int blogId;
  final int userId;
  final String username;
  final DateTime createdAt;
  final List<CommentImage> images;

  Comment({
    this.id,
    required this.content,
    required this.blogId,
    required this.userId,
    required this.username,
    DateTime? createdAt,
    this.images = const [],
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Comment.fromJson(Map<String, dynamic> json) {
    print("Parsing comment JSON: ${json.keys}"); // Debug what keys are available

    try {
      // Check multiple possible ID field names
      final id = json['id'] ?? json['ID'] ?? json['comment_id'];
      print("Extracted comment ID: $id");

      return Comment(
        id: id,  // This might be null
        content: json['content'] ?? '',
        blogId: json['blog_id'] ?? 0,
        userId: json['user_id'] ?? 0,
        username: json['username'] ?? 'Unknown',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        images: json['images'] != null && json['images'] is List
            ? (json['images'] as List).map((x) => CommentImage.fromJson(x)).toList()
            : [],
      );
    } catch (e) {
      print('Error parsing Comment: $e');
      return Comment(
        content: 'Error parsing comment',
        blogId: 0,
        userId: 0,
        username: 'System',
      );
    }
  }
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'blog_id': blogId,
      'user_id': userId,
      'username': username,
    };
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
  }
}

class CommentImage {
  final int? id;
  final int? commentId;
  final String url;

  CommentImage({
    this.id,
    this.commentId,
    required this.url,
  });

  // Add this to your CommentImage.fromJson method
  factory CommentImage.fromJson(Map<String, dynamic> json) {
    print("Parsing CommentImage: $json");
    try {
      final url = json['url'] ?? '';
      print("Image URL: $url");

      return CommentImage(
        id: json['id'],
        commentId: json['comment_id'],
        url: url,
      );
    } catch (e) {
      print('Error parsing CommentImage: $e');
      return CommentImage(url: '');
    }
  }
}