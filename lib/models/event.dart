class Event {
  final int id;
  final String title;
  final String location;
  final String imageUrl;
  // You can add other fields as needed

  Event({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
