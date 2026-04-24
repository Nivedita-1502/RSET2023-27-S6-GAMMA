class TripModel {
  final int? id;
  final String userEmail;
  final String title;
  final String destination;
  final String startDate;
  final String endDate;
  final String purpose;
  final int travelersCount;
  final double? budgetInr;
  final String? notes;
  final String status;
  final String? createdAt;

  TripModel({
    this.id,
    required this.userEmail,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.purpose = 'leisure',
    this.travelersCount = 1,
    this.budgetInr,
    this.notes,
    this.status = 'upcoming',
    this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        id: json['id'],
        userEmail: json['user_email'] ?? '',
        title: json['title'] ?? '',
        destination: json['destination'] ?? '',
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        purpose: json['purpose'] ?? 'leisure',
        travelersCount: json['travelers_count'] ?? 1,
        budgetInr: json['budget_inr']?.toDouble(),
        notes: json['notes'],
        status: json['status'] ?? 'upcoming',
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_email': userEmail,
        'title': title,
        'destination': destination,
        'start_date': startDate,
        'end_date': endDate,
        'purpose': purpose,
        'travelers_count': travelersCount,
        if (budgetInr != null) 'budget_inr': budgetInr,
        if (notes != null) 'notes': notes,
        'status': status,
      };

  int get durationDays {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }
}