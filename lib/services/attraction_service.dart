import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/attraction.dart';

class AttractionService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://192.168.88.65:8080';
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
  static Future<Attraction> getAttraction(int attractionId) async {
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
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      final response = await dio.get('/attractions/$attractionId');

      if (response.statusCode == 200) {
        return Attraction.fromJson(response.data);
      } else {
        throw Exception('Failed to load attraction. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attraction: $e');
    }
  }
  // In AttractionService
  static Future<Attraction> fetchAttractionById(int attractionId) async {
    try {
      print('🌐 Fetching attraction with ID: $attractionId');

      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        throw Exception('Session token not found. Please log in.');
      }

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      final response = await dio.get('/attractions/$attractionId');
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        // Try to parse as Attraction directly from the response data
        if (response.data is Map<String, dynamic>) {
          return Attraction.fromJson(response.data);
        } else if (response.data is String) {
          // If response is a string, try parsing it as JSON
          Map<String, dynamic> jsonData = json.decode(response.data);
          return Attraction.fromJson(jsonData);
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load attraction. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching attraction: $e');
      throw Exception('Error fetching attraction: $e');
    }
  }

  static Future<List<Attraction>> fetchAttractions() async {
    try {
      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        print('❌ Session token not found');
        throw Exception('Session token not found. Please log in.');
      }

      print('🌐 Fetching attractions from: $baseUrl with token: $sessionToken');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      final response = await dio.get('/attractions');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        if (responseData.containsKey('attractions')) {
          final List<dynamic> attractionsList = responseData['attractions'];
          final attractions = attractionsList
              .map((item) => Attraction.fromJson(item))
              .toList();

          print('✅ Successfully fetched ${attractions.length} attractions');
          return attractions;
        } else {
          print('⚠️ Invalid response format: "attractions" key not found');
          throw Exception('Invalid response format: "attractions" key not found.');
        }
      } else {
        print('⚠️ Failed to load attractions. Status: ${response.statusCode}');
        throw Exception('Failed to load attractions. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching attractions: $e');
      throw Exception('Error fetching attractions: $e');
    }
  }
}