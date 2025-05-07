import 'dart:io';
import 'package:dio/dio.dart';
import '../models/event.dart';

class EventService {
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

  static Future<Event> getEvent(int eventId) async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await dio.get('/events/$eventId');

      if (response.statusCode == 200) {
        return Event.fromJson(response.data);
      } else {
        throw Exception('Failed to load event. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }

  static Future<Event> fetchEventById(int eventId) async {
    try {
      print('🌐 Fetching event with ID: $eventId');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await dio.get('/events/$eventId');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Event.fromJson(response.data);
      } else {
        throw Exception('Failed to load event. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching event: $e');
      throw Exception('Error fetching event: $e');
    }
  }


  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      print('🌐 Fetching events from: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
        ),
      );

      final response = await dio.get('/events');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('events')) {
          final List<dynamic> eventsList = data['events'];
          final events = eventsList.map((json) => Event.fromJson(json)).toList();

          print('✅ Successfully fetched ${events.length} events');
          return events;
        } else {
          print('⚠️ Invalid response format: "events" key not found');
          throw Exception('Invalid response format: "events" key not found.');
        }
      } else {
        print('⚠️ Failed to load events. Status: ${response.statusCode}');
        throw Exception('Failed to load events. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching events: $e');
      throw Exception('Failed to fetch events: $e');
    }
  }

  static Future<void> printEnvironmentInfo() async {
    print('Current Base URL: $baseUrl');
    print('Platform: ${Platform.operatingSystem}');
    print('Is Physical Device: ${!Platform.environment.containsKey('ANDROID_EMULATOR_IP') && !Platform.environment.containsKey('SIMULATOR_HOST')}');
  }
}