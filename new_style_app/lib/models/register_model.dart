import 'package:flutter/foundation.dart';

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
    // Ajustamos: el backend puede devolver "data", "user" o directamente los campos
    final user = json['data'] ?? json['user'] ?? json;
    
    // Debug: Solo en modo debug
    if (kDebugMode) {
      print('🔍 ApiUser.fromJson recibió: $json');
      print('🔍 Usuario extraído: $user');
    }

    final userId = user['User_id'] ?? user['id'] ?? 0;
    if (kDebugMode) {
      print('🔍 ID de usuario extraído: $userId');
    }

    return ApiUser(
      id: userId,
      name: user['User_name'] ?? user['name'] ?? '',
      email: user['User_mail'] ?? user['email'] ?? '',
      role: user['Role_fk'] ?? user['role'] ?? 0,
      state: user['State_user_fk'] ?? user['state'] ?? 1,
      token: json['token'] ?? user['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'state': state,
      'token': token,
    };
  }
}
