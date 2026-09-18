import 'package:flutter/material.dart';

import '../premium/premium_feature_dialog.dart';
import '../../subscription/models/premium_feature.dart';
import '../../subscription/services/subscription_service.dart';

class PremiumFeatureGuard {
  PremiumFeatureGuard._();

  static Future<bool> check({
    required BuildContext context,
    required PremiumFeature feature,
    VoidCallback? onUpgrade,
  }) async {
    final service = SubscriptionService.instance;

    try {
      await service.loadSubscription();
    } catch (e) {
      if (!context.mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to verify your Premium subscription. Please try again.',
          ),
        ),
      );

      return false;
    }

    if (service.canAccess(feature)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    await showDialog<void>(
      context: context,
      builder: (_) =>
          PremiumFeatureDialog(feature: feature, onUpgrade: onUpgrade),
    );

    return false;
  }
}
