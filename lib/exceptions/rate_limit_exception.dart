class RateLimitException implements Exception {
  final String message;
  final int? retryAfter;
  final int? remaining;

  const RateLimitException({
    required this.message,
    this.retryAfter,
    this.remaining,
  });

  @override
  String toString() => message;
}
