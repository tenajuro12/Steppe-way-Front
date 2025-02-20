import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BlogService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080', // Change if necessary for mobile
    headers: {'Content-Type': 'application/json'},
  ));

  Future<Response> createBlog(Map<String, dynamic> blogData) async {
    final token = await _storage.read(key: 'session_token');
    if (token == null) {
      throw Exception("No session token found. User might not be logged in.");
    }

    // Attach the session token in the Cookie header.
    final response = await _dio.post(
      '/blogs',
      data: blogData,
      options: Options(
        headers: {
          'Cookie': 'session_token=$token',
        },
      ),
    );
    return response;
  }
}
