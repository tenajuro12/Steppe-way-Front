class Event {
  final int id;
  final String title;
  final String description;
  final String location;
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
      category: json['category'] ?? '',
      capacity: json['capacity'] ?? 0,
      currentCount: json['current_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      imageUrl: json['image_url'] != null
          ? 'http://192.168.1.71:8080${json['image_url']}'
          : '',
    );
  }
}
