import 'package:flutter/material.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import 'create_from_template_screen.dart';

class TemplateDetailsScreen extends StatefulWidget {
  final int templateId;

  const TemplateDetailsScreen({Key? key, required this.templateId}) : super(key: key);

  @override
  _TemplateDetailsScreenState createState() => _TemplateDetailsScreenState();
}

class _TemplateDetailsScreenState extends State<TemplateDetailsScreen> {
  late Future<PlanTemplate> _templateFuture;
  late Future<List<TemplateItem>> _templateItemsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
    _loadTemplateItems();
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _isLoading = true;
      _templateFuture = PlanService.getTemplate(widget.templateId);
    });

    try {
      await _templateFuture;
    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTemplateItems() async {
    setState(() {
      _isLoading = true;
      _templateItemsFuture = PlanService.getTemplateItems(widget.templateId);
    });

    try {
      await _templateItemsFuture;
    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCreateFromTemplate() async {
    final template = await _templateFuture;

    print('Template ID before navigation: ${template.id}');

    if (template.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create from template: template ID is missing')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFromTemplateScreen(templateId: template.id!),
      ),
    ).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Template Details'),
        elevation: 0,
        backgroundColor: Colors.purple[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await _loadTemplate();
          await _loadTemplateItems();
        },
        child: FutureBuilder<PlanTemplate>(
          future: _templateFuture,
          builder: (context, templateSnapshot) {
            if (templateSnapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (templateSnapshot.hasError) {
              return _buildErrorState(templateSnapshot.error.toString());
            } else if (!templateSnapshot.hasData) {
              return const Center(child: Text('Template not found'));
            }

            final template = templateSnapshot.data!;

            return FutureBuilder<List<TemplateItem>>(
              future: _templateItemsFuture,
              builder: (context, itemsSnapshot) {
                final items = itemsSnapshot.hasData ? itemsSnapshot.data! : <TemplateItem>[];

                return CustomScrollView(
                  slivers: [

                    SliverToBoxAdapter(
                      child: _buildHeader(template),
                    ),


                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToCreateFromTemplate,
                          icon: const Icon(Icons.add),
                          label: const Text('USE THIS TEMPLATE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),


                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About This Template',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              template.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Suggested Itinerary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text('${template.duration} days'),
                              backgroundColor: Colors.purple[100],
                              labelStyle: TextStyle(
                                color: Colors.purple[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    if (itemsSnapshot.connectionState == ConnectionState.waiting && !_isLoading)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (itemsSnapshot.hasError)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text('Error loading itinerary: ${itemsSnapshot.error}'),
                          ),
                        ),
                      )
                    else if (items.isEmpty)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No itinerary items defined for this template'),
                            ),
                          ),
                        )
                      else
                        _buildItineraryList(items),


                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<PlanTemplate>(
        future: _templateFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateFromTemplate,
              icon: const Icon(Icons.add),
              label: const Text('USE THIS TEMPLATE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(PlanTemplate template) {
    return Container(
      color: Colors.purple[700],
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            template.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),


          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                '${template.city}, ${template.country}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


          if (template.category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                template.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItineraryList(List<TemplateItem> items) {

    final Map<int, List<TemplateItem>> itemsByDay = {};
    for (var item in items) {
      if (!itemsByDay.containsKey(item.dayNumber)) {
        itemsByDay[item.dayNumber] = [];
      }
      itemsByDay[item.dayNumber]!.add(item);
    }


    itemsByDay.forEach((day, dayItems) {
      dayItems.sort((a, b) => a.orderInDay.compareTo(b.orderInDay));
    });


    final sortedDays = itemsByDay.keys.toList()..sort();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final day = sortedDays[index];
          final dayItems = itemsByDay[day]!;

          return _buildDaySection(day, dayItems);
        },
        childCount: sortedDays.length,
      ),
    );
  }

  Widget _buildDaySection(int day, List<TemplateItem> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Day $day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
          ),


          ...items.map((item) => _buildActivityItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(TemplateItem item) {
    final Color color = item.itemType == 'attraction'
        ? Colors.red
        : (item.itemType == 'event' ? Colors.blue : Colors.amber);

    final IconData icon = item.itemType == 'attraction'
        ? Icons.place
        : (item.itemType == 'event' ? Icons.event : Icons.label);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),


          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.recommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Recommended',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                  ],
                ),

                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                if (item.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (item.duration > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(item.duration),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours h $mins min' : '$hours h';
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading template details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadTemplate();
              _loadTemplateItems();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}