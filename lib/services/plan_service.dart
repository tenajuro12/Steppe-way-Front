// lib/services/plan_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';


class PlanService {
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

  static Future<Map<String, String>> _getHeaders() async {
    final userId = await _storage.read(key: 'user_id');
    final sessionToken = await _storage.read(key: 'session_token');

    if (sessionToken == null) {
      print('❌ Session token not found');
      throw Exception('Session token not found. Please log in.');
    }

    return {
      'Content-Type': 'application/json',
      'X-User-ID': userId ?? '',
      'Cookie': 'session_token=$sessionToken',
    };
  }

  // Get all plans for the current user
  static Future<List<Plan>> getUserPlans() async {
    try {
      final headers = await _getHeaders();
      // Use the correct endpoint path with /api prefix
      print('🌐 Fetching user plans from: $baseUrl/api/plans');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.get('/api/plans');
      print('📡 Response Status: ${response.statusCode}');
      print('Raw response data: ${response.data}');


      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final plans = data.map((json) => Plan.fromJson(json)).toList();
        print('✅ Successfully fetched ${plans.length} plans');
        return plans;
      } else {
        print('⚠️ Failed to load plans. Status: ${response.statusCode}');
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting user plans: $e');
      throw Exception('Error getting user plans: $e');
    }
  }

  // Get a specific plan by ID
  static Future<Plan> getPlan(int planId) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Fetching plan $planId from: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.get('/api/plans/$planId');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully fetched plan $planId');
        return Plan.fromJson(response.data);
      } else {
        print('⚠️ Failed to load plan. Status: ${response.statusCode}');
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting plan details: $e');
      throw Exception('Error getting plan details: $e');
    }
  }

  // Create a new plan
  static Future<Plan> createPlan(Plan plan) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Creating plan at: $baseUrl with headers: $headers');

      // Log the JSON payload
      final jsonPayload = plan.toJson();
      print('📦 Plan payload: $jsonPayload');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
          validateStatus: (status) => true, // Don't throw on any status code
        ),
      );

      final response = await dio.post('/api/plans', data: jsonPayload);
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');
      print('📡 Response Body: ${response.data}');

      if (response.statusCode == 201) {
        print('✅ Successfully created plan');
        return Plan.fromJson(response.data);
      } else {
        print('⚠️ Failed to create plan. Status: ${response.statusCode}');
        throw Exception('Failed to create plan: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ Error creating plan: $e');
      if (e is DioException) {
        print('📡 Response data: ${e.response?.data}');
      }
      throw Exception('Error creating plan: $e');
    }
  }
  static Future<Plan> updatePlan(Plan plan) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Updating plan ${plan.id} at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.put('/api/plans/${plan.id}', data: plan.toJson());
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully updated plan ${plan.id}');
        return Plan.fromJson(response.data);
      } else {
        print('⚠️ Failed to update plan. Status: ${response.statusCode}');
        throw Exception('Failed to update plan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating plan: $e');
      throw Exception('Error updating plan: $e');
    }
  }

  // Delete a plan
  static Future<void> deletePlan(int planId) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Deleting plan $planId at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.delete('/api/plans/$planId');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('⚠️ Failed to delete plan. Status: ${response.statusCode}');
        throw Exception('Failed to delete plan: ${response.statusCode}');
      } else {
        print('✅ Successfully deleted plan $planId');
      }
    } catch (e) {
      print('❌ Error deleting plan: $e');
      throw Exception('Error deleting plan: $e');
    }
  }

  // Add an item to a plan
  // In plan_service.dart, modify the addItemToPlan method:
  static Future<PlanItem> addItemToPlan(PlanItem item) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Adding item to plan ${item.planId} at: $baseUrl');

      // Log the payload being sent
      final payload = item.toJson();
      print('📦 Request payload: $payload');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.post(
          '/api/plans/${item.planId}/items',
          data: payload
      );
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('✅ Successfully added item to plan ${item.planId}');
        return PlanItem.fromJson(response.data);
      } else {
        print('⚠️ Failed to add item to plan. Status: ${response.statusCode}');
        throw Exception('Failed to add item to plan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error adding item to plan: $e');
      throw Exception('Error adding item to plan: $e');
    }
  }

  // Update a plan item
  static Future<PlanItem> updatePlanItem(PlanItem item) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Updating plan item ${item.id} at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.put(
          '/api/plans/items/${item.id}',
          data: item.toJson()
      );
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully updated plan item ${item.id}');
        return PlanItem.fromJson(response.data);
      } else {
        print('⚠️ Failed to update plan item. Status: ${response.statusCode}');
        throw Exception('Failed to update plan item: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating plan item: $e');
      throw Exception('Error updating plan item: $e');
    }
  }

  // Delete a plan item
  static Future<void> deletePlanItem(int itemId) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Deleting plan item $itemId at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.delete('/api/plans/items/$itemId');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('⚠️ Failed to delete plan item. Status: ${response.statusCode}');
        throw Exception('Failed to delete plan item: ${response.statusCode}');
      } else {
        print('✅ Successfully deleted plan item $itemId');
      }
    } catch (e) {
      print('❌ Error deleting plan item: $e');
      throw Exception('Error deleting plan item: $e');
    }
  }

  // Optimize the route for a plan
  static Future<List<PlanItem>> optimizeRoute(int planId) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Optimizing route for plan $planId at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.post('/api/plans/$planId/optimize');
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final items = data.map((json) => PlanItem.fromJson(json)).toList();
        print('✅ Successfully optimized route with ${items.length} items');
        return items;
      } else {
        print('⚠️ Failed to optimize route. Status: ${response.statusCode}');
        throw Exception('Failed to optimize route: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error optimizing route: $e');
      throw Exception('Error optimizing route: $e');
    }
  }

  // Get available plan templates
  static Future<List<PlanTemplate>> getTemplates({String? category}) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Fetching templates from: $baseUrl');

      String url = '/api/templates';
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.get(url);
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final templates = data.map((json) => PlanTemplate.fromJson(json)).toList();
        print('✅ Successfully fetched ${templates.length} templates');
        return templates;
      } else {
        print('⚠️ Failed to load templates. Status: ${response.statusCode}');
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting templates: $e');
      throw Exception('Error getting templates: $e');
    }
  }

  // Create a plan from a template
  static Future<Plan> createPlanFromTemplate(int templateId, DateTime startDate) async {
    try {
      final headers = await _getHeaders();
      print('🌐 Creating plan from template $templateId at: $baseUrl');

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: headers,
        ),
      );

      final response = await dio.post(
        '/api/templates/create-plan',
        data: {
          'template_id': templateId,
          'start_date': startDate.toIso8601String(),
        },
      );
      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('✅ Successfully created plan from template $templateId');
        return Plan.fromJson(response.data);
      } else {
        print('⚠️ Failed to create plan from template. Status: ${response.statusCode}');
        throw Exception('Failed to create plan from template: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating plan from template: $e');
      throw Exception('Error creating plan from template: $e');
    }
  }
}