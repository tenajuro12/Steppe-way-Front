import 'package:travel_kz/models/plan.dart';

import 'accommodation.dart';

class GeneratedPlan {
  String id;
  String title;
  DateTime startDate;
  DateTime endDate;
  List<PlanDay> days;
  List<Accommodation> suggestedAccommodations;
  double totalDistance;
  int totalDurationMinutes;

  GeneratedPlan({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.suggestedAccommodations,
    required this.totalDistance,
    required this.totalDurationMinutes,
  });
}

class PlanDay {
  int dayNumber;
  DateTime date;
  List<PlanItem> activities;
  double dayDistance;
  int dayDurationMinutes;

  PlanDay({
    required this.dayNumber,
    required this.date,
    required this.activities,
    required this.dayDistance,
    required this.dayDurationMinutes,
  });
}
