import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:intl/intl.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/food.dart';
import '../../services/food_service.dart';
import 'dish_details_screen.dart';
import 'food_reviews_screen.dart';
import 'add_review_screen.dart';


class FoodPlaceDetailsScreen extends StatefulWidget {
  final int placeId;

  const FoodPlaceDetailsScreen({Key? key, required this.placeId}) : super(key: key);

  @override
  _FoodPlaceDetailsScreenState createState() => _FoodPlaceDetailsScreenState();
}


class _FoodPlaceDetailsScreenState extends State<FoodPlaceDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Place> _placeFuture;
  bool _isLoading = true;
  Place? _place;
  int _currentImageIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlace();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlace() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _placeFuture = FoodService.getFoodPlace(widget.placeId);
      _place = await _placeFuture;
    } catch (e) {
      print('Error loading place: $e');
      // Show error message if needed
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _place?.name ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: _buildHeaderImages(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Implement share functionality
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _place != null
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddReviewScreen(place: _place!),
            ),
          ).then((_) => _loadPlace());
        },
        child: const Icon(Icons.rate_review),
      )
          : null,
    );
  }

  Widget _buildHeaderImages() {
    if (_place == null || _place!.images.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterCarousel(
          options: CarouselOptions(
            height: 250,
            showIndicator: false,
            viewportFraction: 1.0,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: _place!.images.map((image) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  child: Image.network(
                    image.url.startsWith('http')
                        ? image.url
                        : '${FoodService.baseUrl}${image.url}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 80.0,
          left: 0,
          right: 0,
          child: Center(
            child: DotsIndicator(
              dotsCount: _place!.images.length,
              position: _currentImageIndex.toDouble(),
              decorator: const DotsDecorator(
                color: Colors.white60,
                activeColor: Colors.white,
                size: Size.square(8.0),
                activeSize: Size.square(10.0),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildBasicInfo() {
    if (_place == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _place!.type,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_place!.cuisines.isNotEmpty)
                      Text(
                        _place!.cuisines.map((c) => c.name).join(', '),
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
              if (_place!.priceRange.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _place!.priceRange,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _place!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_place!.address}, ${_place!.city}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  if (_place!.location.isNotEmpty) {
                    final coords = _place!.location.split(',');
                    if (coords.length == 2) {
                      final lat = double.tryParse(coords[0].trim());
                      final lng = double.tryParse(coords[1].trim());
                      if (lat != null && lng != null) {
                        launchUrl(Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng'));
                      }
                    }
                  } else {
                    launchUrl(Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_place!.address + ', ' + _place!.city)}'));
                  }
                },
              ),
            ],
          ),
          if (_place!.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _place!.phone,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    launchUrl(Uri.parse('tel:${_place!.phone}'));
                  },
                ),
              ],
            ),
          ],
          if (_place!.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _place!.website,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    launchUrl(Uri.parse(_place!.website));
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _place!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Menu'),
          Tab(text: 'Reviews'),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_place == null) return const SizedBox.shrink();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildReviewsTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    if (_place == null || _place!.dishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No menu items available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Group dishes by cuisine
    final dishByCuisine = <String, List<Dish>>{};
    dishByCuisine['Specialties'] = [];

    for (final dish in _place!.dishes) {
      if (dish.isSpecialty) {
        dishByCuisine['Specialties']!.add(dish);
      }

      String cuisineName = 'Other';
      if (dish.cuisineId != null) {
        final cuisine = _place!.cuisines.firstWhere(
              (c) => c.id == dish.cuisineId,
          orElse: () => Cuisine(id: 0, name: 'Other'),
        );
        cuisineName = cuisine.name;
      }

      if (!dishByCuisine.containsKey(cuisineName)) {
        dishByCuisine[cuisineName] = [];
      }

      if (!dish.isSpecialty || cuisineName != 'Specialties') {
        dishByCuisine[cuisineName]!.add(dish);
      }
    }

    // Remove empty lists
    dishByCuisine.removeWhere((key, value) => value.isEmpty);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dishByCuisine.length,
      itemBuilder: (context, index) {
        final cuisine = dishByCuisine.keys.elementAt(index);
        final dishes = dishByCuisine[cuisine]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                cuisine,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dishes.length,
              itemBuilder: (context, dishIndex) {
                final dish = dishes[dishIndex];
                return _buildDishItem(dish);
              },
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildDishItem(Dish dish) {
    final hasImage = dish.images.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DishDetailsScreen(dish: dish),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    dish.images[0].url.startsWith('http')
                        ? dish.images[0].url
                        : '${FoodService.baseUrl}${dish.images[0].url}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dish.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (dish.isSpecialty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Specialty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (dish.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dish.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '\$${dish.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_place == null) return const SizedBox.shrink();

    if (_place!.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReviewScreen(place: _place!),
                  ),
                ).then((_) => _loadPlace());
              },
              icon: const Icon(Icons.star),
              label: const Text('Write a Review'),
            ),
          ],
        ),
      );
    }

    // Show first few reviews
    final reviewsToShow = _place!.reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${_place!.reviews.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodReviewsScreen(place: _place!),
                    ),
                  ).then((_) => _loadPlace());
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...reviewsToShow.map((review) => _buildReviewItem(review)),
          if (_place!.reviews.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodReviewsScreen(place: _place!),
                    ),
                  ).then((_) => _loadPlace());
                },
                icon: const Icon(Icons.more_horiz),
                label: Text('See All ${_place!.reviews.length} Reviews'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(FoodReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.profileImg.isNotEmpty
                      ? NetworkImage(
                    review.profileImg.startsWith('http')
                        ? review.profileImg
                        : '${FoodService.baseUrl}${review.profileImg}',
                  )
                      : null,
                  child: review.profileImg.isEmpty
                      ? Text(review.username.isNotEmpty ? review.username[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment),
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.images[index].url.startsWith('http')
                              ? review.images[index].url
                              : '${FoodService.baseUrl}${review.images[index].url}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_place == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Type', _place!.type),
          _buildInfoItem('City', _place!.city),
          _buildInfoItem('Address', _place!.address),
          if (_place!.phone.isNotEmpty)
            _buildInfoItem('Phone', _place!.phone),
          if (_place!.website.isNotEmpty)
            _buildInfoItem('Website', _place!.website, isLink: true),
          if (_place!.priceRange.isNotEmpty)
            _buildInfoItem('Price Range', _place!.priceRange),
          if (_place!.cuisines.isNotEmpty)
            _buildInfoItem('Cuisines', _place!.cuisines.map((c) => c.name).join(', ')),
          const SizedBox(height: 24),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _place!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: isLink
                ? GestureDetector(
              onTap: () => launchUrl(Uri.parse(value)),
              child: Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
                : Text(value),
          ),
        ],
      ),
    );
  }
}