import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/attraction.dart';

class AttractionService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://172.20.10.2:8080';
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

  static Future<List<Attraction>> fetchAttractions() async {
    try {
      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        throw Exception('Session token not found');
      }

      print('🌐 Fetching attractions from: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $sessionToken',
            'Cookie': 'session_token=$sessionToken',
          },
          extra: {'withCredentials': true},
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

  static Future<void> printEnvironmentInfo() async {
    print('Current Base URL: $baseUrl');
    print('Platform: ${Platform.operatingSystem}');
    print('Is Physical Device: ${!Platform.environment.containsKey('ANDROID_EMULATOR_IP') && !Platform.environment.containsKey('SIMULATOR_HOST')}');
  }
}