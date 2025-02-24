import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  List<Marker> _markers = [];
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _loadAttractions(); // Load attractions when screen initializes
  }

  /// Starts real-time location updates
  Future<void> _startLocationUpdates() async {
    await _positionSubscription?.cancel();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _updateCurrentLocationMarker(); // ✅ Ensures the marker updates

      if (_mapReady && _currentLocation != null) {
        _mapController.move(_currentLocation!, 16.0);
      }
    });
  }

  /// Loads attraction markers from the service
  Future<void> _loadAttractions() async {
    try {
      final attractions = await AttractionService.fetchAttractions();
      setState(() {
        _markers = [
          if (_currentLocation != null) _buildCurrentLocationMarker(),
          ...attractions.map((attraction) {
            final coordinates = _parseLocation(attraction.location);
            if (coordinates != null) {
              return Marker(
                width: 60,
                height: 60,
                point: coordinates,
                child: GestureDetector(
                  onTap: () => _showAttractionDetails(attraction),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              );
            }
            return null;
          }).whereType<Marker>().toList(),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attractions: $e')),
      );
    }
  }

  /// Ensures the user's current location marker is always updated
  void _updateCurrentLocationMarker() {
    if (_currentLocation == null) return;

    setState(() {
      _markers = [
        _buildCurrentLocationMarker(), // Always add user's marker
        ..._markers.where((marker) => marker.point != _currentLocation), // Avoid duplicates
      ];
    });
  }

  /// Returns the current location marker
  Marker _buildCurrentLocationMarker() {
    return Marker(
      width: 50,
      height: 50,
      point: _currentLocation!,
      child: const Icon(
        Icons.my_location,
        color: Colors.blue,
        size: 30,
      ),
    );
  }

  /// Parses attraction coordinates from string "lat,lng"
  LatLng? _parseLocation(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('⚠️ Error parsing location: $e');
    }
    return null;
  }

  /// Displays details of an attraction in a bottom sheet
  void _showAttractionDetails(Attraction attraction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attraction.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(attraction.description),
            const SizedBox(height: 8),
            Text('City: ${attraction.city}'),
            Text('Address: ${attraction.address}'),
            const SizedBox(height: 8),
            if (attraction.imageUrl.isNotEmpty)
              Image.network(
                attraction.imageUrl,
                height: 150,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map with Attractions')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation!,
          initialZoom: 13.0,
          onMapReady: () {
            setState(() => _mapReady = true);
            _mapController.move(_currentLocation!, 13.0);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.travel_kz',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 16.0);
          }
        },
        tooltip: 'Recenter',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
