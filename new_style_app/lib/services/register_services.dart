import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import '../models/register_model.dart';

class RegisterService {
  late final Dio _dio;

  RegisterService() {
    const String localIp = "192.168.1.7"; 
    const int port = 3000;

    final String baseUrl = kIsWeb
        ? "http://$localIp:$port/api_v1"
        : "http://10.0.2.2:$port/api_v1";

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {"Content-Type": "application/json"},
      ),
    );
  }

  /// 🔹 Registro de usuario
  Future<ApiUser> registerUser(
      String username, String password, String email) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          "User_name": username,
          "User_mail": email,
          "User_password": password,
          "User_status": "active",
          "User_role": "user",
        },
      );

      // 🔹 Depuración: ver respuesta del backend
      debugPrint("🔹 Respuesta backend (registro): ${response.data}");

      return ApiUser.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(" Error Dio: ${e.response?.data ?? e.message}");
      throw Exception("Error al registrar: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint(" Error inesperado: $e");
      throw Exception("Error inesperado al registrar: $e");
    }
  }
}
