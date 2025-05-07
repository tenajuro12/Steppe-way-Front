import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/plan.dart';

class PlanMapScreen extends StatefulWidget {
  final Plan plan;

  const PlanMapScreen({Key? key, required this.plan}) : super(key: key);

  @override
  _PlanMapScreenState createState() => _PlanMapScreenState();
}

class _PlanMapScreenState extends State<PlanMapScreen> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  MapType _mapType = MapType.normal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _createMarkersAndRoute();
  }

  void _createMarkersAndRoute() {
    // Clear existing markers and polylines
    _markers.clear();

    // Sort items by order index
    final sortedItems = List<PlanItem>.from(widget.plan.items)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    List<LatLng> routePoints = [];

    for (int i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];

      // Skip items without valid location data
      if (item.location.isEmpty) continue;

      // Parse location string (assuming format is "lat, lng")
      final List<String> locationParts = item.location.split(',');
      if (locationParts.length != 2) continue;

      try {
        final double lat = double.parse(locationParts[0].trim());
        final double lng = double.parse(locationParts[1].trim());
        final position = LatLng(lat, lng);
        routePoints.add(position);

        final markerId = MarkerId(item.id?.toString() ?? i.toString());

        // Create marker
        final marker = Marker(
          markerId: markerId,
          position: position,
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.description.length > 30
                ? '${item.description.substring(0, 30)}...'
                : item.description,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              item.itemType == 'attraction'
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueBlue
          ),
        );

        setState(() {
          _markers[markerId] = marker;
        });
      } catch (e) {
        print('Error parsing location for item ${item.id}: $e');
      }
    }

    // Create a polyline if we have at least 2 points
    if (routePoints.length >= 2) {
      final polylineId = PolylineId('route');
      final polyline = Polyline(
        polylineId: polylineId,
        points: routePoints,
        color: Colors.blue,
        width: 5,
        patterns: [
          PatternItem.dash(15),
          PatternItem.gap(10),
        ],
      );

      setState(() {
        _polylines[polylineId] = polyline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default to Astana if no valid markers
    final LatLng initialPosition = _markers.isEmpty
        ? const LatLng(51.1605, 71.4704) // Astana coordinates
        : _markers.values.first.position;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plan.title} Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapTypeSelector,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _mapType,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 12.0,
            ),
            markers: Set<Marker>.of(_markers.values),
            polylines: Set<Polyline>.of(_polylines.values),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              if (_markers.isNotEmpty) {
                _fitBounds();
              }
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: true,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.center_focus_strong),
        onPressed: _fitBounds,
      ),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Normal'),
              onTap: () {
                setState(() {
                  _mapType = MapType.normal;
                });
                _mapController?.setMapStyle(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              onTap: () {
                setState(() {
                  _mapType = MapType.satellite;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Terrain'),
              onTap: () {
                setState(() {
                  _mapType = MapType.terrain;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Hybrid'),
              onTap: () {
                setState(() {
                  _mapType = MapType.hybrid;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final marker in _markers.values) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        50, // padding in pixels
      ),
    );
  }
}