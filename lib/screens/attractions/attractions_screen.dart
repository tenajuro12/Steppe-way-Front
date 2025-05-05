import 'package:flutter/material.dart';
import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import 'attraction_details_screen.dart';

class AttractionsListScreen extends StatefulWidget {
  const AttractionsListScreen({super.key});

  @override
  State<AttractionsListScreen> createState() => _AttractionsListScreenState();
}

class _AttractionsListScreenState extends State<AttractionsListScreen> {
  late Future<List<Attraction>> _attractionsFuture;

  @override
  void initState() {
    super.initState();
    _attractionsFuture = AttractionService.fetchAttractions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E65A0), // Blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E65A0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Plenty of popular places!",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Visit them all now!",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Attraction>>(
                future: _attractionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No attractions found.', style: TextStyle(color: Colors.white)));
                  }

                  final attractions = snapshot.data!;
                  return GridView.builder(
                    itemCount: attractions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final attraction = attractions[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttractionDetailsScreen(attraction: attraction),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  attraction.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Text(
                                  attraction.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.bookmark, color: Colors.white),
                                  onPressed: () {
                                    // Handle bookmark action
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
