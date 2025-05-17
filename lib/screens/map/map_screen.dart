import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/attraction.dart';
import '../../models/event.dart';
import '../../models/food.dart';
import '../../models/accommodation.dart';
import '../../services/attraction_service.dart';
import '../../services/event_service.dart';
import '../../services/food_service.dart';
import '../../services/accommodation_service.dart';
import '../accommodations/accommodation_details_screen.dart';
import '../food/food_place_details_screen.dart';

// Helper class to ensure locations are properly formatted
class LocationHelper {
  // Generate random location near default center
  static String generateRandomLocation(LatLng defaultCenter, int seed) {
    final random = math.Random(seed);
    final lat = defaultCenter.latitude + (random.nextDouble() - 0.5) * 0.01;
    final lng = defaultCenter.longitude + (random.nextDouble() - 0.5) * 0.01;
    return '$lat,$lng';
  }

  // Ensure all items have proper location data
  static List<dynamic> ensureLocations(
      List<dynamic> items, LatLng defaultCenter, String itemType) {
    return items.map((item) {
      // Check if location is empty or improperly formatted
      if (item.location == null ||
          item.location.isEmpty ||
          !item.location.contains(',')) {
        final seed = item.id.hashCode;
        final location = generateRandomLocation(defaultCenter, seed);

        // Create a new instance with proper location
        switch (itemType) {
          case 'event':
            return Event(
              id: item.id,
              title: item.title,
              description: item.description,
              location: location,
              address: item.address ?? '',
              link: item.link ?? '',
              category: item.category ?? '',
              capacity: item.capacity ?? 0,
              currentCount: item.currentCount ?? 0,
              startDate: item.startDate,
              endDate: item.endDate,
              imageUrl: item.imageUrl ?? '',
            );
          case 'food':
            return Place(
              id: item.id,
              name: item.name,
              description: item.description,
              location: location,
              city: item.city ?? '',
              address: item.address ?? '',
              type: item.type ?? '',
              priceRange: item.priceRange ?? '',
              isPublished: item.isPublished ?? true,
              phone: item.phone ?? '',
              website: item.website ?? '',
              images: item.images ?? [],
              cuisines: item.cuisines ?? [],
              dishes: item.dishes ?? [],
              reviews: item.reviews ?? [],
            );
          case 'accommodation':
            return Accommodation(
              id: item.id,
              name: item.name,
              description: item.description,
              location: location,
              city: item.city ?? '',
              address: item.address ?? '',
              type: item.type ?? '',
              adminId: item.adminId ?? 0,
              website: item.website ?? '',
              isPublished: item.isPublished ?? true,
              amenities: item.amenities ?? [],
              images: item.images ?? [],
              roomTypes: item.roomTypes ?? [],
              reviews: item.reviews ?? [],
            );
          default:
            return item;
        }
      }
      return item;
    }).toList();
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition? _initialCameraPosition;

  // Markers and data
  Set<Marker> _markers = {};
  List<Attraction> _attractions = [];
  List<Event> _events = [];
  List<Place> _foodPlaces = [];
  List<Accommodation> _accommodations = [];
  bool _showAttractions = true;
  bool _showEvents = true;
  bool _showFood = true;
  bool _showAccommodations = true;

  // User location
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  bool _isLoading = true;

  // Search and filter values
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String? _selectedCategory;
  final AccommodationService _accommodationService = AccommodationService();

  // For marker icons
  final FoodService _foodService = FoodService();

  @override
  void initState() {
    super.initState();
    _determinePosition();

    _searchController.addListener(_onSearchChanged);
  }

  // Initialize everything once we have position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permissions are permanently denied. Enable them in settings.'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition = CameraPosition(
        target: _currentLocation!,
        zoom: 14.0,
      );
    });

    // Start continuous location updates
    _startLocationUpdates();

    // Load data
    await _loadData();
  }

  Future<void> _startLocationUpdates() async {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      await _updateCurrentLocationMarker();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load attractions
      _attractions = await AttractionService.fetchAttractions();
      print('✅ Loaded ${_attractions.length} attractions');

      // Load events
      try {
        _events = await EventService.fetchUpcomingEvents();
        print('✅ Loaded ${_events.length} events');

        if (_currentLocation != null) {
          _events = LocationHelper.ensureLocations(
                  _events, _currentLocation!, 'event')
              .cast<Event>();
        }
      } catch (eventError) {
        print('❌ Error loading events: $eventError');
        _events = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $eventError')),
        );
      }

      // Load food places
      // For loading food places
      // Load food places
      try {
        final foodService = FoodService();
        _foodPlaces = await foodService.fetchPlaces();
        print('✅ Loaded ${_foodPlaces.length} food places');

        // Debug food places data
        for (var place in _foodPlaces) {
          print('🍕 Food place: ${place.name}, Location: ${place.location}');
        }

        // Ensure all food places have valid location data
        if (_currentLocation != null) {
          _foodPlaces = LocationHelper.ensureLocations(
              _foodPlaces, _currentLocation!, 'food').cast<Place>();

          // Verify locations after fixing
          for (var place in _foodPlaces) {
            print('✓ Fixed food place: ${place.name}, Location: ${place.location}');
          }
        }
      } catch (foodError) {
        print('❌ Error loading food places: $foodError');
        _foodPlaces = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load food places: $foodError')),
        );
      }

      // Load accommodations
      try {
        _accommodations = await _accommodationService.getAccommodations();
        print('✅ Loaded ${_accommodations.length} accommodations');

        if (_currentLocation != null) {
          _accommodations = LocationHelper.ensureLocations(
                  _accommodations, _currentLocation!, 'accommodation')
              .cast<Accommodation>();
        }
      } catch (accomError) {
        print('❌ Error loading accommodations: $accomError');
        _accommodations = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accommodations: $accomError')),
        );
      }

      // Create markers
      await _updateMarkers();
    } catch (e) {
      print('❌ Error in _loadData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load map data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Count the number of matches for the current search query
  int _countSearchMatches() {
    if (_searchQuery.isEmpty) {
      return 0; // No active search
    }

    final query = _searchQuery.toLowerCase();
    int count = 0;

    // Count matching attractions
    if (_showAttractions) {
      for (var attraction in _attractions) {
        if (_selectedCategory != null &&
            attraction.category != _selectedCategory) {
          continue;
        }

        final title = attraction.title.toLowerCase();
        final description = attraction.description.toLowerCase();
        final category = attraction.category.toLowerCase();
        final city = attraction.city.toLowerCase();

        if (title.contains(query) ||
            description.contains(query) ||
            category.contains(query) ||
            city.contains(query)) {
          count++;
        }
      }
    }

    // Count matching events
    if (_showEvents) {
      for (var event in _events) {
        if (_selectedCategory != null && event.category != _selectedCategory) {
          continue;
        }

        final title = event.title.toLowerCase();
        final description = event.description.toLowerCase();
        final category = event.category.toLowerCase();
        final location = event.location.toLowerCase();

        if (title.contains(query) ||
            description.contains(query) ||
            category.contains(query) ||
            location.contains(query)) {
          count++;
        }
      }
    }

    // Count matching food places
    if (_showFood) {
      for (var place in _foodPlaces) {
        if (_selectedCategory != null && place.type != _selectedCategory) {
          continue;
        }

        final name = place.name.toLowerCase();
        final description = place.description.toLowerCase();
        final type = place.type.toLowerCase();
        final city = place.city.toLowerCase();

        if (name.contains(query) ||
            description.contains(query) ||
            type.contains(query) ||
            city.contains(query)) {
          count++;
        }
      }
    }

    // Count matching accommodations
    if (_showAccommodations) {
      for (var accommodation in _accommodations) {
        if (_selectedCategory != null &&
            accommodation.type != _selectedCategory) {
          continue;
        }

        final name = accommodation.name.toLowerCase();
        final description = accommodation.description.toLowerCase();
        final type = accommodation.type.toLowerCase();
        final city = accommodation.city.toLowerCase();

        if (name.contains(query) ||
            description.contains(query) ||
            type.contains(query) ||
            city.contains(query)) {
          count++;
        }
      }
    }

    return count;
  }

  // Updates all markers based on current filters and toggles
  Future<void> _updateMarkers() async {
    if (_currentLocation == null) return;

    Set<Marker> newMarkers = {};

    // Add current location marker
    newMarkers.add(await _createCurrentLocationMarker());

    // Add attraction markers if enabled
    if (_showAttractions) {
      for (var attraction in _attractions) {
        // Skip if category filter is active and doesn't match
        if (_selectedCategory != null &&
            attraction.category != _selectedCategory) {
          continue;
        }

        // Skip if search filter is active and doesn't match
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = attraction.title.toLowerCase();
          final description = attraction.description.toLowerCase();
          final category = attraction.category.toLowerCase();
          final city = attraction.city.toLowerCase();

          if (!title.contains(query) &&
              !description.contains(query) &&
              !category.contains(query) &&
              !city.contains(query)) {
            continue;
          }
        }

        LatLng? location = _parseLocation(attraction.location);
        if (location != null) {
          final marker = await _createAttractionMarker(attraction, location);
          newMarkers.add(marker);
        }
      }
    }

    // Add event markers if enabled
    if (_showEvents) {
      print('📍 Attempting to add ${_events.length} event markers');
      int eventMarkersAdded = 0;

      for (var event in _events) {
        // Skip if category filter is active and doesn't match
        if (_selectedCategory != null && event.category != _selectedCategory) {
          continue;
        }

        // Skip if search filter is active and doesn't match
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = event.title.toLowerCase();
          final description = event.description.toLowerCase();
          final category = event.category.toLowerCase();
          final location = event.location.toLowerCase();

          if (!title.contains(query) &&
              !description.contains(query) &&
              !category.contains(query) &&
              !location.contains(query)) {
            continue;
          }
        }

        // Debug info for this event
        print('📍 Processing event: ${event.id} - ${event.title}');
        print('📍 Event location string: "${event.location}"');

        LatLng? location = _parseLocation(event.location);
        if (location != null) {
          final marker = await _createEventMarker(event, location);
          newMarkers.add(marker);
          eventMarkersAdded++;
          print('✅ Added event marker for: ${event.title}');
        } else {
          print('❌ Failed to create marker for event: ${event.title}');
        }
      }

      print('📍 Successfully added $eventMarkersAdded event markers');
    }

    // Add food place markers if enabled
// Add food place markers if enabled
    if (_showFood) {
      print('🍕 Attempting to add ${_foodPlaces.length} food place markers');
      int foodMarkersAdded = 0;

      for (var place in _foodPlaces) {
        // Skip if category filter is active and doesn't match
        if (_selectedCategory != null &&
            (place.type != _selectedCategory &&
                !place.cuisines.any((c) => c.name == _selectedCategory))) {
          continue;
        }

        // Skip if search filter is active and doesn't match
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = place.name.toLowerCase();
          final description = place.description.toLowerCase();
          final type = place.type.toLowerCase();
          final city = place.city.toLowerCase();

          if (!name.contains(query) &&
              !description.contains(query) &&
              !type.contains(query) &&
              !city.contains(query)) {
            continue;
          }
        }

        print('🍕 Processing food place: ${place.id} - ${place.name}');
        print('🍕 Food location string: "${place.location}"');

        // If location is empty, generate a random one near current location
        if (place.location.isEmpty || !place.location.contains(',')) {
          final random = math.Random(place.id.hashCode);
          final lat = _currentLocation!.latitude + (random.nextDouble() - 0.5) * 0.01;
          final lng = _currentLocation!.longitude + (random.nextDouble() - 0.5) * 0.01;
          final location = LatLng(lat, lng);
          print('🍕 Generated random location for ${place.name}: $lat,$lng');

          final marker = await _createFoodMarker(place, location);
          newMarkers.add(marker);
          foodMarkersAdded++;
          print('✅ Added food marker for: ${place.name} (random location)');
        } else {
          LatLng? location = _parseLocation(place.location);
          if (location != null) {
            final marker = await _createFoodMarker(place, location);
            newMarkers.add(marker);
            foodMarkersAdded++;
            print('✅ Added food marker for: ${place.name}');
          } else {
            print('❌ Failed to parse location for food place: ${place.name}');

            // Attempt to fix the location format
            final parts = place.location.split(RegExp(r'[,\s-]+')).where((p) => p.isNotEmpty).toList();
            if (parts.length >= 2) {
              try {
                final lat = double.parse(parts[0]);
                final lng = double.parse(parts[1]);
                final location = LatLng(lat, lng);

                print('🔧 Fixed location for ${place.name}: $lat,$lng');

                final marker = await _createFoodMarker(place, location);
                newMarkers.add(marker);
                foodMarkersAdded++;
                print('✅ Added food marker for: ${place.name} (fixed format)');
              } catch (e) {
                // Fallback: generate a random location
                final random = math.Random(place.id.hashCode);
                final lat = _currentLocation!.latitude + (random.nextDouble() - 0.5) * 0.01;
                final lng = _currentLocation!.longitude + (random.nextDouble() - 0.5) * 0.01;
                final location = LatLng(lat, lng);

                print('🍕 Generated random location for ${place.name}: $lat,$lng');

                final marker = await _createFoodMarker(place, location);
                newMarkers.add(marker);
                foodMarkersAdded++;
                print('✅ Added food marker for: ${place.name} (random fallback)');
              }
            }
          }
        }
      }

      print('🍕 Successfully added $foodMarkersAdded food place markers');
    }
    // Add accommodation markers if enabled
    if (_showAccommodations) {
      print(
          '📍 Attempting to add ${_accommodations.length} accommodation markers');
      int accommodationMarkersAdded = 0;

      for (var accommodation in _accommodations) {
        // Skip if category filter is active and doesn't match
        if (_selectedCategory != null &&
            accommodation.type != _selectedCategory) {
          continue;
        }

        // Skip if search filter is active and doesn't match
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = accommodation.name.toLowerCase();
          final description = accommodation.description.toLowerCase();
          final type = accommodation.type.toLowerCase();
          final city = accommodation.city.toLowerCase();

          if (!name.contains(query) &&
              !description.contains(query) &&
              !type.contains(query) &&
              !city.contains(query)) {
            continue;
          }
        }

        LatLng? location = _parseLocation(accommodation.location);
        if (location != null) {
          final marker =
              await _createAccommodationMarker(accommodation, location);
          newMarkers.add(marker);
          accommodationMarkersAdded++;
          print('✅ Added accommodation marker for: ${accommodation.name}');
        } else {
          print(
              '❌ Failed to create marker for accommodation: ${accommodation.name}');
        }
      }

      print(
          '📍 Successfully added $accommodationMarkersAdded accommodation markers');
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Future<Marker> _createCurrentLocationMarker() async {
    return Marker(
      markerId: const MarkerId('current_location'),
      position: _currentLocation!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(
        title: 'Your Location',
      ),
      zIndex: 2,
    );
  }

  Future<void> _updateCurrentLocationMarker() async {
    if (_currentLocation == null) return;

    final updatedMarkers =
        _markers.where((m) => m.markerId.value != 'current_location').toSet();

    updatedMarkers.add(await _createCurrentLocationMarker());

    setState(() {
      _markers = updatedMarkers;
    });
  }

  Future<Marker> _createAttractionMarker(
      Attraction attraction, LatLng position) async {
    return Marker(
      markerId: MarkerId('attraction_${attraction.id}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: attraction.title,
        snippet: attraction.city,
        onTap: () => _showAttractionDetails(attraction),
      ),
    );
  }

  Future<Marker> _createEventMarker(Event event, LatLng position) async {
    return Marker(
      markerId: MarkerId('event_${event.id}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
        title: event.title,
        snippet:
            '${event.startDate.day}/${event.startDate.month} - ${event.category}',
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Future<Marker> _createFoodMarker(Place place, LatLng position) async {
    return Marker(
      markerId: MarkerId('food_${place.id}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: place.name,
        snippet: '${place.type} - ${place.priceRange}',
        onTap: () => _showFoodDetails(place),
      ),
    );
  }

  Future<Marker> _createAccommodationMarker(
      Accommodation accommodation, LatLng position) async {
    return Marker(
      markerId: MarkerId('accommodation_${accommodation.id}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow: InfoWindow(
        title: accommodation.name,
        snippet: '${accommodation.type} - ${accommodation.city}',
        onTap: () => _showAccommodationDetails(accommodation),
      ),
    );
  }

  LatLng? _parseLocation(String? location) {
    // Guard against null or empty location strings
    if (location == null || location.isEmpty) {
      print('⚠️ Empty or null location string');
      return null;
    }

    try {
      // First try normal comma-separated format
      if (location.contains(',')) {
        final parts = location.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          return LatLng(lat, lng);
        }
      }
      // Try dash-separated format as fallback
      else if (location.contains('-')) {
        final parts = location.split('-');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          return LatLng(lat, lng);
        }
      }
      // Try space-separated format as another fallback
      else if (location.contains(' ')) {
        final parts = location.split(' ');
        if (parts.length >= 2) {
          // Extract the first two non-empty parts
          final nonEmptyParts = parts.where((p) => p.trim().isNotEmpty).toList();
          if (nonEmptyParts.length >= 2) {
            final lat = double.parse(nonEmptyParts[0].trim());
            final lng = double.parse(nonEmptyParts[1].trim());
            return LatLng(lat, lng);
          }
        }
      }

      print('⚠️ Invalid location format: $location');
    } catch (e) {
      print('⚠️ Error parsing location: $e for string: $location');
    }
    return null;
  }
  void _showAttractionDetails(Attraction attraction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Stack(
              children: [
                // Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        attraction.imageUrl.isNotEmpty
                            ? attraction.imageUrl
                            : 'https://via.placeholder.com/400x200?text=No+Image',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay and back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border,
                                color: Colors.white),
                            onPressed: () {
                              // Add to favorites functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category chip
                Positioned(
                  top: 20,
                  right: 20,
                  child: Chip(
                    label: Text(
                      attraction.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${attraction.address}, ${attraction.city}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attraction.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Open directions
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add to Plan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Add to plan
                            },
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
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Stack(
              children: [
                // Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        event.imageUrl.isNotEmpty
                            ? event.imageUrl
                            : 'https://via.placeholder.com/400x200?text=No+Image',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay and back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.white),
                            onPressed: () {
                              // Add to calendar functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category chip
                Positioned(
                  top: 20,
                  right: 20,
                  child: Chip(
                    label: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.purple.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentCount}/${event.capacity} attending',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Open directions
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add to Plan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Add to plan
                            },
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
  }

  void _showFoodDetails(Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Stack(
              children: [
                // Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        place.images.isNotEmpty
                            ? place.images.first.url.startsWith('http')
                                ? place.images.first.url
                                : '${_foodService.getBaseUrl()}${place.images.first.url}'
                            : 'https://via.placeholder.com/400x200?text=No+Image',
                      ),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Placeholder shown by default in case of error
                      },
                    ),
                  ),
                ),
                // Overlay and back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border,
                                color: Colors.white),
                            onPressed: () {
                              // Add to favorites functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Type & price range chips
                Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(
                          place.type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.orange.withOpacity(0.8),
                      ),
                      if (place.priceRange.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Chip(
                            label: Text(
                              place.priceRange,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.orange.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${place.address}, ${place.city}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (place.phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            place.phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (place.website.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.public,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.website,
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (place.cuisines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: place.cuisines
                            .map((cuisine) => Chip(
                                  label: Text(cuisine.name),
                                  backgroundColor: Colors.orange[100],
                                  labelStyle:
                                      TextStyle(color: Colors.orange[800]),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Open directions
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Full Menu'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // View full menu or navigate to food details screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FoodPlaceDetailsScreen(placeId: place.id),
                                ),
                              );
                            },
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
  }

  void _showAccommodationDetails(Accommodation accommodation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Stack(
              children: [
                // Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        accommodation.images.isNotEmpty
                            ? accommodation.images.first.url.startsWith('http')
                                ? accommodation.images.first.url
                                : '${_accommodationService.baseUrl}${accommodation.images.first.url}'
                            : 'https://via.placeholder.com/400x200?text=No+Image',
                      ),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Placeholder shown by default in case of error
                      },
                    ),
                  ),
                ),
                // Overlay and back button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border,
                                color: Colors.white),
                            onPressed: () {
                              // Add to favorites functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Type chip
                Positioned(
                  top: 20,
                  right: 20,
                  child: Chip(
                    label: Text(
                      accommodation.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.cyan.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accommodation.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${accommodation.address}, ${accommodation.city}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (accommodation.website.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.public,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              accommodation.website,
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Starting price if available from room types
                    if (accommodation.roomTypes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Starting from ${accommodation.startingPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Amenities chips
                    if (accommodation.amenities.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: accommodation.amenities
                            .take(5)
                            .map((amenity) => Chip(
                                  label: Text(amenity),
                                  backgroundColor: Colors.cyan[100],
                                  labelStyle:
                                      TextStyle(color: Colors.cyan[800]),
                                ))
                            .toList(),
                      ),
                      if (accommodation.amenities.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '+${accommodation.amenities.length - 5} more amenities',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      accommodation.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Open directions
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.hotel),
                            label: const Text('View Rooms'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.cyan,
                              side: BorderSide(color: Colors.cyan),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // Navigate to accommodation details screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AccommodationDetailsScreen(
                                    accommodationId: accommodation.id,
                                  ),
                                ),
                              );
                            },
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
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  // Move camera to current location
  Future<void> _goToCurrentLocation() async {
    if (_currentLocation == null) return;

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _currentLocation!,
        zoom: 15.0,
      ),
    ));
  }

  // Move camera to show all markers (useful after search)
  Future<void> _zoomToShowAllMarkers() async {
    if (_markers.isEmpty || _markers.length <= 1) {
      // If no markers or only current location marker, go to user location
      _goToCurrentLocation();
      return;
    }

    // Calculate bounds
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    // Add padding to the bounds
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Create bounds
    final southwest = LatLng(minLat, minLng);
    final northeast = LatLng(maxLat, maxLng);
    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    // Animate camera to show all markers
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  void _onSearchChanged() {
    final String newQuery = _searchController.text;

    // Only update if the query has actually changed
    if (_searchQuery != newQuery) {
      setState(() {
        _searchQuery = newQuery;
      });

      // Update markers based on new search query
      _updateMarkers().then((_) {
        // If we have search results, zoom to show them all
        if (_searchQuery.isNotEmpty && _countSearchMatches() > 0) {
          _zoomToShowAllMarkers();
        }
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      // Show loading state until we have initial position
      return Scaffold(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition!,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _markers,
            onMapCreated: _onMapCreated,
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // Top bar with search
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top toolbar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            _isSearching ? 'Search Map' : 'Explore Map',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isSearching ? Icons.close : Icons.search),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search bar (shown conditionally)
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search attractions, events, food and more...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (value) {
                          // This will trigger _onSearchChanged via the listener
                          _updateMarkers();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Search results indicator (shown when searching)
          if (_searchQuery.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  (_isSearching ? 110 : 60),
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        size: 18, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing ${_countSearchMatches()} results for "$_searchQuery"',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: _zoomToShowAllMarkers,
                      child: const Text('See All'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom filter bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Recenter button
                FloatingActionButton(
                  heroTag: 'recenterBtn',
                  mini: true,
                  onPressed: _goToCurrentLocation,
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),

                // Main filter card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Filter Map',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Attractions toggle
                            FilterChip(
                              label: const Text('Attractions'),
                              selected: _showAttractions,
                              onSelected: (selected) {
                                setState(() {
                                  _showAttractions = selected;
                                });
                                _updateMarkers();
                              },
                              avatar: Icon(
                                Icons.place,
                                color: _showAttractions
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 16,
                              ),
                              selectedColor: Colors.red[400],
                              checkmarkColor: Colors.white,
                            ),
                            // Events toggle
                            FilterChip(
                              label: const Text('Events'),
                              selected: _showEvents,
                              onSelected: (selected) {
                                setState(() {
                                  _showEvents = selected;
                                });
                                _updateMarkers();
                              },
                              avatar: Icon(
                                Icons.event,
                                color: _showEvents
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 16,
                              ),
                              selectedColor: Colors.purple[400],
                              checkmarkColor: Colors.white,
                            ),
                            // Food toggle
                            FilterChip(
                              label: const Text('Food'),
                              selected: _showFood,
                              onSelected: (selected) {
                                setState(() {
                                  _showFood = selected;
                                });
                                _updateMarkers();
                              },
                              avatar: Icon(
                                Icons.restaurant,
                                color:
                                    _showFood ? Colors.white : Colors.grey[600],
                                size: 16,
                              ),
                              selectedColor: Colors.orange[400],
                              checkmarkColor: Colors.white,
                            ),
                            // Accommodations toggle
                            FilterChip(
                              label: const Text('Accommodations'),
                              selected: _showAccommodations,
                              onSelected: (selected) {
                                setState(() {
                                  _showAccommodations = selected;
                                });
                                _updateMarkers();
                              },
                              avatar: Icon(
                                Icons.hotel,
                                color: _showAccommodations
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 16,
                              ),
                              selectedColor: Colors.cyan[400],
                              checkmarkColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      // Category filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            // All categories option
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _updateMarkers();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                            ),
                            const SizedBox(width: 8),
                            // Sample categories - replace with your actual categories
                            ...[
                              'Museum',
                              'Park',
                              'Monument',
                              'Restaurant',
                              'Hotel',
                              'Resort',
                              'Café',
                              'Entertainment',
                              'Historical',
                              'Nature',
                              'Shopping'
                            ].map((category) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: _selectedCategory == category,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCategory =
                                            _selectedCategory == category
                                                ? null
                                                : category;
                                      });
                                      _updateMarkers();
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.2),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
