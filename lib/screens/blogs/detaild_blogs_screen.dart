// blog_detail_page.dart
import 'package:flutter/material.dart';

import '../../models/blogs.dart';

class BlogDetailPage extends StatelessWidget {
  final Blog blog;
  const BlogDetailPage({Key? key, required this.blog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blog.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(blog.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Category: ${blog.category}'),
            const SizedBox(height: 10),
            Text('Likes: ${blog.likes}'),
            const SizedBox(height: 20),
            const Text(
              'Comments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: blog.comments.length,
                itemBuilder: (context, index) {
                  final comment = blog.comments[index];
                  return ListTile(
                    title: Text(comment.content),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
