import 'package:flutter/material.dart';
import '../../models/event.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl.isNotEmpty)
              Image.network(event.imageUrl, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(event.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Location: ${event.location}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Category: ${event.category}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Capacity: ${event.capacity}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Start: ${event.startDate}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('End: ${event.endDate}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(event.description, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
