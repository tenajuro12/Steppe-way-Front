import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../services/event_service.dart';
import 'event_details_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventService.fetchUpcomingEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No events found.'));
          } else {
            final events = snapshot.data!;
            return ListView.builder(
              itemCount: events.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Image with gradient overlay
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Stack(
                            children: [
                              Image.network(
                                event.imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 60),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Event details
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: Colors.blueAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${event.startDate} - ${event.endDate}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
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
              },
            );
          }
        },
      ),
    );
  }
}
