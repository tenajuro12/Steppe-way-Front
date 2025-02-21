import 'package:flutter/material.dart';
import '../models/attraction.dart';
import '../models/blogs.dart';
import '../models/event.dart';
import '../services/attraction_service.dart';
import '../services/blogs_service.dart';
import '../services/event_service.dart';
import 'attractions/attraction_details_screen.dart';
import 'blogs/blogs_detailed_screen.dart';
import 'events/event_details_screen.dart';
import 'events/events_screen.dart';
import 'blogs/blogs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Attraction>> _attractionsFuture;
  late Future<List<Event>> _upcomingEventsFuture;
  late Future<List<Blog>> _blogsFuture;

  @override
  void initState() {
    super.initState();
    _attractionsFuture = AttractionService.fetchAttractions();
    _upcomingEventsFuture = EventService.fetchUpcomingEvents();
    _blogsFuture = BlogService.fetchBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Kazakhstan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Upcoming Events'),
            _buildUpcomingEventsList(),
            _buildSectionHeader('Latest Blogs'),
            _buildBlogsList(),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlogsScreen()),
                ),
                child: const Text('See All Blogs'),
              ),
            ),
            _buildSectionHeader('Popular Attractions'),
            _buildAttractionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUpcomingEventsList() {
    return FutureBuilder<List<Event>>(
      future: _upcomingEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No upcoming events.'));
        }

        final events = snapshot.data!;
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(event: event),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventImage(event.imageUrl),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  event.startDate.toLocal().toString().split(' ')[0],
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventImage(String imageUrl) {
    return imageUrl.isNotEmpty
        ? Image.network(
      imageUrl,
      width: 160,
      height: 100,
      fit: BoxFit.cover,
    )
        : Container(
      width: 160,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 50),
    );
  }

  Widget _buildBlogsList() {
    return FutureBuilder<List<Blog>>(
      future: _blogsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No blogs found.'));
        }

        final blogs = snapshot.data!;
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return _buildBlogCard(blog);
            },
          ),
        );
      },
    );
  }

  Widget _buildBlogCard(Blog blog) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlogDetailsScreen(blog: blog),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  blog.content.length > 60
                      ? '${blog.content.substring(0, 60)}...'
                      : blog.content,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('❤️ ${blog.likes}'),
                    Text(blog.createdAt.toLocal().toString().split(' ')[0]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttractionsList() {
    return FutureBuilder<List<Attraction>>(
      future: _attractionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attractions found.'));
        }

        final attractions = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attractions.length,
          itemBuilder: (context, index) {
            final attraction = attractions[index];
            return _buildAttractionCard(attraction);
          },
        );
      },
    );
  }

  Widget _buildAttractionCard(Attraction attraction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: attraction.imageUrl.isNotEmpty
            ? Image.network(
          attraction.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
            : const Icon(Icons.image_not_supported, size: 60),
        title: Text(attraction.title),
        subtitle: Text('${attraction.city}\n${attraction.description}'),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttractionDetailsScreen(attraction: attraction),
          ),
        ),
      ),
    );
  }
}