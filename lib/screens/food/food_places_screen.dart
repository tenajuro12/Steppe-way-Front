import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food.dart';
import '../../services/food_service.dart';
import '../../widgets/favorite_button.dart';
import 'food_place_details_screen.dart';

class FoodPlacesScreen extends StatefulWidget {
  const FoodPlacesScreen({Key? key}) : super(key: key);

  @override
  _FoodPlacesScreenState createState() => _FoodPlacesScreenState();
}

class _FoodPlacesScreenState extends State<FoodPlacesScreen> {
  late Future<PlaceSearchResult> _placesFuture;
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  List<Place> _places = [];

  // Filter variables
  String? _selectedCity;
  String? _selectedType;
  String? _selectedCuisine;
  double? _minRating;
  String? _selectedPriceRange;

  final List<String> _placeTypes = [
    'Restaurant',
    'Cafe',
    'Fast Food',
    'Street Food',
    'Bar',
    'Bakery',
    'Food Court',
  ];

  final List<String> _priceRanges = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];
  late List<Cuisine> _cuisines = [];

  @override
  void initState() {
    super.initState();
    _loadCuisines();
    _loadPlaces(refresh: true);
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await FoodService.getCuisines();
      setState(() {
        _cuisines = cuisines;
      });
    } catch (e) {
      print('Error loading cuisines: $e');
      // Show error message if needed
    }
  }

  Future<void> _loadPlaces({bool refresh = false}) async {
    setState(() {
      if (refresh) {
        _currentPage = 1;
        _places = [];
        _hasMorePages = true;
      }
      _isLoading = true;
    });

    try {
      final result = await FoodService.getFoodPlaces(
        city: _selectedCity,
        type: _selectedType,
        cuisine: _selectedCuisine,
        minRating: _minRating,
        priceRange: _selectedPriceRange,
        page: _currentPage,
      );

      setState(() {
        if (refresh) {
          _places = result.places;
        } else {
          _places.addAll(result.places);
        }
        _hasMorePages = _currentPage < result.totalPages;
        if (_hasMorePages) {
          _currentPage++;
        }
      });
    } catch (e) {
      print('Error loading places: $e');
      // Show error message if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter Food Places',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCity = value.isEmpty ? null : value;
                      });
                    },
                    controller: TextEditingController(text: _selectedCity ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Place Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    value: _selectedType,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ..._placeTypes.map((type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Cuisine',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fastfood),
                    ),
                    value: _selectedCuisine,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Cuisines'),
                      ),
                      ..._cuisines.map((cuisine) => DropdownMenuItem<String>(
                        value: cuisine.name,
                        child: Text(cuisine.name),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCuisine = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Minimum Rating', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: _minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: (_minRating ?? 0).toString(),
                    onChanged: (value) {
                      setModalState(() {
                        _minRating = value > 0 ? value : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _priceRanges.map((range) {
                      final isSelected = _selectedPriceRange == range;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            _selectedPriceRange = isSelected ? null : range;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCity = null;
                            _selectedType = null;
                            _selectedCuisine = null;
                            _minRating = null;
                            _selectedPriceRange = null;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadPlaces(refresh: true);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Places',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPlaces(refresh: true),
        color: Theme.of(context).primaryColor,
        child: _places.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _places.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No food places found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Try adjusting your filters or search for something else',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadPlaces(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        )
            : NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoading &&
                _hasMorePages &&
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              _loadPlaces();
              return true;
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _places.length + (_hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _places.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildPlaceCard(_places[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodPlaceDetailsScreen(placeId: place.id),
                ),
              ).then((_) => _loadPlaces(refresh: true));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: place.images.isNotEmpty
                          ? Image.network(
                        place.images[0].url.startsWith('http')
                            ? place.images[0].url
                            : '${FoodService.baseUrl}${place.images[0].url}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // Rating badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
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
                              place.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Price range badge
                    if (place.priceRange.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            place.priceRange,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    // Favorite button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: FavoriteButton(
                          itemId: place.id,
                          itemType: 'food',
                          title: place.name,
                          imageUrl: place.images.isNotEmpty
                              ? place.images[0].url : '',
                          description: place.description,
                          city: place.city,
                          location: place.location,
                          category: place.type,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${place.address}, ${place.city}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.type,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (place.cuisines.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: place.cuisines.map((cuisine) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                cuisine.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}