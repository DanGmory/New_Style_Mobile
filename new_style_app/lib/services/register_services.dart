import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/register_model.dart';

class RegisterService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;

  RegisterService();

  /// Inicializar servicio con IP dinámica
  Future<void> initialize() async {
    if (_isInitialized) return;

    final String baseUrl = await _getBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    // Interceptor para debugging
    _dio!.interceptors.add(
      LogInterceptor(
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        error: kDebugMode,
        logPrint: (obj) {
          if (kDebugMode) print(obj);
        },
      ),
    );

    // Interceptor para manejo de errores
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (kDebugMode) {
            print('Error en petición de registro: ${error.message}');
            print('Tipo de error: ${error.type}');
            print('IP actual: $_dynamicIp');
          }
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  /// Obtener la URL base con IP dinámica
  Future<String> _getBaseUrl() async {
    const int port = 3000;

    // Para Flutter Web
    if (kIsWeb) {
      final List<String> commonIPs = [
        'localhost',
        '127.0.0.1',
        '192.168.1.1',
        '192.168.1.10', // IP específica del ejemplo
        await _getHostIP() ?? 'localhost',
      ];

      for (String ip in commonIPs) {
        final testUrl = "http://$ip:$port/api_v1";
        if (await _testConnection("$testUrl/users", isRegisterEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) {
            print('IP dinámica detectada para Register: $ip');
          }
          return testUrl;
        }
      }

      _dynamicIp = 'localhost';
      return "http://localhost:$port/api_v1";
    }
    // Para dispositivos móviles
    else {
      try {
        final String? deviceIP = await _getLocalIP();
        if (deviceIP != null) {
          final parts = deviceIP.split('.');
          if (parts.length >= 3) {
            final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';

            final List<String> ipsToTest = [
              '$networkBase.1',
              '$networkBase.10', // IP del ejemplo
              '$networkBase.2',
              '$networkBase.100',
              '$networkBase.101',
              '10.0.2.2', // Android emulator
            ];

            for (String ip in ipsToTest) {
              final testUrl = "http://$ip:$port/api_v1";
              if (await _testConnection(
                "$testUrl/users",
                isRegisterEndpoint: true,
              )) {
                _dynamicIp = ip;
                if (kDebugMode) {
                  print('IP dinámica detectada para Register: $ip');
                }
                return testUrl;
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error obteniendo IP local: $e');
        }
      }

      _dynamicIp = '10.0.2.2';
      return "http://10.0.2.2:$port/api_v1";
    }
  }

  /// Obtener IP local del dispositivo (solo para móviles)
  Future<String?> _getLocalIP() async {
    try {
      if (kIsWeb) return null;

      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo interfaces de red: $e');
      }
    }
    return null;
  }

  /// Obtener IP del host (para Flutter Web)
  Future<String?> _getHostIP() async {
    try {
      if (kIsWeb) {
        final currentUrl = Uri.base.host;
        if (currentUrl.isNotEmpty && currentUrl != 'localhost') {
          return currentUrl;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo IP del host: $e');
      }
    }
    return null;
  }

  /// Probar conexión con endpoint específico
  Future<bool> _testConnection(
    String url, {
    bool isRegisterEndpoint = false,
  }) async {
    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      // Para endpoints de registro, hacemos un GET al endpoint base
      final baseUrl = url.replaceAll('/users', '');
      final response = await testDio.get(baseUrl);
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
    }
  }

  /// Registro de usuario con manejo de IP dinámica
  Future<ApiUser> registerUser(
    String username,
    String password,
    String email,
  ) async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.post(
        '/users',
        data: {
          "User_name": username,
          "User_mail": email,
          "User_password": password,
          "User_status": "active",
          "User_role": "user",
        },
      );

      // Depuración: ver respuesta del backend
      if (kDebugMode) {
        print("Respuesta backend (registro): ${response.data}");
      }

      return ApiUser.fromJson(response.data);
    } on DioException catch (e) {
      // Si es un error de conexión, intentamos con IPs alternativas
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        if (kDebugMode) {
          print(
            'Error de conexión en registro, intentando con IPs alternativas...',
          );
        }

        return await _registerWithAlternativeIPs(username, password, email);
      }

      if (kDebugMode) {
        print("Error Dio: ${e.response?.data ?? e.message}");
      }

      // Manejo específico de errores de registro
      if (e.response?.statusCode == 409) {
        throw Exception("El usuario ya existe");
      } else if (e.response?.statusCode == 422) {
        throw Exception("Datos de registro inválidos");
      }

      throw Exception("Error al registrar: ${e.response?.data ?? e.message}");
    } catch (e) {
      if (kDebugMode) {
        print("Error inesperado: $e");
      }
      throw Exception("Error inesperado al registrar: $e");
    }
  }

  /// Intentar registro con IPs alternativas
  Future<ApiUser> _registerWithAlternativeIPs(
    String username,
    String password,
    String email,
  ) async {
    final List<String> alternativeUrls = await _getAllPossibleUrls();

    for (String baseUrl in alternativeUrls) {
      try {
        final alternativeDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          ),
        );

        if (kDebugMode) {
          print('Intentando registro con: $baseUrl');
        }

        final response = await alternativeDio.post(
          '/users',
          data: {
            "User_name": username,
            "User_mail": email,
            "User_password": password,
            "User_status": "active",
            "User_role": "user",
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (kDebugMode) {
            print('Registro exitoso con: $baseUrl');
            print("Respuesta backend: ${response.data}");
          }

          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = baseUrl;

          return ApiUser.fromJson(response.data);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error con $baseUrl: $e');
        }
        continue;
      }
    }

    throw Exception("No se pudo conectar con el servidor para registro");
  }

  /// Obtener todas las URLs posibles para registro
  Future<List<String>> _getAllPossibleUrls() async {
    const int port = 3000;
    final List<String> urls = [];

    // URLs básicas
    urls.addAll([
      "http://localhost:$port/api_v1",
      "http://127.0.0.1:$port/api_v1",
      "http://192.168.1.10:$port/api_v1", // IP del ejemplo
    ]);

    // Agregar IP detectada dinámicamente
    if (_dynamicIp != null) {
      urls.add("http://$_dynamicIp:$port/api_v1");
    }

    // Para móviles
    if (!kIsWeb) {
      urls.add("http://10.0.2.2:$port/api_v1");

      try {
        final String? localIP = await _getLocalIP();
        if (localIP != null) {
          final parts = localIP.split('.');
          if (parts.length >= 3) {
            final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
            // Solo las IPs más comunes para registro (más rápido)
            final commonIPs = [1, 2, 10, 100, 101, 102, 200, 254];
            for (int ip in commonIPs) {
              urls.add("http://$networkBase.$ip:$port/api_v1");
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error generando IPs de red: $e');
      }
    }

    return urls;
  }

  /// Método para verificar conectividad del servicio de registro
  Future<bool> checkRegisterConnection() async {
    final List<String> testUrls = await _getAllPossibleUrls();

    for (String testUrl in testUrls) {
      if (await _testConnection("$testUrl/users", isRegisterEndpoint: true)) {
        if (kDebugMode) {
          print('Servidor de registro encontrado en: $testUrl');
        }
        return true;
      }
    }
    return false;
  }

  /// Obtener la IP actual que está siendo usada
  String? getCurrentIP() {
    return _dynamicIp;
  }

  /// Método para forzar reconexión con nueva detección de IP
  Future<void> reconnect() async {
    _dynamicIp = null;
    _isInitialized = false;
    _dio = null;
    await initialize();
  }

  /// Método adicional para verificar disponibilidad de username/email
  Future<bool> checkUserAvailability(String username, String email) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.get(
        '/users/check',
        queryParameters: {'username': username, 'email': email},
      );

      return response.statusCode == 200;
    } catch (e) {
      // Si falla la verificación, asumimos que está disponible
      return true;
    }
  }
}
