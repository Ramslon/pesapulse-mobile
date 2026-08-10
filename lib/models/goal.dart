class Goal {
  final int id;
  final int? serverId;
  final int isSynced;

  final String title;
  final double targetAmount;
  final double savedAmount;

  final String? targetDate;

  final String achievement;
  final double completedPercentage;

  final String? createdAt;
  final String? completedAt;
  final String? updatedAt;

  final int isArchived;
  final int isDeleted;

  const Goal({
    required this.id,
    required this.serverId,
    required this.isSynced,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.achievement,
    required this.completedPercentage,
    required this.createdAt,
    required this.completedAt,
    required this.updatedAt,
    required this.isArchived,
    required this.isDeleted,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: _toInt(map['id']),
      serverId: _toNullableInt(map['server_id']),
      isSynced: _toInt(map['is_synced']),
      title: map['title']?.toString() ?? '',
      targetAmount: _toDouble(map['target_amount']),
      savedAmount: _toDouble(map['saved_amount']),
      targetDate: map['target_date']?.toString(),
      achievement: map['achievement']?.toString() ?? '',
      completedPercentage: _toDouble(map['completed_percentage']),
      createdAt: map['created_at']?.toString(),
      completedAt: map['completed_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      isArchived: _toInt(map['is_archived']),
      isDeleted: _toInt(map['is_deleted']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'is_synced': isSynced,
      'title': title,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'target_date': targetDate,
      'achievement': achievement,
      'completed_percentage': completedPercentage,
      'created_at': createdAt,
      'completed_at': completedAt,
      'updated_at': updatedAt,
      'is_archived': isArchived,
      'is_deleted': isDeleted,
    };
  }

  /// ID that should be sent to the API.
  int get requestId {
    if (isSynced == 1 && serverId != null) {
      return serverId!;
    }

    return id;
  }

  double get percentage {
    if (targetAmount <= 0) {
      return 0.0;
    }

    return (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  bool get isCompleted => percentage >= 1.0;

  bool get isAlmostThere => percentage >= 0.75;

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
