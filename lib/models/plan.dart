import 'package:intl/intl.dart';

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
    print('Plan JSON: $json');

    // Use default dates if null or invalid
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    // Try to parse the start date
    if (json['start_date'] != null) {
      try {
        startDate = DateTime.parse(json['start_date']);

        // Check if the parsed date is valid (not year 0001)
        if (startDate.year < 1000) {
          print('⚠️ Invalid start date year: ${startDate.year}, using default');
          startDate = DateTime.now();
        }
      } catch (e) {
        print('❌ Error parsing start_date: $e');
      }
    }

    // Try to parse the end date
    if (json['end_date'] != null) {
      try {
        endDate = DateTime.parse(json['end_date']);

        // Check if the parsed date is valid (not year 0001)
        if (endDate.year < 1000) {
          print('⚠️ Invalid end date year: ${endDate.year}, using default');
          endDate = startDate.add(const Duration(days: 1));
        }
      } catch (e) {
        print('❌ Error parsing end_date: $e');
      }
    }

    return Plan(
      id: json['id'] ?? json['ID'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: startDate,
      endDate: endDate,
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
// lib/models/plan.dart
// This is an excerpt showing just the changes needed to the PlanItem class

class PlanItem {
  int? id;
  int planId;
  String itemType;
  int itemId;
  String title;
  String description;
  String location;
  String address;
  DateTime? scheduledFor;
  int duration;  // in minutes
  int orderIndex;
  String notes;
  String? imageURL;  // Added for storing image URL
  String? category;  // Added for categorization
  String? priceRange;  // Added for food places
  String? accommodationType;  // Added for accommodations

  PlanItem({
    this.id,
    required this.planId,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.description,
    required this.location,
    this.address = '',
    this.scheduledFor,
    required this.duration,
    required this.orderIndex,
    this.notes = '',
    this.imageURL,
    this.category,
    this.priceRange,
    this.accommodationType,
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
          : null,
      duration: json['duration'] ?? 60,
      orderIndex: json['order_index'] ?? 0,
      notes: json['notes'] ?? '',
      imageURL: json['image_url'],
      category: json['category'],
      priceRange: json['price_range'],
      accommodationType: json['accommodation_type'],
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

    if (scheduledFor != null) {
      data['scheduled_for'] = DateFormat('yyyy-MM-ddTHH:mm:ss').format(scheduledFor!);
    }

    if (imageURL != null) {
      data['image_url'] = imageURL;
    }

    if (category != null) {
      data['category'] = category;
    }

    if (priceRange != null) {
      data['price_range'] = priceRange;
    }

    if (accommodationType != null) {
      data['accommodation_type'] = accommodationType;
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
      // Handle both uppercase "ID" and lowercase "id"
      id: json['id'] ?? json['ID'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      duration: json['duration'] ?? 0,
      category: json['category'] ?? '',
      isPublic: json['is_public'] ?? true,
    );
  }
}

// Add this class to your models/plan.dart file:

class TemplateItem {
  int? id;
  int templateId;
  String itemType;
  int itemId;
  String title;
  String description;
  String location;
  int dayNumber;
  int orderInDay;
  int duration;
  bool recommended;

  TemplateItem({
    this.id,
    required this.templateId,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.description,
    required this.location,
    required this.dayNumber,
    required this.orderInDay,
    required this.duration,
    this.recommended = false,
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['id'],
      templateId: json['template_id'],
      itemType: json['item_type'] ?? 'custom',
      itemId: json['item_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      dayNumber: json['day_number'] ?? 1,
      orderInDay: json['order_in_day'] ?? 1,
      duration: json['duration'] ?? 60,
      recommended: json['recommended'] ?? false,
    );
  }
}
