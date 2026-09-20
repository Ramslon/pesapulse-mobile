import '../models/premium_feature.dart';
import '../models/subscription_state.dart';
import '../../services/api_services.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionState _state = const SubscriptionState();

  SubscriptionState get state => _state;

  bool get isPremium => _state.isPremium;

  bool canAccess(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.advancedBudgetInsights:
      case PremiumFeature.advancedAnalytics:
      case PremiumFeature.spendingForecast:
      case PremiumFeature.advancedGoalTracking:
      case PremiumFeature.advancedGoalForecast:
      case PremiumFeature.budgetSimulation:
      case PremiumFeature.historicalInsights:
        return isPremium;
    }
  }

  Future<SubscriptionState> loadSubscription({
    bool forceRefresh = false,
  }) async {
    if (_state.hasLoaded && !forceRefresh) {
      return _state;
    }

    _state = _state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await ApiService.getSubscription();

      final subscription = data['subscription'] is Map<String, dynamic>
          ? data['subscription'] as Map<String, dynamic>
          : <String, dynamic>{};

      final planValue = subscription['plan']?.toString().toLowerCase();

      final plan = planValue == 'premium'
          ? SubscriptionPlan.premium
          : SubscriptionPlan.basic;

      final status = subscription['status']?.toString() ?? 'active';

      final startsAt = _parseDate(subscription['starts_at']);

      final expiresAt = _parseDate(subscription['expires_at']);

      _state = SubscriptionState(
        plan: plan,
        status: status,
        isLoading: false,
        hasLoaded: true,
        startsAt: startsAt,
        expiresAt: expiresAt,
      );

      return _state;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        hasLoaded: false,
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  void setPlan({
    required SubscriptionPlan plan,
    DateTime? startsAt,
    DateTime? expiresAt,
    String status = 'active',
  }) {
    _state = SubscriptionState(
      plan: plan,
      status: status,
      isLoading: false,
      hasLoaded: true,
      startsAt: startsAt,
      expiresAt: expiresAt,
    );
  }

  void setLoading(bool value) {
    _state = _state.copyWith(isLoading: value);
  }

  void reset() {
    _state = const SubscriptionState();
  }
}
