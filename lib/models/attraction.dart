class Attraction {
      final int id;
      final String title;
      final String description;
      final String city;
      final String location;
      final String address;
      final bool isPublished;
      final int adminId;
      final String imageUrl;
      String category;


      Attraction({
        required this.id,
        required this.title,
        required this.description,
        required this.city,
        required this.address,
        required this.location,
        required this.isPublished,
        required this.adminId,
        required this.imageUrl,
        required this.category,

      });

      factory Attraction.fromJson(Map<String, dynamic> json) {
        final imagePath = json['image_url'];

        return Attraction(
          id: json['ID'] != null ? json['ID'] as int : 0,
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          city: json['city'] ?? '',
          location: json['location'] ?? '',
          address: json['address']?? '',
          category: json['category'],
          isPublished: json['is_published'] ?? false,
          adminId: json['admin_id'] != null ? json['admin_id'] as int : 0,
          imageUrl: (imagePath != null && imagePath.isNotEmpty)
              ? 'http://10.0.2.2:8080$imagePath'
              : '',     );
      }
    }
