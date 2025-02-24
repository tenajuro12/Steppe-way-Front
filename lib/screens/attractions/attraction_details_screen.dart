import 'package:flutter/material.dart';
import '../../models/attraction.dart';

class AttractionDetailsScreen extends StatelessWidget {
  final Attraction attraction;

  const AttractionDetailsScreen({super.key, required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(attraction.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: attraction.title,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: attraction.imageUrl.isNotEmpty
                    ? Image.network(
                  attraction.imageUrl,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image, size: 100)),
                )
                    : const SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: Center(child: Icon(Icons.image_not_supported, size: 100)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📍 Title & Location
                  Text(
                    attraction.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        attraction.city,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 📄 Description Section
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attraction.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < 4 ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, size: 28),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to favorites!')),
                          );
                        },
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
}
