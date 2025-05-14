
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/attraction.dart';
import '../../models/event.dart';
import '../../models/food.dart';
import '../../models/accommodation.dart';
import '../../services/plan_service.dart';
import '../../services/attraction_service.dart';
import '../../services/event_service.dart';
import '../../services/food_service.dart';
import '../../services/accommodation_service.dart';

class AddPlanItemScreen extends StatefulWidget {
  final Plan plan;

  const AddPlanItemScreen({Key? key, required this.plan}) : super(key: key);

  @override
  _AddPlanItemScreenState createState() => _AddPlanItemScreenState();
}

class _AddPlanItemScreenState extends State<AddPlanItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Attraction>> _attractionsFuture;
  late Future<List<Event>> _eventsFuture;
  late Future<List<Place>> _foodPlacesFuture;
  late Future<List<Accommodation>> _accommodationsFuture;

  bool _isLoading = false;
  String _searchQuery = '';


  final AccommodationService _accommodationService = AccommodationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAttractions();
    _loadEvents();
    _loadFoodPlaces();
    _loadAccommodations();


    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _refreshCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadAttractions();
        break;
      case 1:
        _loadEvents();
        break;
      case 2:
        _loadFoodPlaces();
        break;
      case 3:
        _loadAccommodations();
        break;
    }
  }

  Future<void> _loadAttractions() async {
    setState(() {
      _isLoading = true;
      _attractionsFuture = AttractionService.fetchAttractions();
    });

    try {
      await _attractionsFuture;
    } catch (e) {
      print('Error loading attractions: $e');
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
      _eventsFuture = EventService.fetchUpcomingEvents();
    });

    try {
      await _eventsFuture;
    } catch (e) {
      print('Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFoodPlaces() async {
    setState(() {
      _isLoading = true;
      _foodPlacesFuture =
          FoodService.getFoodPlaces().then((result) => result.places);
    });

    try {
      await _foodPlacesFuture;
    } catch (e) {
      print('Error loading food places: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAccommodations() async {
    setState(() {
      _isLoading = true;
      _accommodationsFuture = _accommodationService.getAccommodations();
    });

    try {
      await _accommodationsFuture;
    } catch (e) {
      print('Error loading accommodations: $e');
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
      final bool scheduleTime = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Schedule this attraction?'),
              content: const Text(
                  'Would you like to schedule a specific time for this attraction?'),
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
          ) ??
          false;

      DateTime? scheduledDateTime;

      if (scheduleTime) {
        final DateTime? selectedDate =
            await _showDatePicker(widget.plan.startDate, widget.plan.endDate);

        if (selectedDate == null) {
          setState(() => _isLoading = false);
          return;
        }


        final TimeOfDay? selectedTime = await _showTimePicker();

        if (selectedTime == null) {
          setState(() => _isLoading = false);
          return;
        }


        scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }


      final planItem = PlanItem(
        planId: widget.plan.id!,
        itemType: 'attraction',
        itemId: attraction.id,
        title: attraction.title,
        description: attraction.description,
        location: attraction.location,
        address: attraction.address,
        scheduledFor: scheduledDateTime,
        duration: 120,
        orderIndex: 0,
        imageURL: attraction.imageUrl,
        category: attraction.category,
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
        duration: _calculateEventDuration(event),
        imageURL: event.imageUrl,
        category: event.category,
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

  Future<void> _addFoodPlaceToPlan(Place foodPlace) async {
    setState(() => _isLoading = true);
    try {

      final bool scheduleTime = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Schedule this food place?'),
              content: const Text(
                  'Would you like to schedule a specific time to visit this restaurant?'),
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
          ) ??
          false;


      DateTime? scheduledDateTime;

      if (scheduleTime) {

        final DateTime? selectedDate =
            await _showDatePicker(widget.plan.startDate, widget.plan.endDate);

        if (selectedDate == null) {
          setState(() => _isLoading = false);
          return;
        }


        final TimeOfDay? selectedTime = await _showMealTimePicker();

        if (selectedTime == null) {
          setState(() => _isLoading = false);
          return;
        }


        scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }


      String? imageUrl;
      if (foodPlace.images.isNotEmpty) {
        imageUrl = foodPlace.images.first.url;

        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'http://10.0.2.2:8080' + imageUrl;
        }
      }


      final planItem = PlanItem(
        planId: widget.plan.id!,
        itemType: 'food',
        itemId: foodPlace.id,
        title: foodPlace.name,
        description: foodPlace.description,
        location: foodPlace.location,
        address: foodPlace.address,
        scheduledFor: scheduledDateTime,
        duration: 90,
        orderIndex: 0,
        imageURL: imageUrl,
        category: foodPlace.type,
        priceRange: foodPlace.priceRange,
      );

      await PlanService.addItemToPlan(planItem);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${foodPlace.name} added to your plan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding food place to plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAccommodationToPlan(Accommodation accommodation) async {
    setState(() => _isLoading = true);
    try {

      final bool scheduleTime = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Set check-in time?'),
              content: const Text(
                  'Would you like to set a check-in time for this accommodation?'),
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
          ) ??
          false;


      DateTime? scheduledDateTime;

      if (scheduleTime) {

        final DateTime? selectedDate =
            await _showDatePicker(widget.plan.startDate, widget.plan.endDate);

        if (selectedDate == null) {
          setState(() => _isLoading = false);
          return;
        }


        final TimeOfDay defaultCheckIn =
            const TimeOfDay(hour: 14, minute: 0);
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: defaultCheckIn,
          helpText: 'Select check-in time',
        );

        if (selectedTime == null) {
          setState(() => _isLoading = false);
          return;
        }


        scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }


      String? imageUrl;
      if (accommodation.images.isNotEmpty) {
        imageUrl = accommodation.images.first.url;

        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'http://10.0.2.2:8080' + imageUrl;
        }
      }


      final planItem = PlanItem(
        planId: widget.plan.id!,
        itemType: 'accommodation',
        itemId: accommodation.id,
        title: accommodation.name,
        description: accommodation.description,
        location: accommodation.location,
        address: accommodation.address,
        scheduledFor: scheduledDateTime,
        duration: 1440,

        orderIndex: 0,

        imageURL: imageUrl,
        accommodationType: accommodation.type,
      );

      await PlanService.addItemToPlan(planItem);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${accommodation.name} added to your plan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding accommodation to plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateEventDuration(Event event) {
    if (event.endDate != null) {
      final difference = event.endDate.difference(event.startDate);
      return difference.inMinutes;
    }
    return 60;
  }

  Future<DateTime?> _showDatePicker(
      DateTime startDate, DateTime endDate) async {
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

  Future<TimeOfDay?> _showMealTimePicker() async {

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a meal time'),
        children: [
          _buildMealTimeOption(
              context, 'Breakfast', const TimeOfDay(hour: 8, minute: 0)),
          _buildMealTimeOption(
              context, 'Lunch', const TimeOfDay(hour: 13, minute: 0)),
          _buildMealTimeOption(
              context, 'Dinner', const TimeOfDay(hour: 19, minute: 0)),
          _buildMealTimeOption(context, 'Custom Time...', null),
        ],
      ),
    );


    if (result == null) {
      return await _showTimePicker();
    }

    return result;
  }

  Widget _buildMealTimeOption(
      BuildContext context, String label, TimeOfDay? time) {
    return SimpleDialogOption(
      onPressed: () {
        if (time != null) {
          Navigator.pop(context, time);
        } else {

          Navigator.pop(context);
        }
      },
      child: Text(
        time != null ? '$label (${time.format(context)})' : label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Plan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.place), text: 'Attractions'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.restaurant), text: 'Food'),
            Tab(icon: Icon(Icons.hotel), text: 'Accommodation'),
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

                    _buildAttractionsTab(),


                    _buildEventsTab(),


                    _buildFoodTab(),


                    _buildAccommodationTab(),
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
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


        final attractions = snapshot.data!.where((attraction) {
          if (_searchQuery.isEmpty) return true;
          return attraction.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              attraction.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              attraction.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              attraction.city
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        }).toList();

        if (attractions.isEmpty) {
          return Center(
              child: Text('No attractions found for "$_searchQuery"'));
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
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


        final events = snapshot.data!.where((event) {
          if (_searchQuery.isEmpty) return true;
          return event.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              event.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              event.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              event.location.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();


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

  Widget _buildFoodTab() {
    return FutureBuilder<List<Place>>(
      future: _foodPlacesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
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
                  onPressed: _loadFoodPlaces,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No restaurants or food places found'));
        }


        final foodPlaces = snapshot.data!.where((place) {
          if (_searchQuery.isEmpty) return true;
          return place.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              place.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              place.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              place.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              place.cuisines.any((cuisine) => cuisine.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
        }).toList();

        if (foodPlaces.isEmpty) {
          return Center(
              child: Text('No food places found for "$_searchQuery"'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: foodPlaces.length,
          itemBuilder: (context, index) {
            final foodPlace = foodPlaces[index];
            return _buildFoodPlaceCard(foodPlace);
          },
        );
      },
    );
  }

  Widget _buildAccommodationTab() {
    return FutureBuilder<List<Accommodation>>(
      future: _accommodationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
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
                  onPressed: _loadAccommodations,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No accommodations found'));
        }


        final accommodations = snapshot.data!.where((accommodation) {
          if (_searchQuery.isEmpty) return true;
          return accommodation.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              accommodation.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              accommodation.type
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              accommodation.city
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        }).toList();

        if (accommodations.isEmpty) {
          return Center(
              child: Text('No accommodations found for "$_searchQuery"'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accommodations.length,
          itemBuilder: (context, index) {
            final accommodation = accommodations[index];
            return _buildAccommodationCard(accommodation);
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
                      backgroundColor: Colors.red.withOpacity(0.1),
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
                    child: ElevatedButton.icon(
                      onPressed: () => _addAttractionToPlan(attraction),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD TO PLAN'),


                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
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
                      backgroundColor: Colors.blue.withOpacity(0.1),
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
                    child: ElevatedButton.icon(
                      onPressed: () => _addEventToPlan(event),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD TO PLAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
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

  Widget _buildFoodPlaceCard(Place foodPlace) {

    String imageUrl = '';
    if (foodPlace.images.isNotEmpty) {
      imageUrl = foodPlace.images.first.url;
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'http://10.0.2.2:8080' + imageUrl;
      }
    }


    List<String> cuisineNames = foodPlace.cuisines.map((c) => c.name).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _addFoodPlaceToPlan(foodPlace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
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
                        Icons.restaurant,
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
                    foodPlace.name,
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
                          foodPlace.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [

                      if (foodPlace.priceRange.isNotEmpty) ...[
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          foodPlace.priceRange,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],


                      if (foodPlace.averageRating > 0) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          foodPlace.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),


                  if (cuisineNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: cuisineNames.take(3).map((cuisine) {
                        return Chip(
                          label: Text(
                            cuisine,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    foodPlace.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _addFoodPlaceToPlan(foodPlace),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD TO PLAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                      ),
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

  Widget _buildAccommodationCard(Accommodation accommodation) {

    String imageUrl = '';
    if (accommodation.images.isNotEmpty) {
      imageUrl = accommodation.images.first.url;
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'http://10.0.2.2:8080' + imageUrl;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _addAccommodationToPlan(accommodation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
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
                        Icons.hotel,
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
                    accommodation.name,
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
                          accommodation.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.hotel,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        accommodation.type,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (accommodation.startingPrice > 0) ...[
                        const Spacer(),
                        Text(
                          'From ${accommodation.formattedStartingPrice}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),


                  if (accommodation.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: accommodation.amenities.take(3).map((amenity) {
                        return Chip(
                          label: Text(
                            amenity,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    accommodation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _addAccommodationToPlan(accommodation),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD TO PLAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
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
