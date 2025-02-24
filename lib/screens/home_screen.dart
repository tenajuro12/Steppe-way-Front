import 'package:flutter/material.dart';
import '../models/attraction.dart';
import '../models/blogs.dart';
import '../models/event.dart';
import '../services/attraction_service.dart';
import '../services/blogs_service.dart';
import '../services/event_service.dart';
import 'attractions/attraction_details_screen.dart';
import 'attractions/attractions_screen.dart';
import 'blogs/blogs_detailed_screen.dart';
import 'events/event_details_screen.dart';
import 'events/events_screen.dart';
import 'blogs/blogs_screen.dart';
import 'map/map_screen.dart';

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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _attractionsFuture = AttractionService.fetchAttractions();
            _upcomingEventsFuture = EventService.fetchUpcomingEvents();
            _blogsFuture = BlogService.fetchBlogs();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('Map'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.place),
                      label: const Text('See All Attractions'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttractionsListScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionHeader('Upcoming Events'),
              _buildUpcomingEventsList(),
              _buildSectionHeader('Latest Blogs'),
              _buildBlogsList(),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlogsScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('See All Blogs'),
                ),
              ),
              _buildSectionHeader('Popular Attractions'),
              _buildAttractionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
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
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildEventCard(events[index]),
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.startDate.toLocal().toString().split(' ')[0],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: blogs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildBlogCard(blogs[index]),
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
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  blog.content.length > 60 ? '${blog.content.substring(0, 60)}...' : blog.content,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const Icon(Icons.favorite, size: 16, color: Colors.red), Text(' ${blog.likes}')]),
                    Text(blog.createdAt.toLocal().toString().split(' ')[0], style: const TextStyle(color: Colors.grey)),
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
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attractions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildAttractionCard(attractions[index]),
        );
      },
    );
  }

  Widget _buildAttractionCard(Attraction attraction) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: attraction.imageUrl.isNotEmpty
              ? Image.network(
            attraction.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          )
              : Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          ),
        ),
        title: Text(
          attraction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${attraction.city}\n${attraction.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
