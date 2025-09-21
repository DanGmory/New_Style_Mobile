class ApiUser {
  final int id;
  final String name;
  final String email;
  final int role;
  final int state;
  final String token;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.state,
    required this.token,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    // Ajustamos: el backend devuelve "data"
    final user = json['data'] ?? json['user'] ?? {};

    return ApiUser(
      id: user['User_id'] ?? 0,
      name: user['User_name'] ?? '',
      email: user['User_mail'] ?? '',
      role: user['Role_fk'] ?? 0,
      state: user['State_user_fk'] ?? 0,
      token: json['token'] ?? '',
    );
  }
}
