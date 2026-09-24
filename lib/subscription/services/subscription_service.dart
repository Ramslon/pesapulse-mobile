import 'dart:async';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/premium_payment_result.dart';

import '../models/premium_feature.dart';
import '../models/subscription_state.dart';
import '../../services/api_services.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  static const String _pendingCheckoutReferenceKey =
      'pending_premium_checkout_reference';

  static const String _premiumCacheFlagPrefix = 'pesapulse_premium_access_';

  static const String _premiumCacheExpiryPrefix = 'pesapulse_premium_expiry_';

  SubscriptionState _state = const SubscriptionState();

  SubscriptionState get state => _state;

  bool get isPremium => _state.isPremium;

  bool get hasCachedPremiumAccess => _cachedPremiumAccess ?? false;

  bool get hasPremiumAccess {
    return isPremium || hasCachedPremiumAccess;
  }

  bool? _cachedPremiumAccess;

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

  Future<String?> _getCurrentOwnerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ownerId = prefs.getString('owner_id');

      if (ownerId == null || ownerId.isEmpty || ownerId == 'guest') {
        return null;
      }

      return ownerId;
    } catch (e) {
      debugPrint('SubscriptionService: failed to read owner id: $e');

      return null;
    }
  }

  String _premiumCacheFlagKey(String ownerId) {
    return '$_premiumCacheFlagPrefix$ownerId';
  }

  String _premiumCacheExpiryKey(String ownerId) {
    return '$_premiumCacheExpiryPrefix$ownerId';
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

      if (_state.isPremium) {
        await cacheCurrentPremiumAccess();
        _cachedPremiumAccess = true;
      } else {
        await clearCachedPremiumAccess();
        _cachedPremiumAccess = false;
      }

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

  Future<bool> getCachedPremiumAccess() async {
    try {
      final ownerId = await _getCurrentOwnerId();

      if (ownerId == null) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      final cachedPremium =
          prefs.getBool(_premiumCacheFlagKey(ownerId)) ?? false;

      if (!cachedPremium) {
        return false;
      }

      final expiryValue = prefs.getString(_premiumCacheExpiryKey(ownerId));

      if (expiryValue == null || expiryValue.isEmpty) {
        return true;
      }

      final expiresAt = DateTime.tryParse(expiryValue)?.toUtc();

      if (expiresAt == null) {
        return true;
      }

      if (!expiresAt.isAfter(DateTime.now().toUtc())) {
        await clearCachedPremiumAccess();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint(
        'SubscriptionService: failed to read cached Premium access: $e',
      );

      return false;
    }
  }

  Future<void> cacheCurrentPremiumAccess() async {
    try {
      final ownerId = await _getCurrentOwnerId();

      if (ownerId == null) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      if (!isPremium) {
        await clearCachedPremiumAccess();
        return;
      }

      await prefs.setBool(_premiumCacheFlagKey(ownerId), true);

      final expiresAt = _state.expiresAt;

      if (expiresAt != null) {
        await prefs.setString(
          _premiumCacheExpiryKey(ownerId),
          expiresAt.toUtc().toIso8601String(),
        );
      } else {
        await prefs.remove(_premiumCacheExpiryKey(ownerId));
      }

      debugPrint('SubscriptionService: Premium entitlement cached locally.');
    } catch (e) {
      debugPrint(
        'SubscriptionService: failed to cache Premium entitlement: $e',
      );
    }
  }

  Future<void> clearCachedPremiumAccess() async {
    try {
      final ownerId = await _getCurrentOwnerId();

      if (ownerId == null) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_premiumCacheFlagKey(ownerId));

      await prefs.remove(_premiumCacheExpiryKey(ownerId));

      debugPrint('SubscriptionService: cached Premium entitlement cleared.');
    } catch (e) {
      debugPrint(
        'SubscriptionService: failed to clear cached Premium entitlement: $e',
      );
    }
  }

  Future<bool> restoreCachedPremiumAccess() async {
    final cached = await getCachedPremiumAccess();

    _cachedPremiumAccess = cached;

    return cached;
  }

  Future<bool> restoreOfflinePremiumAccess() async {
    if (isPremium) {
      _cachedPremiumAccess = true;
      return true;
    }

    return restoreCachedPremiumAccess();
  }

  Future<String> createPremiumCheckout() async {
    final response = await ApiService.createPremiumCheckout();

    final checkoutUrl = response['checkout_url']?.toString().trim();

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception(
        'The Premium checkout URL was not returned by the server.',
      );
    }

    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      throw Exception('The Premium checkout URL is invalid.');
    }

    return checkoutUrl;
  }

  Future<void> openPremiumCheckout() async {
    final response = await ApiService.createPremiumCheckout();

    final checkoutUrl = response['checkout_url']?.toString().trim();

    final reference = response['reference']?.toString().trim();

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception(
        'The Premium checkout URL was not returned by the server.',
      );
    }

    if (reference == null || reference.isEmpty) {
      throw Exception(
        'The Premium payment reference was not returned by the server.',
      );
    }

    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      throw Exception('The Premium checkout URL is invalid.');
    }

    // Store the exact transaction reference before
    // opening the external checkout.
    await _savePendingCheckoutReference(reference);

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      await _clearPendingCheckoutReference();

      throw Exception('Unable to open the Premium payment page.');
    }
  }

  Future<PremiumPaymentResult?> verifyPendingPayment({
    int attempts = 4,
    Duration delay = const Duration(seconds: 2),
  }) async {
    final reference = await _getPendingCheckoutReference();

    if (reference == null || reference.isEmpty) {
      return null;
    }

    PremiumPaymentResult? latestResult;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final data = await ApiService.getPremiumPaymentStatus(
          reference: reference,
        );

        final result = PremiumPaymentResult.fromJson(data);

        latestResult = result;

        if (result.isComplete) {
          await loadSubscription(forceRefresh: true);

          if (_state.isPremium) {
            await cacheCurrentPremiumAccess();
            _cachedPremiumAccess = true;
          }

          await _clearPendingCheckoutReference();

          return result;
        }

        if (result.isFailed) {
          await _clearPendingCheckoutReference();

          return result;
        }

        if (attempt < attempts - 1) {
          await Future<void>.delayed(delay);
        }
      } catch (e) {
        if (attempt == attempts - 1) {
          rethrow;
        }

        await Future<void>.delayed(delay);
      }
    }

    return latestResult;
  }

  Future<void> _savePendingCheckoutReference(String reference) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_pendingCheckoutReferenceKey, reference);
  }

  Future<String?> _getPendingCheckoutReference() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_pendingCheckoutReferenceKey);
  }

  Future<void> _clearPendingCheckoutReference() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pendingCheckoutReferenceKey);
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
