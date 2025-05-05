import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  late Future<UserProfile> _profileFuture;
  bool _isEditing = false;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.fetchUserProfile(widget.userId);
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _profileService.fetchUserProfile(widget.userId);
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile(UserProfile currentProfile) async {
    if (!_isEditing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService.updateProfile(
        userId: widget.userId,
        username: _usernameController.text != currentProfile.username
            ? _usernameController.text
            : null,
        email: _emailController.text != currentProfile.email
            ? _emailController.text
            : null,
        bio: _bioController.text != currentProfile.bio
            ? _bioController.text
            : null,
        profileImage: _selectedImage,
      );

      // Update local storage with new username if changed
      if (_usernameController.text != currentProfile.username) {
        const FlutterSecureStorage().write(
            key: 'username',
            value: _usernameController.text
        );
      }

      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      _refreshProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startEditing(UserProfile profile) {
    _usernameController.text = profile.username;
    _emailController.text = profile.email;
    _bioController.text = profile.bio;

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found'));
          }

          final profile = snapshot.data!;
          return _buildProfileContent(profile);
        },
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            title: !_isEditing
                ? Text(
              profile.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _startEditing(profile),
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _cancelEditing,
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.check, color: Colors.white),
                    onPressed: _isLoading
                        ? null
                        : () => _saveProfile(profile),
                  ),
                ],
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: _selectedImage != null
                          ? CircleAvatar(
                        radius: 60,
                        backgroundImage: FileImage(_selectedImage!),
                      )
                          : CachedNetworkImage(
                        imageUrl: '${_profileService.baseUrl}${profile.profileImg}',
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 60,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => const CircleAvatar(
                          radius: 60,
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Profile Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isEditing
                    ? _buildEditForm()
                    : _buildProfileInfo(profile),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(
          'Username',
          profile.username,
          Icons.person,
        ),
        const Divider(height: 32),
        _buildInfoSection(
          'Email',
          profile.email,
          Icons.email,
        ),
        const Divider(height: 32),
        _buildInfoSection(
          'Bio',
          profile.bio,
          Icons.description,
          isMultiLine: true,
        ),
        const SizedBox(height: 32),
        // Statistics
        const Text(
          'My Kazakhstan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Places Visited', '12', Icons.place),
            _buildStatCard('Events Attended', '5', Icons.event),
            _buildStatCard('Reviews', '8', Icons.star),
          ],
        ),
        const SizedBox(height: 24),
        // Additional Sections
        _buildActionButton(
          'My Planned Trips',
          Icons.map,
              () => Navigator.pushNamed(context, '/plans'),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'My Favorites',
          Icons.favorite,
              () => Navigator.pushNamed(context, '/favorites'),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'My Reviews',
          Icons.rate_review,
              () => Navigator.pushNamed(context, '/reviews'),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'My Photos',
          Icons.photo_library,
              () => Navigator.pushNamed(context, '/photos'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoSection(
      String label,
      String value,
      IconData icon,
      {bool isMultiLine = false}
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: isMultiLine
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      VoidCallback onTap
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.description,
          maxLines: 5,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
