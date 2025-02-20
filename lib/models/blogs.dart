// models.dart
class Blog {
  final int id;
  final String title;
  final String content;
  final int userId;
  final int likes;
  final String category;
  final List<Comment> comments;
  final List<BlogLike> blogLikes;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.likes,
    required this.category,
    required this.comments,
    required this.blogLikes,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    var commentsList = (json['comments'] as List?) ?? [];
    var blogLikesList = (json['blog_likes'] as List?) ?? [];
    return Blog(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      userId: json['user_id'],
      likes: json['likes'],
      category: json['category'],
      comments:
      commentsList.map((item) => Comment.fromJson(item)).toList(),
      blogLikes:
      blogLikesList.map((item) => BlogLike.fromJson(item)).toList(),
    );
  }
}

class Comment {
  final int id;
  final String content;
  final int blogId;
  final int userId;

  Comment({
    required this.id,
    required this.content,
    required this.blogId,
    required this.userId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      blogId: json['blog_id'],
      userId: json['user_id'],
    );
  }
}

class BlogLike {
  final int id;
  final int userId;
  final int blogId;

  BlogLike({
    required this.id,
    required this.userId,
    required this.blogId,
  });

  factory BlogLike.fromJson(Map<String, dynamic> json) {
    return BlogLike(
      id: json['id'],
      userId: json['user_id'],
      blogId: json['blog_id'],
    );
  }
}
