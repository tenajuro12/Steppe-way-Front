import 'package:flutter/material.dart';

import '../../models/blogs.dart';
import '../../services/blogs_service.dart';
import 'blogs_detailed_screen.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  late Future<List<Blog>> _blogsFuture;

  @override
  void initState() {
    super.initState();
    _blogsFuture = BlogService.fetchBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blogs')),
      body: FutureBuilder<List<Blog>>(
        future: _blogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No blogs found.'));
          } else {
            final blogs = snapshot.data!;
            return ListView.builder(
              itemCount: blogs.length,
              itemBuilder: (context, index) {
                final blog = blogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(blog.title),
                    subtitle: Text(
                      blog.content.length > 100
                          ? '${blog.content.substring(0, 100)}...'
                          : blog.content,
                    ),
                    trailing: Text('❤️ ${blog.likes}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlogDetailsScreen(blog: blog),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
