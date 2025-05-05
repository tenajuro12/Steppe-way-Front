class Review {
  final int id;
  final int userId;
  final String username;
  final int attractionId;
  final int rating;
  final String comment;
  final String imageUrl;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.attractionId,
    required this.rating,
    required this.comment,
    required this.imageUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'] ?? '',
      attractionId: json['attraction_id'],
      rating: json['rating'],
      comment: json['comment'],
      imageUrl: json['image_url'] != null
          ? 'http://10.0.2.2:8080${json['image_url']}'
          : '',
    );
  }
}
