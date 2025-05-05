class UserProfile {
  final int userId;
  final String username;
  final String email;
  final String bio;
  final String profileImg;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.bio,
    required this.profileImg,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      profileImg: json['profile_img'] ?? '/uploads/users/default_user.jpg',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
