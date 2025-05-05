import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReviewService {
  static final _storage = const FlutterSecureStorage();
  static const String _baseUrl = 'http://10.0.2.2:8080';

  static Future<void> submitReview({
    required int attractionId,
    required int rating,
    required String comment,
    File? imageFile,
  }) async {
    final token = await _storage.read(key: 'session_token');
    if (token == null) {
      throw Exception("User not authenticated. No session token.");
    }

    final Dio dio = Dio();
    final formData = FormData.fromMap({
      'attraction_id': attractionId.toString(),
      'rating': rating.toString(),
      'comment': comment,
      if (imageFile != null)
        'image': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
    });

    try {
      final response = await dio.post(
        '$_baseUrl/reviews',
        data: formData,
        options: Options(
          headers: {
            'Cookie': 'session_token=$token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        print('✅ Review submitted successfully');
      } else {
        print('⚠️ Failed to submit review: ${response.statusCode}');
        print(response.data);
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }
}
