class AuthException implements Exception {
  final String message;
  final int? remaining;

  AuthException({required this.message, this.remaining});

  @override
  String toString() => message;
}
