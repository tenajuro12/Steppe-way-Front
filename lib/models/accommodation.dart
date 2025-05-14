// lib/models/accommodation.dart
import 'package:intl/intl.dart';
import 'dart:convert';

class Accommodation {
  final int id;
  final String name;
  final String description;
  final String city;
  final String address;
  final String location;
  final String type;
  final int adminId;
  final String website;
  final bool isPublished;
  final List<String> amenities;
  final List<AccommodationImage> images;
  final List<RoomType> roomTypes;
  final List<AccommodationReview> reviews;

  Accommodation({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.location,
    required this.type,
    required this.adminId,
    required this.website,
    required this.isPublished,
    required this.amenities,
    required this.images,
    required this.roomTypes,
    required this.reviews,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    List<AccommodationImage> images = [];
    if (json['images'] != null) {
      images = List<AccommodationImage>.from(
        json['images'].map((x) => AccommodationImage.fromJson(x)),
      );
    }

    List<RoomType> roomTypes = [];
    if (json['room_types'] != null) {
      roomTypes = List<RoomType>.from(
        json['room_types'].map((x) => RoomType.fromJson(x)),
      );
    }

    List<AccommodationReview> reviews = [];
    if (json['reviews'] != null) {
      reviews = List<AccommodationReview>.from(
        json['reviews'].map((x) => AccommodationReview.fromJson(x)),
      );
    }

    List<String> amenities = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is List) {
        amenities = List<String>.from(json['amenities']);
      } else if (json['amenities'] is String) {
        try {
          // Try to parse the string as JSON
          final List<dynamic> parsed = jsonDecode(json['amenities']);
          amenities = List<String>.from(parsed);
        } catch (e) {
          // If parsing fails, use empty list
          amenities = [];
        }
      }
    }

    return Accommodation(
      id: json['id'] ?? json['ID'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      adminId: json['admin_id'] ?? 0,
      website: json['website'] ?? '',
      isPublished: json['is_published'] ?? false,
      amenities: amenities,
      images: images,
      roomTypes: roomTypes,
      reviews: reviews,
    );
  }

  // Method to get average rating
  double get averageRating {
    if (reviews.isEmpty) return 0;
    final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  // Method to get starting price (lowest room price)
  double get startingPrice {
    if (roomTypes.isEmpty) return 0;
    return roomTypes.map((room) => room.price).reduce((a, b) => a < b ? a : b);
  }

  // Formatted starting price
  String get formattedStartingPrice {
    return '\$${startingPrice.toStringAsFixed(2)}';
  }
}

class AccommodationImage {
  final int id;
  final int accommodationId;
  final String url;

  AccommodationImage({
    required this.id,
    required this.accommodationId,
    required this.url,
  });

  factory AccommodationImage.fromJson(Map<String, dynamic> json) {
    return AccommodationImage(
      id: json['id'] ?? json['ID'] ?? 0,
      accommodationId: json['accommodation_id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class RoomType {
  final int id;
  final int accommodationId;
  final String name;
  final String description;
  final double price;
  final int maxGuests;
  final String bedType;
  final String size;

  final List<String> amenities;
  final List<RoomImage> images;

  RoomType({
    required this.id,
    required this.accommodationId,
    required this.name,
    required this.description,
    required this.price,
    required this.maxGuests,
    required this.bedType,
    required this.amenities,
    required this.images,
    required this.size
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    List<RoomImage> images = [];
    if (json['images'] != null) {
      images = List<RoomImage>.from(
        json['images'].map((x) => RoomImage.fromJson(x)),
      );
    }

    List<String> amenities = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is List) {
        amenities = List<String>.from(json['amenities']);
      } else if (json['amenities'] is String) {
        try {
          final List<dynamic> parsed = jsonDecode(json['amenities']);
          amenities = List<String>.from(parsed);
        } catch (e) {
          amenities = [];
        }
      }
    }

    return RoomType(
      id: json['id'] ?? json['ID'] ?? 0,
      accommodationId: json['accommodation_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] ?? 0.0),
      maxGuests: json['max_guests'] ?? 0,
      bedType: json['bed_type'] ?? '',
      size: json['size'] ?? '',
      amenities: amenities,
      images: images,
    );
  }

  // Formatted price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }
}

class RoomImage {
  final int id;
  final int roomTypeId;
  final String url;

  RoomImage({
    required this.id,
    required this.roomTypeId,
    required this.url,
  });

  factory RoomImage.fromJson(Map<String, dynamic> json) {
    return RoomImage(
      id: json['id'] ?? json['ID'] ?? 0,
      roomTypeId: json['room_type_id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class AccommodationReview {
  final int id;
  final int accommodationId;
  final int userId;
  final String username;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<ReviewImage> images;

  AccommodationReview({
    required this.id,
    required this.accommodationId,
    required this.userId,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.images,
  });

  factory AccommodationReview.fromJson(Map<String, dynamic> json) {
    List<ReviewImage> images = [];
    if (json['images'] != null) {
      images = List<ReviewImage>.from(
        json['images'].map((x) => ReviewImage.fromJson(x)),
      );
    }

    DateTime createdAt;
    try {
      createdAt = json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    return AccommodationReview(
      id: json['id'] ?? json['ID'] ?? 0,
      accommodationId: json['accommodation_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: createdAt,
      images: images,
    );
  }

  // Formatted date
  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(createdAt);
  }
}

class ReviewImage {
  final int id;
  final int reviewId;
  final String url;

  ReviewImage({
    required this.id,
    required this.reviewId,
    required this.url,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      id: json['id'] ?? json['ID'] ?? 0,
      reviewId: json['review_id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}