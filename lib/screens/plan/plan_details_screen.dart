
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_kz/screens/plan/plan_map_screen.dart';
import '../../models/plan.dart';
import '../../services/accommodation_service.dart';
import '../../services/attraction_service.dart';
import '../../services/event_service.dart';
import '../../services/food_service.dart';
import '../../services/plan_service.dart';
import '../accommodations/accommodation_details_screen.dart';
import '../attractions/attraction_details_screen.dart';
import '../events/event_details_screen.dart';
import '../food/food_place_details_screen.dart';
import 'add_plan_item_screen.dart';
import 'edit_plan_screen.dart';

class PlanDetailsScreen extends StatefulWidget {
  final int planId;

  const PlanDetailsScreen({Key? key, required this.planId}) : super(key: key);

  @override
  _PlanDetailsScreenState createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  late Future<Plan> _planFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _planFuture = PlanService.getPlan(widget.planId);
    });

    try {
      final plan = await _planFuture;
      print('Loaded plan with ${plan.items.length} items');

      if (plan.items.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _planFuture = PlanService.getPlan(widget.planId);
        });
      }
    } catch (e) {
      print('Error loading plan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePlan(Plan plan) async {

    if (plan.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete plan: plan ID is missing')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await PlanService.deletePlan(plan.id!);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting plan: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _optimizeRoute(int planId) async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Optimizing route for plan $planId...');


      final currentPlan = await _planFuture;
      final currentItems = currentPlan.items;
      currentItems.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      print('📋 Current order:');
      for (var item in currentItems) {
        print('  ${item.orderIndex}. ${item.title} (${item.location})');
      }


      await PlanService.optimizeRoute(planId);


      print('🔄 Reloading plan data after optimization...');
      await _loadPlan();


      final newPlan = await _planFuture;
      final newItems = newPlan.items;
      newItems.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      print('📋 New optimized order:');
      for (var item in newItems) {
        print('  ${item.orderIndex}. ${item.title} (${item.location})');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route optimized successfully!')),
        );
      }
    } catch (e) {
      print('❌ Error optimizing route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error optimizing route: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final plan = await _planFuture;
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlanScreen(plan: plan),
                  ),
                ).then((_) => _loadPlan());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () async {
              final plan = await _planFuture;
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanMapScreen(plan: plan),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final plan = await _planFuture;
              if (mounted) {
                _deletePlan(plan);
              }
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          FutureBuilder<Plan>(
            future: _planFuture,
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
                        onPressed: _loadPlan,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Plan not found'));
              }

              final plan = snapshot.data!;

              final canOptimize = plan.id != null;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(plan),
                    const SizedBox(height: 16),
                    if (plan.items.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Itinerary (${plan.items.length} items)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (canOptimize)
                              TextButton(
                                onPressed: () => _optimizeRoute(plan.id!),
                                child: const Text('OPTIMIZE ROUTE'),
                              ),
                          ],
                        ),
                      ),
                      _buildItinerary(plan.items),
                    ] else ...[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No items in this plan yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('Start adding attractions and events'),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          FloatingActionButton(
            heroTag: 'map_button',
            onPressed: () async {
              final plan = await _planFuture;
              if (mounted && plan.items.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanMapScreen(plan: plan),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add some attractions or events to your plan first!'),
                  ),
                );
              }
            },
            child: const Icon(Icons.map),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 16),

          FloatingActionButton(
            heroTag: 'add_button',
            onPressed: () async {
              try {
                final plan = await _planFuture;
                if (mounted && plan.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPlanItemScreen(plan: plan),
                    ),
                  ).then((_) => _loadPlan());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot add items: plan ID is missing')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading plan: $e')),
                  );
                }
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),

    );
  }

  Widget _buildHeader(Plan plan) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                plan.city,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                '${dateFormat.format(plan.startDate)} - ${dateFormat.format(plan.endDate)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                '${plan.durationInDays} days',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              plan.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItinerary(List<PlanItem> items) {

    final Map<String, List<PlanItem>> itemsByDate = {};
    for (var item in items) {

      final date = item.scheduledFor != null
          ? DateFormat('yyyy-MM-dd').format(item.scheduledFor!)
          : 'Unscheduled';

      if (!itemsByDate.containsKey(date)) {
        itemsByDate[date] = [];
      }
      itemsByDate[date]!.add(item);
    }


    final sortedDates = itemsByDate.keys.toList()
      ..sort((a, b) {
        if (a == 'Unscheduled') return 1;
        if (b == 'Unscheduled') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayItems = itemsByDate[date]!;


        final String formattedDate;
        if (date == 'Unscheduled') {
          formattedDate = 'Unscheduled Items';
        } else {
          formattedDate = DateFormat('EEEE, MMM d').format(DateTime.parse(date));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayItems.length,
              itemBuilder: (context, itemIndex) {
                return _buildPlanItemCard(dayItems[itemIndex], itemIndex);
              },
            ),
          ],
        );
      },
    );
  }



  Widget _buildPlanItemCard(PlanItem item, int index) {
    IconData iconData;
    Color iconColor;


    switch(item.itemType) {
      case 'attraction':
        iconData = Icons.place;
        iconColor = Colors.red;
        break;
      case 'event':
        iconData = Icons.event;
        iconColor = Colors.blue;
        break;
      case 'food':
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'accommodation':
        iconData = Icons.hotel;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.calendar_today;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: () => _navigateToItemDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  if (index < 10) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (item.scheduledFor != null) ...[
                      Text(
                        DateFormat('h:mm a').format(item.scheduledFor!),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),


                    if (item.category != null && item.category!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],


                    if (item.priceRange != null && item.priceRange!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.priceRange!,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],


                    if (item.accommodationType != null && item.accommodationType!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.hotel,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.accommodationType!,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDuration,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {

                  } else if (value == 'delete') {
                    _deletePlanItem(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _navigateToItemDetails(PlanItem item) async {
    try {
      setState(() => _isLoading = true);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading details...')),
      );

      switch (item.itemType) {
        case 'attraction':

          final attraction = await AttractionService.fetchAttractionById(item.itemId);

          if (mounted) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttractionDetailsScreen(attraction: attraction),
              ),
            );
          }
          break;

        case 'event':

          final event = await EventService.fetchEventById(item.itemId);

          if (mounted) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(event: event),
              ),
            );
          }
          break;

        case 'food':

          final foodPlace = await FoodService.getFoodPlace(item.itemId);

          if (mounted) {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodPlaceDetailsScreen(placeId: foodPlace.id),
              ),
            );
          }
          break;

        case 'accommodation':
          final accommodationService = AccommodationService();
          final accommodation = await accommodationService.getAccommodationDetails(item.itemId);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccommodationDetailsScreen(accommodationId: accommodation.id),
              ),
            );
          }
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Details not available for this item type')),
            );
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }  Future<void> _deletePlanItem(PlanItem item) async {

    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete item: item ID is missing')),
      );
      return;
    }
    void _openMap() async {
      try {
        final plan = await _planFuture;
        if (mounted && plan.items.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanMapScreen(plan: plan),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add some attractions or events to your plan first!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading plan: $e')),
          );
        }
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to remove "${item.title}" from this plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await PlanService.deletePlanItem(item.id!);
        _loadPlan();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}