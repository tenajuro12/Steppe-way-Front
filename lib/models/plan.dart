import 'package:intl/intl.dart';

// lib/models/plan.dart
import 'package:intl/intl.dart';

class Plan {
  int? id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  int userId;
  bool isPublic;
  String city;
  List<PlanItem> items;

  Plan({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.userId,
    this.isPublic = false,
    required this.city,
    this.items = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug it
    print('Plan JSON: $json');

    return Plan(
      // Handle the case where ID is uppercase instead of lowercase
      id: json['id'] != null
          ? (json['id'] is String ? int.tryParse(json['id']) : json['id'] as int)
          : (json['ID'] != null
          ? (json['ID'] is String ? int.tryParse(json['ID']) : json['ID'] as int)
          : null),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 1)),
      userId: json['user_id'] ?? 0,
      isPublic: json['is_public'] ?? false,
      city: json['city'] ?? '',
      items: json['items'] != null
          ? List<PlanItem>.from(json['items'].map((x) => PlanItem.fromJson(x)))
          : [],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'user_id': userId,
      'is_public': isPublic,
      'city': city,
    };
  }

  int get durationInDays => endDate.difference(startDate).inDays + 1;
}
class PlanItem {
  int? id;
  int planId;
  String itemType;
  int itemId;
  String title;
  String description;
  String location;
  String address;
  DateTime? scheduledFor;  // Make nullable
  int duration;  // in minutes
  int orderIndex;
  String notes;

  PlanItem({
    this.id,
    required this.planId,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.description,
    required this.location,
    this.address = '',
    this.scheduledFor,  // No longer required
    required this.duration,
    required this.orderIndex,
    this.notes = '',
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id'] != null
          ? (json['id'] is String
          ? int.tryParse(json['id'])
          : json['id'] as int)
          : (json['ID'] != null
          ? (json['ID'] is String ? int.tryParse(json['ID']) : json['ID'] as int)
          : null),
      planId: json['plan_id'] ?? 0,
      itemType: json['item_type'] ?? '',
      itemId: json['item_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,  // Can be null now
      duration: json['duration'] ?? 60,
      orderIndex: json['order_index'] ?? 0,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      if (id != null) 'id': id,
      'plan_id': planId,
      'item_type': itemType,
      'item_id': itemId,
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'duration': duration,
      'order_index': orderIndex,
      'notes': notes,
    };

    // Only include scheduled_for if it has a value
    if (scheduledFor != null) {
      data['scheduled_for'] = DateFormat('yyyy-MM-ddTHH:mm:ss').format(scheduledFor!);
    }

    return data;
  }


  String get formattedDuration {
    if (duration < 60) {
      return '$duration mins';
    } else {
      final hours = duration ~/ 60;
      final mins = duration % 60;
      return mins > 0 ? '$hours h $mins min' : '$hours h';
    }
  }
}

// lib/models/plan_template.dart
class PlanTemplate {
  int? id;
  String title;
  String description;
  String city;
  String country;
  int duration;
  String category;
  bool isPublic;

  PlanTemplate({
    this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.country,
    required this.duration,
    required this.category,
    this.isPublic = true,
  });

  factory PlanTemplate.fromJson(Map<String, dynamic> json) {
    return PlanTemplate(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      city: json['city'],
      country: json['country'],
      duration: json['duration'],
      category: json['category'],
      isPublic: json['is_public'] ?? true,
    );
  }
}
