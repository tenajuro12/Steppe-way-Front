// lib/screens/plans/add_plan_item_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/attraction.dart';
import '../../models/event.dart';
import '../../services/plan_service.dart';
import '../../services/attraction_service.dart';
import '../../services/event_service.dart';

class AddPlanItemScreen extends StatefulWidget {
  final Plan plan;

  const AddPlanItemScreen({Key? key, required this.plan}) : super(key: key);

  @override
  _AddPlanItemScreenState createState() => _AddPlanItemScreenState();
}

class _AddPlanItemScreenState extends State<AddPlanItemScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<List<Attraction>> _attractionsFuture;
  late Future<List<Event>> _eventsFuture;

  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttractions();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttractions() async {
    setState(() {
      _isLoading = true;
      // Use the correct method from your existing AttractionService
      _attractionsFuture = AttractionService.fetchAttractions();
    });

    try {
      await _attractionsFuture;
    } catch (e) {
      // Error handling in the FutureBuilder
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      // Use the correct method from your existing EventService
      _eventsFuture = EventService.fetchUpcomingEvents();
    });

    try {
      await _eventsFuture;
    } catch (e) {
      // Error handling in the FutureBuilder
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addAttractionToPlan(Attraction attraction) async {
    setState(() => _isLoading = true);
    try {
      // Optional date picker - show a dialog asking if user wants to schedule
      final bool scheduleTime = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Schedule this attraction?'),
          content: const Text('Would you like to schedule a specific time for this attraction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('NO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('YES'),
            ),
          ],
        ),
      ) ?? false;

      // Schedule datetime will be null if user chooses not to schedule
      DateTime? scheduledDateTime;

      if (scheduleTime) {
        // Show date picker for scheduling
        final DateTime? selectedDate = await _showDatePicker(
            widget.plan.startDate,
            widget.plan.endDate
        );

        if (selectedDate == null) {
          setState(() => _isLoading = false);
          return;
        }

        // Show time picker
        final TimeOfDay? selectedTime = await _showTimePicker();

        if (selectedTime == null) {
          setState(() => _isLoading = false);
          return;
        }

        // Combine date and time
        scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }

      // Create plan item
      final planItem = PlanItem(
        planId: widget.plan.id!,
        itemType: 'attraction',
        itemId: attraction.id,
        title: attraction.title,
        description: attraction.description,
        location: attraction.location,
        address: attraction.address,
        scheduledFor: scheduledDateTime,  // Can be null now
        duration: 120, // Default 2 hours for attractions
        orderIndex: 0, // Will be set by the backend
      );

      await PlanService.addItemToPlan(planItem);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${attraction.title} added to your plan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding attraction to plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addEventToPlan(Event event) async {
    setState(() => _isLoading = true);
    try {
      // For events, we use the event's start time directly
      final planItem = PlanItem(
        planId: widget.plan.id!,
        itemType: 'event',
        itemId: event.id,
        title: event.title,
        description: event.description,
        location: event.location,
        address: '',
        scheduledFor: event.startDate,
        orderIndex: 0,
        duration: Duration.minutesPerHour, // Will be set by the backend
      );

      await PlanService.addItemToPlan(planItem);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${event.title} added to your plan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding event to plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<DateTime?> _showDatePicker(DateTime startDate, DateTime endDate) async {
    return showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: endDate,
      helpText: 'Select date for this activity',
    );
  }

  Future<TimeOfDay?> _showTimePicker() async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select time for this activity',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Plan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Attractions'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Attractions Tab
                    _buildAttractionsTab(),
                    // Events Tab
                    _buildEventsTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttractionsTab() {
    return FutureBuilder<List<Attraction>>(
      future: _attractionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAttractions,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attractions found'));
        }

        // Filter attractions based on search query
        final attractions = snapshot.data!.where((attraction) {
          if (_searchQuery.isEmpty) return true;
          return attraction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              attraction.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              attraction.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              attraction.city.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (attractions.isEmpty) {
          return Center(child: Text('No attractions found for "$_searchQuery"'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attractions.length,
          itemBuilder: (context, index) {
            final attraction = attractions[index];
            return _buildAttractionCard(attraction);
          },
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadEvents,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        // Filter events based on search query
        final events = snapshot.data!.where((event) {
          if (_searchQuery.isEmpty) return true;
          return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.location.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // Filter events by date range of the plan
        final planEvents = events.where((event) {
          return (event.startDate.isAfter(widget.plan.startDate) ||
              event.startDate.isAtSameMomentAs(widget.plan.startDate)) &&
              (event.startDate.isBefore(widget.plan.endDate) ||
                  event.startDate.isAtSameMomentAs(widget.plan.endDate));
        }).toList();

        if (planEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No events found for your travel dates'
                      : 'No events found for "$_searchQuery" during your travel dates',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: planEvents.length,
          itemBuilder: (context, index) {
            final event = planEvents[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildAttractionCard(Attraction attraction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _addAttractionToPlan(attraction),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: attraction.imageUrl.isNotEmpty
                  ? Image.network(
                attraction.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.place,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                          attraction.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (attraction.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        attraction.category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    attraction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addAttractionToPlan(attraction),
                      child: const Text('ADD TO PLAN'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _addEventToPlan(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: event.imageUrl.isNotEmpty
                  ? Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.event,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(event.startDate),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
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
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (event.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        event.category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addEventToPlan(event),
                      child: const Text('ADD TO PLAN'),
                    ),
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