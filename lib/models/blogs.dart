class Blog {
  final int id;
  final String title;
  final String content;
  final int userId;
  final int likes;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.likes,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['ID'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      userId: json['user_id'] ?? 0,
      likes: json['likes'] ?? 0,
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
    );
  }
}
