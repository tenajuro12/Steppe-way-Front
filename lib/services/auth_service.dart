import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://192.168.1.71:8080';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';
  static const String _iosEmulatorUrl = 'http://localhost:8080';

  String get baseUrl {
    if (Platform.isAndroid) {
      bool isEmulator = Platform.environment.containsKey('ANDROID_EMULATOR_IP');
      return isEmulator ? _androidEmulatorUrl : _physicalDeviceUrl;
    } else if (Platform.isIOS) {
      bool isSimulator = Platform.environment.containsKey('SIMULATOR_HOST');
      return isSimulator ? _iosEmulatorUrl : _physicalDeviceUrl;
    }
    return _physicalDeviceUrl;
  }

  Future<bool> login(String email, String password) async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
          },
          receiveDataWhenStatusError: true,
        ),
      );

      print('🌐 Attempting login to: ${dio.options.baseUrl}');

      final Response response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Extract the session token from cookies
        String? sessionCookie;
        response.headers.forEach((name, values) {
          if (name.toLowerCase() == 'set-cookie') {
            for (var value in values) {
              if (value.contains('session_token=')) {
                sessionCookie = value;
                // Extract just the token part
                final RegExp regex = RegExp(r'session_token=([^;]+)');
                final match = regex.firstMatch(value);
                if (match != null && match.groupCount >= 1) {
                  final token = match.group(1);
                  if (token != null) {
                    _storage.write(key: 'session_token', value: token);
                    print('✅ Session token extracted and saved: $token');
                  }
                }
              }
            }
          }
        });

        if (sessionCookie == null) {
          // If we couldn't extract from cookies, store a placeholder for test purposes
          // This is just for debugging - in production, you'd want to fail if no token is found
          await _storage.write(key: 'session_token', value: 'dummy_token_for_testing');
          print('⚠️ No session cookie found, using dummy token for testing');
        }

        return true;
      } else {
        print('⚠️ Login failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }
  Future<bool> register(String email, String password, String username) async {
    try {
      print('🌐 Attempting registration to: $baseUrl');

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
        print('✅ Registration successful');
        return true;
      } else {
        print('⚠️ Registration failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return false;
    }
  }

  // Optional: Method to check current environment
  Future<void> printEnvironmentInfo() async {
    print('Current Base URL: $baseUrl');
    print('Platform: ${Platform.operatingSystem}');
    print('Is Physical Device: ${!Platform.environment.containsKey('ANDROID_EMULATOR_IP') && !Platform.environment.containsKey('SIMULATOR_HOST')}');
  }
}