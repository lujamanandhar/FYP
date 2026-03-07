class HydrationLog {
  final int? id;
  final String? userId;  // Changed from int? to String? for UUID
  final double amount;
  final String unit;
  final DateTime loggedAt;
  final DateTime? createdAt;

  const HydrationLog({
    this.id,
    this.userId,
    required this.amount,
    required this.unit,
    required this.loggedAt,
    this.createdAt,
  });

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog(
      id: json['id'] as int?,
      userId: json['user']?.toString(),
      amount: _parseDouble(json['amount']),
      unit: json['unit'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Helper method to parse double from either String or num
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user': userId,
      'amount': amount,
      'unit': unit,
      'logged_at': loggedAt.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  HydrationLog copyWith({
    int? id,
    String? userId,  // Changed from int? to String?
    double? amount,
    String? unit,
    DateTime? loggedAt,
    DateTime? createdAt,
  }) {
    return HydrationLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HydrationLog &&
        other.id == id &&
        other.userId == userId &&
        other.amount == amount &&
        other.unit == unit &&
        other.loggedAt == loggedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, amount, unit, loggedAt, createdAt);
  }
}
