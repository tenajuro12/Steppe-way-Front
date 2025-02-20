import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({Key? key}) : super(key: key);

  @override
  _CreateBlogPageState createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();

  // Instantiate Dio with your backend's base URL.
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080', // Use http://10.0.2.2:8080 for Android emulators
    headers: {'Content-Type': 'application/json'},
  ));

  // Secure storage instance to retrieve the session token.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> createBlog() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Retrieve the session token from secure storage.
        final token = await _storage.read(key: 'session_token');
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No session token found. Please log in.')),
          );
          return;
        }

        // Send POST request to create a blog, including the session token in the Cookie header.
        final response = await _dio.post(
          '/blogs',
          data: {
            'title': _titleController.text,
            'content': _contentController.text,
            'category': _categoryController.text,
            // Optionally, include other fields (e.g., user_id) if needed by your backend.
          },
          options: Options(
            headers: {
              'Cookie': 'session_token=$token',
            },
          ),
        );

        // Check for a successful response (status code 200 or 201).
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blog created successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create blog')),
          );
        }
      } catch (e) {
        print('Error creating blog: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating blog')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Blog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter content' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter category' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: createBlog,
                child: const Text('Create Blog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
