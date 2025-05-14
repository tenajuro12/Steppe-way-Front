// lib/screens/accommodations/accommodations_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/accommodation.dart';
import '../../services/accommodation_service.dart';
import 'accommodation_card.dart';
import 'accommodation_details_screen.dart';
import 'accommodation_search.dart';


class AccommodationsListScreen extends StatefulWidget {
  final String? city;
  final String? type;

  const AccommodationsListScreen({
    Key? key,
    this.city,
    this.type,
  }) : super(key: key);

  @override
  _AccommodationsListScreenState createState() => _AccommodationsListScreenState();
}

class _AccommodationsListScreenState extends State<AccommodationsListScreen> {
  final AccommodationService _accommodationService = AccommodationService();
  late Future<List<Accommodation>> _accommodationsFuture;
  bool _isLoading = false;
  String? _selectedType;
  List<String> _accommodationTypes = [
    'All Types',
    'Hotel',
    'Apartment',
    'Villa',
    'Resort',
    'Guesthouse',
    'Hostel',
    'Motel',
    'Cottage',
    'Cabin',
  ];
  double? _minPrice;
  double? _maxPrice;
  int _currentPage = 1;
  List<Accommodation> _accommodations = [];
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type ?? 'All Types';
    _loadAccommodations();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (!_isLoading && _hasMorePages) {
          _loadMoreAccommodations();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAccommodations({bool refresh = false}) async {
    setState(() {
      if (refresh) {
        _currentPage = 1;
        _accommodations = [];
        _hasMorePages = true;
      }
      _isLoading = true;
    });

    try {
      final accommodations = await _accommodationService.getAccommodations(
        city: widget.city,
        type: _selectedType != 'All Types' ? _selectedType : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        page: _currentPage,
      );

      setState(() {
        if (accommodations.isEmpty) {
          _hasMorePages = false;
        } else {
          _accommodations.addAll(accommodations);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading accommodations: $e')),
      );
    }
  }

  Future<void> _loadMoreAccommodations() async {
    await _loadAccommodations();
  }

  Future<void> _refreshAccommodations() async {
    await _loadAccommodations(refresh: true);
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Accommodations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Accommodation Type Filter
                  Text(
                    'Accommodation Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _accommodationTypes.length,
                      itemBuilder: (context, index) {
                        final type = _accommodationTypes[index];
                        final isSelected = _selectedType == type;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = selected ? type : 'All Types';
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  // Price Range Filter
                  Text(
                    'Price Range (Per Night)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Min Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _minPrice = double.tryParse(value);
                              });
                            } else {
                              setState(() {
                                _minPrice = null;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Max Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _maxPrice = double.tryParse(value);
                              });
                            } else {
                              setState(() {
                                _maxPrice = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Apply and Reset Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = 'All Types';
                            _minPrice = null;
                            _maxPrice = null;
                          });
                        },
                        child: Text('Reset Filters'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _refreshAccommodations();
                        },
                        child: Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
// Add these variables to your state class
  String _sortBy = 'Price: Low to High';
  int? _minRating;

// Add this method to your state class
  void _sortAccommodations() {
    if (_accommodations.isEmpty) return;

    setState(() {
      switch (_sortBy) {
        case 'Price: Low to High':
          _accommodations.sort((a, b) {
            double priceA = _getLowestPrice(a);
            double priceB = _getLowestPrice(b);
            return priceA.compareTo(priceB);
          });
          break;

        case 'Price: High to Low':
          _accommodations.sort((a, b) {
            double priceA = _getLowestPrice(a);
            double priceB = _getLowestPrice(b);
            return priceB.compareTo(priceA);
          });
          break;

        case 'Rating':
          _accommodations.sort((a, b) {
            double ratingA = _getAverageRating(a);
            double ratingB = _getAverageRating(b);
            return ratingB.compareTo(ratingA); // Higher ratings first
          });
          break;

        case 'Popularity':
          _accommodations.sort((a, b) {
            int reviewsA = a.reviews.length;
            int reviewsB = b.reviews.length;
            return reviewsB.compareTo(reviewsA); // More reviews first
          });
          break;
      }
    });
  }

  double _getLowestPrice(Accommodation accommodation) {
    if (accommodation.roomTypes.isEmpty) {
      return double.infinity; // Put accommodations without prices at the end
    }

    double? lowestPrice;
    for (final roomType in accommodation.roomTypes) {
      if (lowestPrice == null || roomType.price < lowestPrice) {
        lowestPrice = roomType.price;
      }
    }

    return lowestPrice ?? double.infinity;
  }

  double _getAverageRating(Accommodation accommodation) {
    if (accommodation.reviews.isEmpty) {
      return 0;
    }

    double totalRating = 0;
    for (final review in accommodation.reviews) {
      totalRating += review.rating;
    }

    return totalRating / accommodation.reviews.length;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          widget.city != null ? 'Accommodations in ${widget.city}' : 'Accommodations',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality
              showSearch(
                context: context,
                delegate: AccommodationSearchDelegate(_accommodations),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAccommodations,
        color: Theme.of(context).primaryColor,
        child: Column(
          children: [
            // City name with gradient banner if provided
            if (widget.city != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_city, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          widget.city!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your perfect stay in ${widget.city}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // Accommodation type filter chips
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _accommodationTypes.length,
                itemBuilder: (context, index) {
                  final type = _accommodationTypes[index];
                  final isSelected = _selectedType == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        type,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : 'All Types';
                          _refreshAccommodations();
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      showCheckmark: false,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                },
              ),
            ),

            // Results count and active filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_accommodations.length} accommodations found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (_minPrice != null || _maxPrice != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                          _refreshAccommodations();
                        });
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Clear price filter'),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                ],
              ),
            ),

            // Sort options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('Sort by:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    items: ['Price: Low to High', 'Price: High to Low', 'Rating', 'Popularity']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortBy = newValue;
                          _sortAccommodations();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Accommodations list
            Expanded(
              child: _accommodations.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _accommodations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _accommodations.length + (_hasMorePages ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _accommodations.length) {
                    return _isLoading
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : const SizedBox.shrink();
                  }

                  final accommodation = _accommodations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AccommodationCard(
                      accommodation: accommodation,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccommodationDetailsScreen(
                            accommodationId: accommodation.id,
                          ),
                        ),
                      ).then((_) => _refreshAccommodations()),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFiltersSheet(context);
        },
        child: const Icon(Icons.tune),
        tooltip: 'Advanced Filters',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No accommodations found',
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
              'Try adjusting your filters or searching in a different area',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshAccommodations,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list),
                        const SizedBox(width: 8),
                        const Text(
                          'Advanced Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Reset all filters logic
                            Navigator.pop(context);
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Price range filter
                        const Text(
                          'Price Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RangeSlider(
                          values: RangeValues(
                            _minPrice?.toDouble() ?? 0.0,
                            _maxPrice?.toDouble() ?? 1000.0,
                          ),
                          min: 0.0,
                          max: 1000.0,
                          divisions: 20,
                          labels: RangeLabels(
                            '\$${_minPrice ?? 0}',
                            '\$${_maxPrice ?? 1000}',
                          ),
                          onChanged: (RangeValues values) {
                            // Update price range logic
                          },
                        ),

                        const SizedBox(height: 24),

                        // Amenities filter
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Wi-Fi',
                            'Swimming Pool',
                            'Free Parking',
                            'Air Conditioning',
                            'Restaurant',
                            'Fitness Center',
                            'Spa',
                            'Room Service',
                            'Pet Friendly',
                          ].map((amenity) => FilterChip(
                            label: Text(amenity),
                            selected: false, // Replace with actual state
                            onSelected: (bool selected) {
                              // Toggle amenity selection
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            showCheckmark: true,
                          )).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Guest rating filter
                        const Text(
                          'Guest Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRatingButton(3, 'Good 3+'),
                            _buildRatingButton(4, 'Very Good 4+'),
                            _buildRatingButton(5, 'Excellent 5'),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Apply button
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Apply filters logic
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingButton(int rating, String label) {
    final isSelected = _minRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _minRating = isSelected ? null : rating;
          _refreshAccommodations();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: isSelected ? Colors.white : Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}