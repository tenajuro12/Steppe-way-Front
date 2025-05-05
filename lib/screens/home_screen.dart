import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_kz/screens/attractions/attraction_details_screen.dart';
import 'package:travel_kz/screens/blogs/blogs_detailed_screen.dart';
import 'package:travel_kz/screens/events/event_details_screen.dart';
import 'package:travel_kz/screens/plan/plan_screen.dart';
import 'package:travel_kz/screens/profile/profile_screen.dart';
import 'dart:ui';

import '../models/attraction.dart';
import '../models/blogs.dart';
import '../models/event.dart';
import '../services/attraction_service.dart';
import '../services/blogs_service.dart';
import '../services/event_service.dart';
import 'attractions/attractions_screen.dart';
import 'blogs/blogs_screen.dart';
import 'events/events_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _attractionsFuture = AttractionService.fetchAttractions();
    _upcomingEventsFuture = EventService.fetchUpcomingEvents();
    _blogsFuture = BlogService.fetchBlogs();


    _scrollController.addListener(() {
      if (_scrollController.offset > 150) {
        if (!_showAppBarTitle) {
          setState(() {
            _showAppBarTitle = true;
          });
        }
      } else {
        if (_showAppBarTitle) {
          setState(() {
            _showAppBarTitle = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: _showAppBarTitle ? 2 : 0,
        backgroundColor: _showAppBarTitle
            ? Theme.of(context).primaryColor
            : Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: const Text(
            'Explore Kazakhstan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: _showAppBarTitle ? Colors.white : Colors.white,
            size: 28,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: _showAppBarTitle ? Colors.white : Colors.white,
              size: 28,
            ),
            onPressed: () => _showSearchModal(context),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: _showAppBarTitle ? Colors.white : Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: _buildHeroHeader(),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),

            // Upcoming Events
            SliverToBoxAdapter(
              child: _buildSectionHeader('Upcoming Events', onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                );
              }),
            ),
            SliverToBoxAdapter(
              child: _buildUpcomingEventsList(),
            ),

            // Popular Attractions
            SliverToBoxAdapter(
              child: _buildSectionHeader('Popular Attractions', onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttractionsListScreen()),
                );
              }),
            ),
            SliverToBoxAdapter(
              child: _buildAttractionsList(),
            ),

            // Latest Blogs
            SliverToBoxAdapter(
              child: _buildSectionHeader('Latest Blogs', onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlogsScreen()),
                );
              }),
            ),
            SliverToBoxAdapter(
              child: _buildBlogsList(),
            ),

            // Footer Space
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        // Background Image
        Container(
          height: 280,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/kazakhstan_hero.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Welcome Content
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore Kazakhstan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover the beauty, culture, and adventure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/tour-guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Start Your Adventure',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 16),
            child: Text(
              'Discover',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                ),
                _buildQuickActionItem(
                  icon: Icons.place_outlined,
                  label: 'Attractions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttractionsListScreen()),
                  ),
                ),
                _buildQuickActionItem(
                  icon: Icons.event_outlined,
                  label: 'Events',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventsScreen()),
                  ),
                ),
                _buildQuickActionItem(
                  icon: Icons.article_outlined,
                  label: 'Blogs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlogsScreen()),
                  ),
                ),
                _buildQuickActionItem(
                  icon: Icons.hotel_outlined,
                  label: 'Hotels',
                  onTap: () => Navigator.pushNamed(context, '/hotels'),
                ),
                _buildQuickActionItem(
                  icon: Icons.restaurant_menu_outlined,
                  label: 'Food',
                  onTap: () => Navigator.pushNamed(context, '/restaurants'),
                ),
                _buildQuickActionItem(
                  icon: Icons.photo_camera_outlined,
                  label: 'Photos',
                  onTap: () => Navigator.pushNamed(context, '/gallery'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAllPressed != null)
            GestureDetector(
              onTap: onSeeAllPressed,
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsList() {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Event>>(
        future: _upcomingEventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No upcoming events'));
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailsScreen(event: event),
                  ),
                ),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Image
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(event.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Event Details
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    event.description,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAttractionsList() {
    return SizedBox(
      height: 250,
      child: FutureBuilder<List<Attraction>>(
        future: _attractionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attractions found'));
          }

          final attractions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: attractions.length,
            itemBuilder: (context, index) {
              final attraction = attractions[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttractionDetailsScreen(attraction: attraction),
                  ),
                ),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attraction Image
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(attraction.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_border,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Attraction Title
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attraction.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    attraction.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBlogsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<Blog>>(
        future: _blogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No blogs found'));
          }

          final blogs = snapshot.data!;
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: blogs.length > 3 ? 3 : blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlogDetailsScreen(blog: blog),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // Blog Image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(blog.category),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Blog Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blog.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                blog.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'By ${blog.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    blog.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {

    return Drawer(

      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: AssetImage('assets/images/profile_placeholder.jpg'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hello, Traveler!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sign In / Sign Up',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),

          _buildDrawerItem(
            icon: Icons.explore_outlined,
            title: 'Explore',
            onTap: () => Navigator.pushNamed(context, '/explore'),
          ),
          _buildDrawerItem(
            icon: Icons.place_outlined,
            title: 'Attractions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttractionsListScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.event_outlined,
            title: 'Events',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.article_outlined,
            title: 'Blogs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlogsScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.map_outlined,
            title: 'Interactive Map',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.hotel_outlined,
            title: 'Accommodations',
            onTap: () => Navigator.pushNamed(context, '/hotels'),
          ),
          _buildDrawerItem(
            icon: Icons.restaurant_menu_outlined,
            title: 'Food & Dining',
            onTap: () => Navigator.pushNamed(context, '/restaurants'),
          ),
          _buildDrawerItem(
            icon: Icons.person_outlined,
            title: 'My Profile',
            onTap: () async {
              // Get the current user ID from secure storage or state management
              final storage = FlutterSecureStorage();
              final userId = await storage.read(key: 'user_id');

              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: int.parse(userId))),
                );
              } else {
                // Handle case when user is not logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to view your profile')),
                );
                // Optionally navigate to login page
                // Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.public_outlined,
            title: 'Travel Guide',
            onTap: () => Navigator.pushNamed(context, '/travel-guide'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0:

              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
              break;
            case 2:
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlansScreen()),);
                  break;
            case 3:
              Navigator.pushNamed(context, '/favorites');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backpack_outlined),
            activeIcon: Icon(Icons.backpack),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search attractions, events, blogs...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildSearchFilterChip('Attractions'),
                  const SizedBox(width: 8),
                  _buildSearchFilterChip('Events'),
                  const SizedBox(width: 8),
                  _buildSearchFilterChip('Blogs'),
                  const SizedBox(width: 8),
                  _buildSearchFilterChip('Hotels'),
                ],
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentSearchItem('Charyn Canyon'),
                  _buildRecentSearchItem('Astana events'),
                  _buildRecentSearchItem('Traditional cuisine'),
                  _buildRecentSearchItem('Almaty attractions'),
                ],
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPopularCategoryChip('Mountains'),
                      const SizedBox(width: 8),
                      _buildPopularCategoryChip('Lakes'),
                      const SizedBox(width: 8),
                      _buildPopularCategoryChip('Deserts'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPopularCategoryChip('Historical'),
                      const SizedBox(width: 8),
                      _buildPopularCategoryChip('Cultural'),
                      const SizedBox(width: 8),
                      _buildPopularCategoryChip('Nature'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: label == 'Attractions',
      onSelected: (bool selected) {
        // Handle filter selection
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: label == 'Attractions'
            ? Theme.of(context).primaryColor
            : Colors.black87,
        fontWeight: label == 'Attractions'
            ? FontWeight.bold
            : FontWeight.normal,
      ),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Text(
            query,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.north_west,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategoryChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      labelStyle: const TextStyle(
        color: Colors.black87,
      ),
    );
  }}