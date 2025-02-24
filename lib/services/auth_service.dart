import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://172.20.10.2:8080';
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

  Future<String?> login(String email, String password) async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
          },
          extra: {'withCredentials': true},
        ),
      );

      print('🌐 Attempting login to: ${dio.options.baseUrl}');

      final Response response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

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