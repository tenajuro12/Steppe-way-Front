import 'package:flutter/material.dart';
import '../../models/blogs.dart';

class BlogDetailsScreen extends StatelessWidget {
  final Blog blog;

  const BlogDetailsScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(blog.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blog.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Likes: ❤️ ${blog.likes}  |  Author ID: ${blog.userId}'),
            const SizedBox(height: 8),
            Text(
              'Created: ${blog.createdAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  blog.content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
