// lib/screens/plan/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_kz/screens/plan/plan_map_screen.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
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
      await _planFuture;
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

  Future<void> _deletePlan(Plan plan) async {
    // Guard against null ID
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
      await PlanService.optimizeRoute(planId);
      _loadPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route optimized successfully!')),
        );
      }
    } catch (e) {
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
              // Guard against null ID for optimize button
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
          // Map button
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
          // Add item button
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
    // Group items by date
    final Map<String, List<PlanItem>> itemsByDate = {};
    for (var item in items) {
      // Handle null scheduledFor
      final date = item.scheduledFor != null
          ? DateFormat('yyyy-MM-dd').format(item.scheduledFor!)
          : 'Unscheduled';

      if (!itemsByDate.containsKey(date)) {
        itemsByDate[date] = [];
      }
      itemsByDate[date]!.add(item);
    }

    // Sort dates
    final sortedDates = itemsByDate.keys.toList()
      ..sort((a, b) {
        if (a == 'Unscheduled') return 1; // Put unscheduled at the end
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

        // Format date header
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
    final iconData = item.itemType == 'attraction' ? Icons.place : Icons.event;
    final iconColor = item.itemType == 'attraction' ? Colors.red : Colors.blue;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  // Only show time if scheduled
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
                  // Navigate to edit item screen
                } else if (value == 'delete') {
                  _deletePlanItem(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _deletePlanItem(PlanItem item) async {
    // Guard against null ID
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