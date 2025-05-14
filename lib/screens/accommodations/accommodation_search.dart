import 'package:flutter/material.dart';

import '../../models/accommodation.dart';
import 'accommodation_card.dart';
import 'accommodation_details_screen.dart';

class AccommodationSearchDelegate extends SearchDelegate<Accommodation> {
  final List<Accommodation> accommodations;

  AccommodationSearchDelegate(this.accommodations);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, accommodations.first);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = accommodations.where((accommodation) =>
        accommodation.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final accommodation = results[index];
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = accommodations.where((accommodation) =>
        accommodation.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final accommodation = suggestions[index];
        return ListTile(
          leading: accommodation.images.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              accommodation.images.first.url,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.hotel, color: Colors.grey),
                );
              },
            ),
          )
              : Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hotel, color: Colors.grey),
          ),
          title: Text(accommodation.name),
          subtitle: Text(accommodation.address),
          onTap: () {
            close(context, accommodation);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccommodationDetailsScreen(
                  accommodationId: accommodation.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
