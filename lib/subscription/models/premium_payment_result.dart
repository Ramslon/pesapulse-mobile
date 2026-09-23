enum PremiumPaymentStatus { pending, processing, complete, failed, unknown }

class PremiumPaymentResult {
  final String reference;
  final PremiumPaymentStatus status;
  final bool isPremium;
  final String message;
  final String? paymentMethod;
  final DateTime? paidAt;

  const PremiumPaymentResult({
    required this.reference,
    required this.status,
    required this.isPremium,
    required this.message,
    this.paymentMethod,
    this.paidAt,
  });

  bool get isComplete => status == PremiumPaymentStatus.complete;

  bool get isFailed => status == PremiumPaymentStatus.failed;

  bool get isPending =>
      status == PremiumPaymentStatus.pending ||
      status == PremiumPaymentStatus.processing;

  factory PremiumPaymentResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toLowerCase() ?? '';

    final status = switch (rawStatus) {
      'pending' => PremiumPaymentStatus.pending,
      'processing' => PremiumPaymentStatus.processing,
      'complete' => PremiumPaymentStatus.complete,
      'failed' => PremiumPaymentStatus.failed,
      _ => PremiumPaymentStatus.unknown,
    };

    final transaction = json['transaction'] is Map<String, dynamic>
        ? json['transaction'] as Map<String, dynamic>
        : <String, dynamic>{};

    return PremiumPaymentResult(
      reference: json['reference']?.toString() ?? '',
      status: status,
      isPremium: json['is_premium'] == true,
      message: json['message']?.toString() ?? 'Payment status unavailable.',
      paymentMethod: transaction['payment_method']?.toString(),
      paidAt: DateTime.tryParse(transaction['paid_at']?.toString() ?? ''),
    );
  }
}
