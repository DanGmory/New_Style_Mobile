import 'package:dio/dio.dart';
import '../models/register_model.dart'; // ✅ Aquí está ApiUser

class AuthService {
  late final Dio _dio;

  AuthService() {
    const String localIp = "192.168.1.2"; // 👉 tu IP real
    const int port = 3000;

    final String baseUrl = "http://$localIp:$port/api_v1";

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {"Content-Type": "application/json"},
      ),
    );
  }

  Future<ApiUser> loginUser(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          "User_mail": email,
          "User_password": password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // 👇 Parseamos directamente con ApiUser
        final ApiUser user = ApiUser.fromJson(response.data);
        return user;
      } else {
        throw Exception("Acceso denegado: Usuario no registrado");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception("Acceso denegado: Credenciales inválidas");
      }
      throw Exception("Error en login: ${e.response?.data ?? e.message}");
    }
  }
}
