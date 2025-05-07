import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/user_profile.dart';

class ProfileService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _physicalDeviceUrl = 'http://192.168.88.65:8080';
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

  Future<UserProfile> fetchUserProfile(int userId) async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');

      final response = await _dio.get(
        '$baseUrl/user/profiles/$userId',
        options: Options(
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
          validateStatus: (status) => status! < 500, // Don't throw on 4xx errors
        ),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Profile not found, create a new one
        return await createInitialProfile(userId);
      } else {
        throw Exception('Failed to load profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      throw Exception('Network error');
    }
  }

  Future<UserProfile> createInitialProfile(int userId) async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');

      // Get username from secure storage if available
      final username = await _storage.read(key: 'username') ?? 'User $userId';

      // Create a minimal profile with default values
      final data = {
        'username': username,
        'email': '',  // Leave blank or get from storage
        'bio': 'Tell us about yourself'  // Default placeholder
      };

      final response = await _dio.post(
        '$baseUrl/user/profiles',  // Endpoint to create profile
        data: data,
        options: Options(
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Failed to create profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating profile: $e');
      throw Exception('Failed to create initial profile');
    }
  }

  Future<UserProfile> updateProfile({
    required int userId,
    String? username,
    String? email,
    String? bio,
    File? profileImage,
  }) async {
    try {
      final sessionToken = await _storage.read(key: 'session_token');

      FormData formData = FormData();

      if (username != null) formData.fields.add(MapEntry('username', username));
      if (email != null) formData.fields.add(MapEntry('email', email));
      if (bio != null) formData.fields.add(MapEntry('bio', bio));

      if (profileImage != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            profileImage.path,
            filename: profileImage.path.split('/').last,
          ),
        ));
      }

      final response = await _dio.patch(
        '$baseUrl/user/profiles/$userId',
        data: formData,
        options: Options(
          headers: {
            'Cookie': 'session_token=$sessionToken',
          },
        ),
      );
      print('Attempting to fetch profile for user ID: $userId');
      print('Using URL: $baseUrl/user/profiles/$userId');
      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Network error');
    }
  }
}