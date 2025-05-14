import 'package:flutter/material.dart';

import 'package:travel_kz/models/event.dart';
import 'dart:math';

class EventAdPopup extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;

  const EventAdPopup({
    Key? key,
    required this.event,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 180,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: onClose,
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onClose();
                        // Navigate to event details page
                        Navigator.pushNamed(
                          context,
                          '/events', // Make sure you have this route
                          arguments: event,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'VIEW EVENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Fallback if image doesn't load
                    return const AssetImage('assets/images/placeholder.jpg');
                  } as ImageErrorListener?,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.grey[700],
                onPressed: onClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}