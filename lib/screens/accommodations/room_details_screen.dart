// lib/screens/accommodations/room_details_screen.dart
import 'package:flutter/material.dart';
import '../../models/accommodation.dart';
import '../../services/accommodation_service.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String accommodationName;
  final RoomType roomType;

  const RoomDetailsScreen({
    Key? key,
    required this.accommodationName,
    required this.roomType,
  }) : super(key: key);

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final AccommodationService _service = AccommodationService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Image and header section
          Stack(
            children: [
              // Room image
              SizedBox(
                height: 240,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.roomType.images.isEmpty ? 1 : widget.roomType.images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return widget.roomType.images.isEmpty
                        ? Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.hotel_outlined,
                        size: 80,
                        color: Colors.grey[500],
                      ),
                    )
                        : Image.network(
                      widget.roomType.images[index].url.startsWith('http')
                          ? widget.roomType.images[index].url
                          : '${_service.baseUrl}${widget.roomType.images[index].url}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.hotel_outlined,
                            size: 80,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Share button
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      // Share functionality
                    },
                  ),
                ),
              ),

              // Dots indicator for images
              if (widget.roomType.images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.roomType.images.length,
                          (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Room header card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roomType.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.accommodationName.isNotEmpty)
                        Text(
                          'at ${widget.accommodationName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.roomType.formattedPrice,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rest of the details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room specs
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecItem(
                          Icons.people_alt_outlined,
                          'Max Guests',
                          '${widget.roomType.maxGuests} ${widget.roomType.maxGuests == 1 ? 'person' : 'persons'}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSpecItem(
                          Icons.bed_outlined,
                          'Bed Type',
                          widget.roomType.bedType,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (widget.roomType.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.roomType.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Room Amenities
                  const Text(
                    'Room Amenities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amenities list
                  if (widget.roomType.amenities.isEmpty)
                    Text(
                      'No amenities listed for this room',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: widget.roomType.amenities.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getAmenityIcon(widget.roomType.amenities[index]),
                                color: Colors.deepPurple,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.roomType.amenities[index],
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper method to get appropriate icon for amenity
  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();

    if (amenityLower.contains('wifi') || amenityLower.contains('internet')) {
      return Icons.wifi;
    } else if (amenityLower.contains('tv') || amenityLower.contains('television')) {
      return Icons.tv;
    } else if (amenityLower.contains('bath') || amenityLower.contains('shower')) {
      return Icons.bathtub;
    } else if (amenityLower.contains('breakfast') || amenityLower.contains('food')) {
      return Icons.restaurant;
    } else if (amenityLower.contains('conditioning') || amenityLower.contains('ac')) {
      return Icons.ac_unit;
    } else if (amenityLower.contains('service')) {
      return Icons.room_service;
    } else if (amenityLower.contains('view')) {
      return Icons.landscape;
    } else if (amenityLower.contains('balcony') || amenityLower.contains('terrace')) {
      return Icons.balcony;
    } else if (amenityLower.contains('fridge') || amenityLower.contains('refrigerator')) {
      return Icons.kitchen;
    } else if (amenityLower.contains('safe')) {
      return Icons.lock;
    } else if (amenityLower.contains('fan')) {
      return Icons.wind_power;
    } else if (amenityLower.contains('coffee')) {
      return Icons.coffee;
    } else if (amenityLower.contains('iron')) {
      return Icons.iron;
    }

    return Icons.check_circle_outline;
  }
}