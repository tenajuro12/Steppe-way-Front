import 'package:flutter/material.dart';

import '../../models/accommodation.dart';
import '../../widgets/favorite_button.dart';

class AccommodationCard extends StatelessWidget {
  final Accommodation accommodation;
  final VoidCallback onTap;

  const AccommodationCard({
    Key? key,
    required this.accommodation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use your existing code structure but with modern styling
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with stacked elements
            Stack(
              children: [
                // Image container with fixed height
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: accommodation.images.isNotEmpty
                      ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      'http://10.0.2.2:8080${accommodation.images[0].url}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $error");
                        return Center(
                          child: Icon(
                            Icons.hotel,
                            size: 50,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Icon(
                      Icons.hotel,
                      size: 50,
                      color: Colors.grey[500],
                    ),
                  ),
                ),

                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      accommodation.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Price badge
                if (accommodation.roomTypes.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLowestPrice(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                      itemId: accommodation.id,
                      itemType: 'accommodation',
                      title: accommodation.name,
                      imageUrl: accommodation.images.isNotEmpty
                          ? 'http://10.0.2.2:8080${accommodation.images[0].url}'
                          : '',
                      description: accommodation.description,
                      city: accommodation.city,
                      location: accommodation.location,
                      category: accommodation.type,
                      activeColor: Colors.red,
                      inactiveColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          accommodation.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (accommodation.reviews.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getReviewColor(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getAverageRating(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Address with icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${accommodation.address}, ${accommodation.city}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Amenities icons
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Free Parking
                      if (_hasAmenity('parking') || _hasAmenity('free parking'))
                        _buildAmenityIcon(Icons.local_parking, 'Free Parking'),

                      // WiFi
                      if (_hasAmenity('wifi') || _hasAmenity('free wifi'))
                        _buildAmenityIcon(Icons.wifi, 'WiFi'),

                      // Restaurant
                      if (_hasAmenity('restaurant'))
                        _buildAmenityIcon(Icons.restaurant, 'Restaurant'),

                      // Pool
                      if (_hasAmenity('pool') || _hasAmenity('swimming'))
                        _buildAmenityIcon(Icons.pool, 'Pool'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Room availability and View Details button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${accommodation.roomTypes.length} room ${accommodation.roomTypes.length != 1 ? 'types' : 'type'} available',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),

                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('View Details'),
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
  }

  String _getLowestPrice() {
    if (accommodation.roomTypes.isEmpty) {
      return 'Price on request';
    }

    double lowestPrice = double.infinity;
    for (final roomType in accommodation.roomTypes) {
      if (roomType.price < lowestPrice) {
        lowestPrice = roomType.price;
      }
    }

    return '\$${lowestPrice.toStringAsFixed(0)}';
  }

  String _getAverageRating() {
    if (accommodation.reviews.isEmpty) {
      return 'N/A';
    }

    double totalRating = 0;
    for (final review in accommodation.reviews) {
      totalRating += review.rating;
    }

    return (totalRating / accommodation.reviews.length).toStringAsFixed(1);
  }

  Color _getReviewColor() {
    if (accommodation.reviews.isEmpty) {
      return Colors.grey;
    }

    double totalRating = 0;
    for (final review in accommodation.reviews) {
      totalRating += review.rating;
    }

    final avgRating = totalRating / accommodation.reviews.length;

    if (avgRating >= 4.5) return Colors.green[700]!;
    if (avgRating >= 4.0) return Colors.green[500]!;
    if (avgRating >= 3.5) return Colors.amber[700]!;
    if (avgRating >= 3.0) return Colors.orange[700]!;

    return Colors.red[700]!;
  }

  bool _hasAmenity(String amenity) {
    final lowercaseAmenity = amenity.toLowerCase();
    return accommodation.amenities.any(
            (a) => a.toLowerCase().contains(lowercaseAmenity)
    );
  }

  Widget _buildAmenityIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: label,
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}