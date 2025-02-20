// blogs_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:travel_kz/screens/blogs/create_blog_screen.dart';
import 'package:travel_kz/screens/blogs/detaild_blogs_screen.dart';

import '../../models/blogs.dart';

class BlogsPage extends StatefulWidget {
  const BlogsPage({Key? key}) : super(key: key);

  @override
  _BlogsPageState createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080',
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<Blog>> fetchBlogs() async {
    try {
      final Response response = await _dio.get('/blogs');
      // Expecting a JSON array of blogs.
      List<dynamic> data = response.data;
      return data.map((json) => Blog.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching blogs: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blogs'),
      ),
      body: FutureBuilder<List<Blog>>(
        future: fetchBlogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final blogs = snapshot.data;
          if (blogs == null || blogs.isEmpty) {
            return const Center(child: Text('No blogs available.'));
          }
          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(blog.title),
                  subtitle: Text(
                    blog.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thumb_up),
                      Text(blog.likes.toString()),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogDetailPage(blog: blog),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          // Navigate to CreateBlogPage and refresh the list upon success.
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBlogPage()),
          );
          if (result == true) {
            setState(() {}); // refresh blogs list
          }
        },
      ),
    );
  }
}
