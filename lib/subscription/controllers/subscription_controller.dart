import 'package:flutter/foundation.dart';

import '../models/premium_feature.dart';
import '../models/subscription_state.dart';
import '../services/subscription_service.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionService service;

  SubscriptionController({SubscriptionService? service})
    : service = service ?? SubscriptionService.instance;

  SubscriptionState get state => service.state;

  bool get isPremium => service.isPremium;

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
