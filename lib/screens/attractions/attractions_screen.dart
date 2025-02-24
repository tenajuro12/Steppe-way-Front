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
      appBar: AppBar(
        title: const Text('All Attractions'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _attractionsFuture = AttractionService.fetchAttractions();
          });
        },
        child: FutureBuilder<List<Attraction>>(
          future: _attractionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No attractions found.'));
            }

            final attractions = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attractions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: attractions[index].imageUrl.isNotEmpty
                        ? Image.network(
                      attractions[index].imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(
                    attractions[index].title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${attractions[index].city}\n${attractions[index].description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttractionDetailsScreen(attraction: attractions[index]),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
