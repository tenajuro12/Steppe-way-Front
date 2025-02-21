import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/attraction.dart';

class AttractionService {
  static const String baseUrl = 'http://localhost:8080';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<List<Attraction>> fetchAttractions() async {
    try {
      final String? sessionToken = await _storage.read(key: 'session_token');
      if (sessionToken == null) {
        throw Exception('Session token not found');
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

      final response = await dio.get('/attractions');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        if (responseData.containsKey('attractions')) {
          final List<dynamic> attractionsList = responseData['attractions'];
          return attractionsList.map((item) => Attraction.fromJson(item)).toList();
        } else {
          throw Exception('Invalid response format: "attractions" key not found.');
        }
      } else {
        throw Exception('Failed to load attractions. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching attractions: $e');
      throw Exception('Error fetching attractions');
    }
  }
}