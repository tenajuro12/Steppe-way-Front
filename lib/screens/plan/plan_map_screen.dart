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
  late GoogleMapController _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  MapType _mapType = MapType.normal;
  bool _showingInfoPanel = false;
  PlanItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _createMarkersAndPolylines();
  }

  void _createMarkersAndPolylines() {
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
            snippet: _formatSnippet(item),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              item.itemType == 'attraction'
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueBlue
          ),
          onTap: () {
            setState(() {
              _selectedItem = item;
              _showingInfoPanel = true;
            });
          },
        );

        setState(() {
          _markers[markerId] = marker;
        });
      } catch (e) {
        print('Error parsing location for item ${item.id}: $e');
      }
    }


    if (routePoints.length >= 2) {
      final polylineId = PolylineId('route');
      final polyline = Polyline(
        polylineId: polylineId,
        points: routePoints,
        color: Colors.blue,
        width: 5,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      );

      setState(() {
        _polylines[polylineId] = polyline;
      });
    }
  }

  String _formatSnippet(PlanItem item) {
    if (item.scheduledFor != null) {
      final timeFormat = DateFormat('h:mm a');
      return '${timeFormat.format(item.scheduledFor!)} • ${item.formattedDuration}';
    }
    return item.formattedDuration;
  }

  @override
  Widget build(BuildContext context) {

    final LatLng initialPosition = _markers.isEmpty
        ? const LatLng(51.1605, 71.4704)
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
            mapType: _mapType, // Use the state variable here
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
            zoomControlsEnabled: false, // We'll add our own
            onTap: (_) {
              setState(() {
                _showingInfoPanel = false;
              });
            },
          ),
          // Custom zoom controls
          Positioned(
            right: 16,
            bottom: _showingInfoPanel ? 240 : 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  child: const Icon(Icons.add),
                  onPressed: () {
                    _mapController.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ],
            ),
          ),
          // Fit bounds button
          Positioned(
            left: 16,
            bottom: _showingInfoPanel ? 240 : 16,
            child: FloatingActionButton(
              heroTag: "fit_bounds",
              child: const Icon(Icons.center_focus_strong),
              onPressed: _fitBounds,
            ),
          ),
          // Info panel for selected location
          if (_showingInfoPanel && _selectedItem != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildInfoPanel(_selectedItem!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(PlanItem item) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle for dragging
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.itemType == 'attraction'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.itemType == 'attraction' ? Icons.place : Icons.event,
                    color: item.itemType == 'attraction' ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.scheduledFor != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(item.scheduledFor!),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(item.scheduledFor!),
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showingInfoPanel = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description.isNotEmpty) ...[
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${item.formattedDuration}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                            item.address.isNotEmpty ? item.address : item.location,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notes:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.notes,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('DIRECTIONS'),
                  onPressed: () {
                    // You would implement opening directions in Google Maps here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening directions in Google Maps...')),
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('EDIT'),
                  onPressed: () {
                    // You would implement edit functionality here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality would open here')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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