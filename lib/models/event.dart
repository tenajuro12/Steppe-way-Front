class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final String address;
  final String link;
  final String category;
  final int capacity;
  final int currentCount;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.link,
    required this.category,
    required this.capacity,
    required this.currentCount,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['ID'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      link: json['link'] ?? '',
      category: json['category'] ?? '',
      capacity: json['capacity'] ?? 0,
      currentCount: json['current_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      imageUrl: json['image_url'] != null
          ? 'http://10.0.2.2:8080${json['image_url']}'
          : '',
    );
  }
}
