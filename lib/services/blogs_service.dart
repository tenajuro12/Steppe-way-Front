import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/blogs.dart';

class BlogService {
  static const String baseUrl = 'http://localhost:8080';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<List<Blog>> fetchBlogs() async {
    try {
      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        throw Exception('Session token not found. Please log in.');
      }

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $sessionToken',
          },
          extra: {'withCredentials': true},
        ),
      );

      final response = await dio.get('/blogs');

      print('✅ Status Code: ${response.statusCode}');
      print('✅ Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Manually decode if response.data is a String
        final Map<String, dynamic> data = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>;

        if (data.containsKey('blogs')) {
          final List<dynamic> blogsList = data['blogs'] ?? [];
          return blogsList.map((json) => Blog.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected response format: "blogs" key not found.');
        }
      } else {
        throw Exception('Failed to load blogs. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching blogs: $e');
      throw Exception('Failed to fetch blogs');
    }
  }
}
