import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/blogs.dart';

class BlogService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://10.0.2.2:8080';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';
  static const String _iosEmulatorUrl = 'http://localhost:8080';

  static String get baseUrl {
    if (Platform.isAndroid) {
      bool isEmulator = Platform.environment.containsKey('ANDROID_EMULATOR_IP');
      return isEmulator ? _androidEmulatorUrl : _physicalDeviceUrl;
    } else if (Platform.isIOS) {
      bool isSimulator = Platform.environment.containsKey('SIMULATOR_HOST');
      return isSimulator ? _iosEmulatorUrl : _physicalDeviceUrl;
    }
    return _physicalDeviceUrl;
  }

  static Future<List<Blog>> fetchBlogs() async {
    try {
      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        print('❌ Session token not found');
        throw Exception('Session token not found. Please log in.');
      }

      print('🌐 Fetching blogs from: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $sessionToken',
            'Cookie': 'session_token=$sessionToken',
          },
          extra: {'withCredentials': true},
          responseType: ResponseType.json, // Ensure proper JSON parsing
        ),
      );

      final response = await dio.get('/blogs');

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Handle both String and Map response types
        final Map<String, dynamic> data = _parseResponseData(response.data);

        if (data.containsKey('blogs')) {
          final List<dynamic> blogsList = data['blogs'] ?? [];
          final blogs = blogsList.map((json) => Blog.fromJson(json)).toList();

          print('✅ Successfully fetched ${blogs.length} blogs');
          return blogs;
        } else {
          print('⚠️ Unexpected response format: "blogs" key not found');
          throw Exception('Unexpected response format: "blogs" key not found.');
        }
      } else {
        print('⚠️ Failed to load blogs. Status: ${response.statusCode}');
        throw Exception('Failed to load blogs. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching blogs: $e');
      throw Exception('Failed to fetch blogs: $e');
    }
  }

  // Helper method to parse response data
  static Map<String, dynamic> _parseResponseData(dynamic responseData) {
    try {
      if (responseData is String) {
        return jsonDecode(responseData);
      } else if (responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        print('⚠️ Unexpected response data type: ${responseData.runtimeType}');
        throw Exception('Unexpected response data type');
      }
    } catch (e) {
      print('❌ Error parsing response data: $e');
      throw Exception('Error parsing response data: $e');
    }
  }

  static Future<void> printEnvironmentInfo() async {
    print('Current Base URL: $baseUrl');
    print('Platform: ${Platform.operatingSystem}');
    print('Is Physical Device: ${!Platform.environment.containsKey('ANDROID_EMULATOR_IP') && !Platform.environment.containsKey('SIMULATOR_HOST')}');
  }
}