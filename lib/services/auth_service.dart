import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String baseUrl = 'http://localhost:8080';

  Future<String?> login(String email, String password) async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
          },
          extra: {'withCredentials': true}, // Required for web-based cookie handling
        ),
      );

      final Response response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      // Ensure session token is treated as a string
      final String? sessionToken = response.data['session_token']?.toString();

      if (sessionToken != null && sessionToken.isNotEmpty) {
        await _storage.write(key: 'session_token', value: sessionToken);
        print('✅ Session Token Saved: $sessionToken');
        return sessionToken;
      } else {
        print('⚠️ No session token found in response data.');
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }


Future<bool> register(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Headers: ${response.headers}');
      print('Registration Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Registration successful');
        return true;
      } else {
        print('Registration failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}
