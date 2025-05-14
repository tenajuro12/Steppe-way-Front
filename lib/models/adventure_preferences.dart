class AdventurePreferences {
  List<String> interests;
  String location;
  DateTime startDate;
  DateTime endDate;
  int durationDays;

  // Optional parameters
  String? accommodationType;
  String? cuisinePreference;
  bool includePopularOnly;
  double? maxBudget;

  AdventurePreferences({
    required this.interests,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.accommodationType,
    this.cuisinePreference,
    this.includePopularOnly = false,
    this.maxBudget,
  });
}
