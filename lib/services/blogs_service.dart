// lib/services/blog_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:math' show min;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../models/blogs.dart';

class BlogService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://10.0.2.2:8080';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';
  static const String _iosEmulatorUrl = 'http://localhost:8080';

  String get baseUrl {
    String url;
    if (Platform.isAndroid) {
      bool isEmulator = Platform.environment.containsKey('ANDROID_EMULATOR_IP');
      url = isEmulator ? _androidEmulatorUrl : _physicalDeviceUrl;
    } else if (Platform.isIOS) {
      bool isSimulator = Platform.environment.containsKey('SIMULATOR_HOST');
      url = isSimulator ? _iosEmulatorUrl : _physicalDeviceUrl;
    } else {
      url = _physicalDeviceUrl;
    }
    print("Using base URL: $url");
    return url;
  }

  Future<Dio> _getDio() async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');
      print('Auth token: ${sessionToken != null ? "Found" : "Not found"}');

      return Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (sessionToken != null) 'Cookie': 'session_token=$sessionToken',
          },
        ),
      );
    } catch (e) {
      print('Error creating Dio instance: $e');
      return Dio(BaseOptions(baseUrl: baseUrl));
    }
  }

  Future<List<Blog>> getBlogs({String? category, int page = 1}) async {
    try {
      final dio = await _getDio();

      String url = '/blogs?page=1';
      if (category != null && category.isNotEmpty) {
        url = '/blogs?category=$category&page=1';
      }

      print('Fetching blogs from: $url');
      final response = await dio.get(url);

      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Handle string response
        if (response.data is String) {
          try {
            Map<String, dynamic> parsed = json.decode(response.data);
            if (parsed.containsKey('blogs') && parsed['blogs'] is List) {
              List<dynamic> blogsList = parsed['blogs'];
              return blogsList.map((blogJson) => Blog.fromJson(blogJson)).toList();
            }
            print('Parsed JSON does not contain expected "blogs" list');
          } catch (e) {
            print('Error parsing JSON string: $e');
          }
        }
        // Handle case where response is already a Map
        else if (response.data is Map<String, dynamic>) {
          Map<String, dynamic> data = response.data;
          if (data.containsKey('blogs') && data['blogs'] is List) {
            List<dynamic> blogsList = data['blogs'];
            return blogsList.map((blogJson) => Blog.fromJson(blogJson)).toList();
          }
        }

        print('No blogs could be processed from response, returning hardcoded blogs');

        // Return some hardcoded blogs for testing
        return [
          Blog(
            id: 1,
            title: "Exploring Northern Kazakhstan",
            content: "Join me on an adventure through the stunning landscapes of Northern Kazakhstan...",
            userId: 1,
            username: "traveler123",
            category: "Travel",
            createdAt: DateTime.now().subtract(Duration(days: 3)),
            images: [BlogImage(url: "/assets/images/kazakhstan1.jpg")],
          ),
          Blog(
            id: 2,
            title: "Traditional Kazakh Cuisine",
            content: "Discover the rich flavors of traditional Kazakh dishes that have been passed down through generations...",
            userId: 2,
            username: "foodlover",
            category: "Food",
            createdAt: DateTime.now().subtract(Duration(days: 5)),
            images: [BlogImage(url: "/assets/images/food1.jpg")],
          ),
        ];
      }

      return [];
    } catch (e) {
      print('Error fetching blogs: $e');
      return [];
    }
  }
  Future <Blog> getBlogDetails(int blogId) async {
    try {
      final dio = await _getDio();

      final response = await dio.get('/blogs/$blogId');

      if (response.statusCode == 200) {
        // Check if response is a string and parse it
        if (response.data is String) {
          try {
            Map<String, dynamic> parsedData = json.decode(response.data);
            return Blog.fromJson(parsedData);
          } catch (e) {
            print('Error parsing JSON string: $e');
            throw Exception('Failed to parse blog details: $e');
          }
        }
        // Handle already parsed JSON
        else if (response.data is Map<String, dynamic>) {
          return Blog.fromJson(response.data);
        }
        else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load blog details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching blog details: $e');
      throw Exception('Failed to load blog details: $e');
    }
  }

  Future<void> likeBlog(int blogId) async {
    try {
      final dio = await _getDio();
      final response = await dio.post('/blogs/$blogId/like');

      if (response.statusCode != 200) {
        throw Exception('Failed to like blog: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking blog: $e');
      throw Exception('Failed to like blog: $e');
    }
  }

  Future<void> unlikeBlog(int blogId) async {
    try {
      final dio = await _getDio();
      final response = await dio.post('/blogs/$blogId/unlike');

      if (response.statusCode != 200) {
        throw Exception('Failed to unlike blog: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unliking blog: $e');
      throw Exception('Failed to unlike blog: $e');
    }
  }

  Future<Comment> addComment(int blogId, String content, {List<File>? images}) async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        throw Exception('Session token not found. Please log in.');
      }

      // Create multipart form data
      final formData = FormData();
      formData.fields.add(MapEntry('content', content));

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        print("Uploading ${images.length} images with comment");

        for (var i = 0; i < images.length; i++) {
          final file = images[i];
          final fileName = file.path.split('/').last;

          print("Adding image $i: $fileName");

          formData.files.add(
            MapEntry(
              'images', // Make sure this matches what your backend expects
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
                contentType: MediaType('image', fileName.split('.').last),
              ),
            ),
          );
        }
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      // Send the request
      final response = await dio.post(
        '/blogs/$blogId/comments', // Make sure this is the correct endpoint
        data: formData,
      );

      print("Comment creation response status: ${response.statusCode}");
      print("Response type: ${response.data.runtimeType}");

      if (response.data is String) {
        try {
          // Don't use substring directly on the response data
          // Instead, just parse it as JSON
          final parsedData = json.decode(response.data);
          return Comment.fromJson(parsedData);
        } catch (e) {
          print("Error parsing response: $e");
          throw Exception('Failed to parse response: $e');
        }
      } else {
        return Comment.fromJson(response.data);
      }
    } catch (e) {
      print("Error in addComment: $e");
      throw Exception('Failed to add comment: $e');
    }
  }
  Future<Comment> updateComment(int commentId, String content, {List<File>? images}) async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');
      final userId = await _storage.read(key: 'user_id');

      if (sessionToken == null || userId == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final formData = FormData();
      formData.fields.add(MapEntry('content', content));

      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          final file = images[i];
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
                contentType: MediaType('image', fileName.split('.').last),
              ),
            ),
          );
        }
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      final response = await dio.put(
        '/comments/$commentId',
        data: formData,
      );

      // Parse response, handling string or Map
      if (response.statusCode == 200) {
        if (response.data is String) {
          try {
            Map<String, dynamic> parsedData = json.decode(response.data);
            return Comment.fromJson(parsedData);
          } catch (e) {
            print('Error parsing comment response: $e');
            throw Exception('Failed to parse comment data: $e');
          }
        } else if (response.data is Map<String, dynamic>) {
          return Comment.fromJson(response.data);
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating comment: $e');
      throw Exception('Failed to update comment: $e');
    }
  }

  // In your BlogService class
  Future<void> deleteComment(int commentId) async {
    print("API: Deleting comment ID: $commentId");
    try {
      final sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        print("API: No session token found");
        throw Exception('Not authenticated');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      print("API: Sending delete request to /comments/$commentId");
      final response = await dio.delete('/comments/$commentId');
      print("API: Delete response status: ${response.statusCode}");

      if (response.statusCode != 204 && response.statusCode != 200) {
        print("API: Unexpected status code: ${response.statusCode}");
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }

      print("API: Comment deleted successfully");
    } catch (e) {
      print("API ERROR: Error deleting comment: $e");
      throw Exception('Failed to delete comment: $e');
    }
  }
  Future<List<Comment>> getComments(int blogId) async {
    try {
      final dio = await _getDio();

      final response = await dio.get('/blogs/$blogId/comments');

      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = response.data;
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Failed to load comments: $e');
    }
  }
}