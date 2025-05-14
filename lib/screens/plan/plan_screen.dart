
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_kz/screens/plan/template_details_screen.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import 'plan_details_screen.dart';
import 'create_plan_screen.dart';
import 'create_from_template_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  _PlansScreenState createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Plan>> _plansFuture;
  late Future<
      List<PlanTemplate>> _templatesFuture;
  bool _isLoading = false;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  final List<String> _categories = [
    'Own Plans',
    'Templates',
    'Active',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadPlans();
    _loadTemplates();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          _loadTemplates();
        } else {
          _loadPlans();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _plansFuture = PlanService.getUserPlans();
    });

    try {
      await _plansFuture;
    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _templatesFuture =
          PlanService.getTemplates();
    });

    try {
      await _templatesFuture;
    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Plan> _filterPlans(List<Plan> plans) {
    final today = DateTime.now();


    List<Plan> filtered = [];

    if (_tabController.index == 0) {

      filtered = plans.where((plan) => !plan.isPublic).toList();
    } else if (_tabController.index == 2) {

      filtered = plans.where(
              (plan) =>
          plan.startDate.isBefore(today) &&
              plan.endDate.isAfter(today) &&
              !plan.isPublic
      ).toList();
    } else if (_tabController.index == 3) {
      filtered = plans.where(
              (plan) =>
          plan.endDate.isBefore(today) &&
              !plan.isPublic
      ).toList();
    } else {
      filtered = plans.where((plan) => !plan.isPublic).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((plan) =>
      plan.title.toLowerCase().contains(query) ||
          plan.description.toLowerCase().contains(query) ||
          plan.city.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  List<PlanTemplate> _filterTemplates(List<PlanTemplate> templates) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      return templates.where((template) =>
      template.title.toLowerCase().contains(query) ||
          template.description.toLowerCase().contains(query) ||
          template.city.toLowerCase().contains(query) ||
          template.category.toLowerCase().contains(query)
      ).toList();
    }
    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'My Travel Plans',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: theme.primaryColor,
            onPressed: _tabController.index == 1 ? _loadTemplates : _loadPlans,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 1
                        ? 'Search templates...'
                        : 'Search plans...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: theme.primaryColor,
                indicatorWeight: 3,
                tabs: _categories.map((category) =>
                    Tab(text: category)).toList(),
                onTap: (_) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),

        children: [

          RefreshIndicator(
            onRefresh: _loadPlans,
            child: _buildPlansTabContent(context),
          ),


          RefreshIndicator(
            onRefresh: _loadTemplates,
            child: _buildTemplatesTabContent(context),
          ),


          RefreshIndicator(
            onRefresh: _loadPlans,
            child: _buildPlansTabContent(context),
          ),


          RefreshIndicator(
            onRefresh: _loadPlans,
            child: _buildPlansTabContent(context),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? null
          : FloatingActionButton.extended(
        heroTag: 'createPlanButton',
        onPressed: _navigateToCreatePlan,
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Create Plan'),
      ),
    );
  }

  Widget _buildPlansTabContent(BuildContext context) {
    return FutureBuilder<List<Plan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final today = DateTime.now();
        List<Plan> plansForThisTab = snapshot.data!;

        if (_tabController.index == 0) {
          plansForThisTab = plansForThisTab.where((plan) => !plan.isPublic).toList();
        } else if (_tabController.index == 2) {
          plansForThisTab = plansForThisTab.where(
                  (plan) =>
              plan.startDate.isBefore(today) &&
                  plan.endDate.isAfter(today) &&
                  !plan.isPublic
          ).toList();
        } else if (_tabController.index == 3) {
          plansForThisTab = plansForThisTab.where(
                  (plan) =>
              plan.endDate.isBefore(today) &&
                  !plan.isPublic
          ).toList();
        }


        final filteredPlans = plansForThisTab.where((plan) {
          if (_searchQuery.isEmpty) return true;

          final query = _searchQuery.toLowerCase();
          return plan.title.toLowerCase().contains(query) ||
              plan.description.toLowerCase().contains(query) ||
              plan.city.toLowerCase().contains(query);
        }).toList();

        if (filteredPlans.isEmpty) {
          return Center(
            child: Column(

            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPlans.length,
          itemBuilder: (context, index) {
            final plan = filteredPlans[index];
            return _buildPlanCard(plan);
          },
        );
      },
    );
  }

  Widget _buildTemplatesTabContent(BuildContext context) {
    return FutureBuilder<List<PlanTemplate>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyTemplatesState();
        }

        final filteredTemplates = _filterTemplates(snapshot.data!);

        if (filteredTemplates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No templates match your search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme
                        .of(context)
                        .primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTemplates.length,
          itemBuilder: (context, index) {
            final template = filteredTemplates[index];
            return _buildTemplateCard(template);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _tabController.index == 1 ? _loadTemplates : _loadPlans,
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

  Widget _buildEmptyState() {
    final emptyTitle = _tabController.index == 2
        ? 'No active plans'
        : (_tabController.index == 3
        ? 'No completed plans yet'
        : 'No travel plans yet');

    final emptyMessage = 'Create your first travel plan to organize attractions, events, and activities for your trip.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.amber[400],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            emptyTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToCreatePlan,
            icon: const Icon(Icons.add),
            label: const Text('Create New Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _tabController.animateTo(1);
            },
            icon: const Icon(Icons.dashboard_customize),
            label: const Text('Use a Template Instead'),
            style: TextButton.styleFrom(
              foregroundColor: Theme
                  .of(context)
                  .primaryColor,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyTemplatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard_outlined,
              size: 80,
              color: Colors.purple[400],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No plan templates available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Templates allow you to quickly create plans based on pre-defined itineraries. Check back later for available templates or create your own custom plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _tabController.animateTo(0);
              _navigateToCreatePlan();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Custom Plan Instead'),
            style: TextButton.styleFrom(
              foregroundColor: Theme
                  .of(context)
                  .primaryColor,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, yyyy');
    final today = DateTime.now();

    bool isCompleted = plan.endDate.isBefore(today);
    bool isActive = !isCompleted && plan.startDate.isBefore(today);;
    final bool hasValidDates = plan.startDate.year > 1000 && plan.endDate.year > 1000;

    final String formattedStartDate = hasValidDates
        ? formatter.format(plan.startDate)
        : 'Invalid date';

    final String formattedEndDate = hasValidDates
        ? formatter.format(plan.endDate)
        : 'Invalid date';

    final String dateDisplay = '$formattedStartDate - $formattedEndDate';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToPlanDetails(plan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isActive
                  ? Colors.green[400]
                  : (isCompleted
                  ? Colors.grey[400]
                  : theme.primaryColor),
              child: Text(
                isActive
                    ? '🔥 ACTIVE NOW'
                    : (isCompleted
                    ? '✓ COMPLETED'
                    : '🕒 UPCOMING'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withOpacity(0.7),
                    theme.primaryColor.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [

                  Center(
                    child: Icon(
                      Icons.map,
                      size: 80,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plan.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${plan.durationInDays} days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                    Row(
                    children: [
                      if (plan.items.any((item) => item.itemType == 'attraction'))
                        _buildInfoChip(
                          Icons.place,
                          '${plan.items.where((item) => item.itemType == 'attraction').length} attractions',
                          Colors.red[400]!,
                        ),
                      if (plan.items.any((item) => item.itemType == 'event'))
                        Padding(
                          padding: EdgeInsets.only(left: plan.items.any((item) => item.itemType == 'attraction') ? 8.0 : 0),
                          child: _buildInfoChip(
                            Icons.event,
                            '${plan.items.where((item) => item.itemType == 'event').length} events',
                            Colors.blue[400]!,
                          ),
                        ),
                      if (plan.items.isEmpty)
                        _buildInfoChip(
                          Icons.calendar_today,
                          'No activities yet',
                          Colors.grey,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          onPressed: () => _navigateToPlanDetails(plan),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text('View'),
                          onPressed: () => _navigateToPlanDetails(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
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
  }


  Widget _buildTemplateCard(PlanTemplate template) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToTemplateDetails(template),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.purple[400],
              child: const Text(
                '📋 TEMPLATE PLAN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),


            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple[700]!.withOpacity(0.7),
                    Colors.purple[500]!.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [

                  Center(
                    child: Icon(
                      Icons.dashboard_customize,
                      size: 80,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),


                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${template.duration} ${template.duration == 1
                                ? 'day'
                                : 'days'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                        const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.city}, ${template.country}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      )],
                      ),
                    ),
                  ),


                  if (template.category.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          template.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (template.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      template.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),


                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Use This Template'),
                      onPressed: () => _navigateToCreateFromTemplate(template),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[400],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),


                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View Details'),
                      onPressed: () => _navigateToTemplateDetails(template),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.purple[700],
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlanDetails(Plan plan) {

    if (plan.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot view plan details: plan ID is missing')),
      );
      return;
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanDetailsScreen(planId: plan.id!),
      ),
    ).then((_) => _loadPlans());
  }


  void _navigateToTemplateDetails(PlanTemplate template) {

    if (template.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Cannot view template details: template ID is missing')),
      );
      return;
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateDetailsScreen(templateId: template.id!),
      ),
    ).then((_) => _loadTemplates());
  }


  void _navigateToCreateFromTemplate(PlanTemplate template) {
    if (template.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Cannot create from template: template ID is missing')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateFromTemplateScreen(templateId: template.id!),
      ),
    ).then((_) {

      _tabController.animateTo(0);
      _loadPlans();
    });
  }

  void _navigateToCreatePlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePlanScreen(),
      ),
    ).then((_) => _loadPlans());
  }
}