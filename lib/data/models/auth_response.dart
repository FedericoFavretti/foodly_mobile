class AuthResponse {
  const AuthResponse({required this.token});

  final String token;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(token: json['token'] as String);
  }
}
