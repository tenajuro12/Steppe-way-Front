import 'package:dio/dio.dart';
import '../models/event.dart';

class EventService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await dio.get('/events');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('events')) {
          final List<dynamic> eventsList = data['events'];
          return eventsList.map((json) => Event.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format: "events" key not found.');
        }
      } else {
        throw Exception('Failed to load events. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching events: $e');
      throw Exception('Failed to fetch events');
    }
  }
}
