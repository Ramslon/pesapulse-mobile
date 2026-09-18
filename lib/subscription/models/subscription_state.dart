enum SubscriptionPlan { basic, premium }

class SubscriptionState {
  final SubscriptionPlan plan;
  final String status;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  const SubscriptionState({
    this.plan = SubscriptionPlan.basic,
    this.status = 'active',
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
    this.startsAt,
    this.expiresAt,
  });

  bool get isPremium {
    if (plan != SubscriptionPlan.premium) {
      return false;
    }

    if (status != 'active') {
      return false;
    }

    final now = DateTime.now();

    if (startsAt != null && startsAt!.isAfter(now)) {
      return false;
    }

    if (expiresAt != null && expiresAt!.isBefore(now)) {
      return false;
    }

    return true;
  }

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    String? status,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool clearDates = false,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      startsAt: clearDates ? null : startsAt ?? this.startsAt,
      expiresAt: clearDates ? null : expiresAt ?? this.expiresAt,
    );
  }
}
