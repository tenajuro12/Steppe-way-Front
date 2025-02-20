  class Attraction {
    final int id;
    final String title;
    final String description;
    final String city;
    final String location;
    final bool isPublished;
    final int adminId;
    final String imageUrl;

    Attraction({
      required this.id,
      required this.title,
      required this.description,
      required this.city,
      required this.location,
      required this.isPublished,
      required this.adminId,
      required this.imageUrl,
    });

    factory Attraction.fromJson(Map<String, dynamic> json) {
      return Attraction(
        id: json['ID'] != null ? json['ID'] as int : 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        city: json['city'] ?? '',
        location: json['location'] ?? '',
        isPublished: json['is_published'] ?? false,
        adminId: json['admin_id'] != null ? json['admin_id'] as int : 0,
        imageUrl: json['image_url'] ?? '',
      );
    }
  }
