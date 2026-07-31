class LoginResponse {
  final String accessToken;
  final String role;

  LoginResponse({required this.accessToken, required this.role});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      role: json['role'] as String,
    );
  }
}
