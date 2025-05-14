import 'dart:convert';

class Place {
  final int id;
  final String name;
  final String description;
  final String city;
  final String address;
  final String location;
  final String type;
  final String priceRange;
  final String website;
  final String phone;
  final bool isPublished;
  final double averageRating;
  final List<PlaceImage> images;
  final List<Cuisine> cuisines;
  final List<Dish> dishes;
  final List<FoodReview> reviews;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    this.location = '',
    required this.type,
    this.priceRange = '',
    this.website = '',
    this.phone = '',
    this.isPublished = true,
    this.averageRating = 0.0,
    this.images = const [],
    this.cuisines = const [],
    this.dishes = const [],
    this.reviews = const [],
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? json['ID'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      priceRange: json['price_range'] ?? '',
      website: json['website'] ?? '',
      phone: json['phone'] ?? '',
      isPublished: json['is_published'] ?? true,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      images: json['images'] != null
          ? List<PlaceImage>.from(
          json['images'].map((x) => PlaceImage.fromJson(x)))
          : [],
      cuisines: json['cuisines'] != null
          ? List<Cuisine>.from(
          json['cuisines'].map((x) => Cuisine.fromJson(x)))
          : [],
      dishes: json['dishes'] != null
          ? List<Dish>.from(json['dishes'].map((x) => Dish.fromJson(x)))
          : [],
      reviews: json['reviews'] != null
          ? List<FoodReview>.from(
          json['reviews'].map((x) => FoodReview.fromJson(x)))
          : [],
    );
  }
}

class PlaceImage {
  final int id;
  final String url;

  PlaceImage({
    required this.id,
    required this.url,
  });

  factory PlaceImage.fromJson(Map<String, dynamic> json) {
    return PlaceImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class Cuisine {
  final int id;
  final String name;
  final String description;
  final String origin;

  Cuisine({
    required this.id,
    required this.name,
    this.description = '',
    this.origin = '',
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    return Cuisine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      origin: json['origin'] ?? '',
    );
  }
}

class Dish {
  final int id;
  final String name;
  final String description;
  final double price;
  final bool isSpecialty;
  final int placeId;
  final int? cuisineId;
  final List<DishImage> images;

  Dish({
    required this.id,
    required this.name,
    this.description = '',
    this.price = 0.0,
    this.isSpecialty = false,
    required this.placeId,
    this.cuisineId,
    this.images = const [],
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      isSpecialty: json['is_specialty'] ?? false,
      placeId: json['place_id'] ?? 0,
      cuisineId: json['cuisine_id'],
      images: json['images'] != null
          ? List<DishImage>.from(
          json['images'].map((x) => DishImage.fromJson(x)))
          : [],
    );
  }
}

class DishImage {
  final int id;
  final String url;

  DishImage({
    required this.id,
    required this.url,
  });

  factory DishImage.fromJson(Map<String, dynamic> json) {
    return DishImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class FoodReview {
  final int id;
  final int placeId;
  final int userId;
  final String username;
  final String profileImg;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<ReviewImage> images;

  FoodReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.username,
    this.profileImg = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
  });

  factory FoodReview.fromJson(Map<String, dynamic> json) {
    return FoodReview(
      id: json['id'] ?? json['ID'] ?? 0,
      placeId: json['place_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      profileImg: json['profile_img'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      images: json['images'] != null
          ? List<ReviewImage>.from(
          json['images'].map((x) => ReviewImage.fromJson(x)))
          : [],
    );
  }
}

class ReviewImage {
  final int id;
  final String url;

  ReviewImage({
    required this.id,
    required this.url,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class PlaceSearchResult {
  final List<Place> places;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PlaceSearchResult({
    required this.places,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      places: json['places'] != null
          ? List<Place>.from(json['places'].map((x) => Place.fromJson(x)))
          : [],
      total: json['pagination']['total'] ?? 0,
      page: json['pagination']['page'] ?? 1,
      pageSize: json['pagination']['page_size'] ?? 20,
      totalPages: json['pagination']['total_pages'] ?? 1,
    );
  }
}