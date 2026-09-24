import 'package:flutter/foundation.dart';

import '../models/premium_feature.dart';
import '../models/subscription_state.dart';
import '../models/premium_payment_result.dart';
import '../services/subscription_service.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionService service;

  SubscriptionController({SubscriptionService? service})
    : service = service ?? SubscriptionService.instance;

  SubscriptionState get state => service.state;

  bool get isPremium => service.isPremium;

  bool get hasPremiumAccess => service.hasPremiumAccess;

  bool get hasCachedPremiumAccess => service.hasCachedPremiumAccess;

  bool canAccess(PremiumFeature feature) {
    return service.canAccess(feature);
  }

  Future<void> loadSubscription({bool forceRefresh = false}) async {
    try {
      await service.loadSubscription(forceRefresh: forceRefresh);
    } finally {
      notifyListeners();
    }
  }

  Future<void> startPremiumCheckout() async {
    await service.openPremiumCheckout();
  }

  Future<PremiumPaymentResult?> verifyPendingPayment({
    int attempts = 4,
    Duration delay = const Duration(seconds: 2),
  }) async {
    final result = await service.verifyPendingPayment(
      attempts: attempts,
      delay: delay,
    );

    notifyListeners();

    return result;
  }

  Future<bool> restoreOfflinePremiumAccess() async {
    final result = await service.restoreOfflinePremiumAccess();
    notifyListeners();
    return result;
  }

  Future<void> cacheCurrentPremiumAccess() async {
    await service.cacheCurrentPremiumAccess();
    notifyListeners();
  }

  Future<void> clearCachedPremiumAccess() async {
    await service.clearCachedPremiumAccess();
    notifyListeners();
  }

  Future<bool> getCachedPremiumAccess() async {
    return service.getCachedPremiumAccess();
  }

  void setPlan({
    required SubscriptionPlan plan,
    DateTime? startsAt,
    DateTime? expiresAt,
    String status = 'active',
  }) {
    service.setPlan(
      plan: plan,
      startsAt: startsAt,
      expiresAt: expiresAt,
      status: status,
    );

    notifyListeners();
  }

  void setLoading(bool value) {
    service.setLoading(value);
    notifyListeners();
  }

  void reset() {
    service.reset();
    notifyListeners();
  }
}
