import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/register_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import 'cache_service.dart';

class AuthService {
  late Dio _dio;
  final CacheService _cacheService = CacheService();
  
  static const String _userCachePrefix = 'user_';

  AuthService() {
    _dio = HttpService().dio;
  }

  /// Login de usuario con caché de sesión
  Future<ApiUser> login(String email, String password) async {
    try {
      if (kDebugMode) debugPrint('🔐 Iniciando login con: $email');
      
      final response = await _dio.post(
        ApiConfig.urlLogin,
        data: {"User_mail": email, "User_password": password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final ApiUser user = ApiUser.fromJson(response.data as Map<String, dynamic>);
        
        // Guardar sesión y caché del usuario
        await Future.wait([
          _saveUserSession(user, email),
          _cacheService.setCache(
            '$_userCachePrefix${user.id}',
            response.data,
            cacheDuration: CacheService.userCacheDuration,
          ),
        ]);

        if (kDebugMode) debugPrint('✅ Login exitoso para ${user.name}');
        return user;
      } else {
        throw Exception('❌ Acceso denegado: Usuario no registrado');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('❌ Acceso denegado: Credenciales inválidas');
      }
      if (kDebugMode) debugPrint('❌ Error login: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Registro de usuario
  Future<ApiUser> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) debugPrint('📝 Registrando usuario: $email');
      
      final response = await _dio.post(
        ApiConfig.urlRegister,
        data: {
          "User_name": name,
          "User_mail": email,
          "User_password": password,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final ApiUser user = ApiUser.fromJson(response.data as Map<String, dynamic>);
        
        // Guardar sesión inmediatamente después del registro
        await _saveUserSession(user, email);
        
        if (kDebugMode) debugPrint('✅ Registro exitoso para ${user.name}');
        return user;
      } else {
        throw Exception('❌ Error al registrar usuario');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('❌ El usuario ya existe');
      }
      if (kDebugMode) debugPrint('❌ Error registro: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Obtener usuario por ID con caché
  Future<ApiUser?> getUserById(int userId) async {
    try {
      final cacheKey = '$_userCachePrefix$userId';
      
      // Intentar caché primero
      final cached = _cacheService.getCache<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Usuario $userId desde caché');
        return ApiUser.fromJson(cached);
      }

      // Obtener del servidor
      if (kDebugMode) debugPrint('📡 Obteniendo usuario $userId del servidor');
      final response = await _dio.get('${ApiConfig.urlUsers}/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final user = ApiUser.fromJson(response.data as Map<String, dynamic>);
        
        // Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          response.data,
          cacheDuration: CacheService.userCacheDuration,
        );

        return user;
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo usuario: ${_handleDioError(e)}');
      return null;
    }
  }

  /// Actualizar perfil de usuario
  Future<ApiUser> updateProfile(int userId, Map<String, dynamic> profileData) async {
    try {
      if (kDebugMode) debugPrint('✏️ Actualizando perfil del usuario $userId');
      
      final response = await _dio.put(
        '${ApiConfig.urlUsers}/$userId',
        data: profileData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final user = ApiUser.fromJson(response.data as Map<String, dynamic>);
        
        // Invalidar caché del usuario
        await _cacheService.removeCache('$_userCachePrefix$userId');
        
        // Actualizar sesión con nuevos datos
        await _saveUserSession(user, user.email);

        if (kDebugMode) debugPrint('✅ Perfil actualizado correctamente');
        return user;
      }
      throw Exception('❌ No se pudo actualizar el perfil');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error actualizando perfil: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Logout del usuario
  Future<void> logout() async {
    try {
      if (kDebugMode) debugPrint('👋 Cerrando sesión...');
      
      await Future.wait([
        clearUserSession(),
        _cacheService.clearCachePattern('$_userCachePrefix.*'),
      ]);

      if (kDebugMode) debugPrint('✅ Sesión cerrada');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error en logout: $e');
      // No relanzamos excepción para permitir cierre forzado
    }
  }

  /// Cambiar contraseña del usuario
  Future<void> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      if (kDebugMode) debugPrint('🔑 Cambiando contraseña del usuario $userId');
      
      final response = await _dio.post(
        '${ApiConfig.urlUsers}/$userId/change-password',
        data: {
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ Contraseña cambiada correctamente');
      } else {
        throw Exception('❌ No se pudo cambiar la contraseña');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('❌ Contraseña antigua incorrecta');
      }
      if (kDebugMode) debugPrint('❌ Error cambiando contraseña: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Verificar conectividad del servidor de autenticación
  Future<bool> checkAuthConnection() async {
    try {
      if (kDebugMode) debugPrint('🔌 Verificando conectividad de auth...');
      final response = await _dio.get(
        ApiConfig.urlLogin,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Guardar información de sesión en SharedPreferences
  Future<void> _saveUserSession(ApiUser user, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('currentUserId', user.id.toString());
      await prefs.setString('currentUserEmail', email);
      await prefs.setString('currentUserName', user.name);
      
      if (user.token.isNotEmpty) {
        await prefs.setString('userToken', user.token);
      }
      
      if (kDebugMode) {
        debugPrint('💾 Sesión guardada: ID=${user.id}, Email=$email');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error guardando sesión: $e');
    }
  }

  /// Limpiar información de sesión
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUserId');
      await prefs.remove('currentUserEmail');
      await prefs.remove('currentUserName');
      await prefs.remove('userToken');
      
      if (kDebugMode) debugPrint('🗑️ Sesión limpiada');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error limpiando sesión: $e');
    }
  }

  /// Obtener información de sesión actual
  Future<Map<String, String?>> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString('currentUserId'),
        'userEmail': prefs.getString('currentUserEmail'),
        'userName': prefs.getString('currentUserName'),
        'userToken': prefs.getString('userToken'),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo sesión: $e');
      return {};
    }
  }

  /// Verificar si hay sesión activa
  Future<bool> hasActiveSession() async {
    final session = await getCurrentSession();
    return session['userId'] != null && session['userId']!.isNotEmpty;
  }

  /// Obtener usuario actual desde sesión
  Future<ApiUser?> getCurrentUser() async {
    try {
      final session = await getCurrentSession();
      final userId = session['userId'];
      
      if (userId == null || userId.isEmpty) return null;
      
      return getUserById(int.parse(userId));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Manejar errores de Dio
  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Timeout de conexión';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Timeout de recepción';
    } else if (e.type == DioExceptionType.badResponse) {
      return '${e.response?.statusCode}: ${e.response?.data}';
    } else if (e.type == DioExceptionType.unknown) {
      return e.error?.toString() ?? 'Error desconocido';
    }
    return e.message ?? 'Error en la solicitud';
  }

  /// Limpiar caché de usuarios
  Future<void> clearUsersCache() async {
    await _cacheService.clearCachePattern('$_userCachePrefix.*');
    if (kDebugMode) debugPrint('🧹 Caché de usuarios limpiado');
  }

  /// Obtener tamaño del caché de autenticación en KB
  int getAuthCacheSize() {
    return _cacheService.getCacheSize();
  }
}
