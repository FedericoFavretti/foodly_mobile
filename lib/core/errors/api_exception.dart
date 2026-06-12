class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.userMessage,
    this.debugInfo,
  });

  final int statusCode;
  final String userMessage;
  final String? debugInfo;

  @override
  String toString() => 'ApiException($statusCode): $userMessage';
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

class NetworkException implements Exception {
  const NetworkException([
    this.userMessage = 'Sin conexión. Verificá tu red e intentá nuevamente.',
  ]);

  final String userMessage;
}
