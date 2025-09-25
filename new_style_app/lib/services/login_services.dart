import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/register_model.dart';

class AuthService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;

  AuthService();

  /// Inicializar servicio con IP dinámica (debe llamarse antes del primer uso)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final String baseUrl = await _getBaseUrl();
    
    _dio = Dio(BaseOptions(
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
    ));

    // Interceptor para debugging
    _dio!.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      error: kDebugMode,
      logPrint: (obj) {
        if (kDebugMode) print(obj);
      },
    ));

    // Interceptor para manejo de errores
    _dio!.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          print('Error en petición de auth: ${error.message}');
          print('Tipo de error: ${error.type}');
          print('IP actual: $_dynamicIp');
        }
        handler.next(error);
      },
    ));
    
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
        await _getHostIP() ?? 'localhost',
      ];
      
      for (String ip in commonIPs) {
        final testUrl = "http://$ip:$port/api_v1";
        if (await _testConnection("$testUrl/login", isAuthEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) {
            print('IP dinámica detectada para Auth: $ip');
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
              '$networkBase.10', // IP común para servidores
              '$networkBase.100',
              '$networkBase.101',
              '$networkBase.2',
              '10.0.2.2',
            ];
            
            for (String ip in ipsToTest) {
              final testUrl = "http://$ip:$port/api_v1";
              if (await _testConnection("$testUrl/login", isAuthEndpoint: true)) {
                _dynamicIp = ip;
                if (kDebugMode) {
                  print('IP dinámica detectada para Auth: $ip');
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
      // Solo intentar obtener interfaces de red en móviles, no en web
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
  Future<bool> _testConnection(String url, {bool isAuthEndpoint = false}) async {
    try {
      final testDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      // Para endpoints de auth, hacemos un GET simple para ver si responde
      final response = await testDio.get(url.replaceAll('/login', '/status'));
      return response.statusCode == 200 || response.statusCode == 404; // 404 también indica que el servidor responde
    } catch (e) {
      // Si falla el /status, probamos directamente con el endpoint base
      try {
        final baseUrl = url.replaceAll('/login', '');
        final Dio testDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        final response = await testDio.get(baseUrl);
        return response.statusCode == 200;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Método de login con reintentos automáticos
  Future<ApiUser> loginUser(String email, String password) async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      await initialize();
    }
    
    try {
      final response = await _dio!.post(
        '/login',
        data: {
          "User_mail": email,
          "User_password": password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final ApiUser user = ApiUser.fromJson(response.data);
        return user;
      } else {
        throw Exception("Acceso denegado: Usuario no registrado");
      }
    } on DioException catch (e) {
      // Si es un error de conexión, intentamos con IPs alternativas
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        
        if (kDebugMode) {
          print('Error de conexión, intentando con IPs alternativas...');
        }
        
        return await _loginWithAlternativeIPs(email, password);
      }
      
      if (e.response?.statusCode == 401) {
        throw Exception("Acceso denegado: Credenciales inválidas");
      }
      throw Exception("Error en login: ${e.response?.data ?? e.message}");
    }
  }

  /// Intentar login con IPs alternativas
  Future<ApiUser> _loginWithAlternativeIPs(String email, String password) async {
    final List<String> alternativeUrls = await _getAllPossibleUrls();
    
    for (String baseUrl in alternativeUrls) {
      try {
        final alternativeDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ));

        if (kDebugMode) {
          print('Intentando login con: $baseUrl');
        }

        final response = await alternativeDio.post(
          '/login',
          data: {
            "User_mail": email,
            "User_password": password,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          if (kDebugMode) {
            print('Login exitoso con: $baseUrl');
          }
          
          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = baseUrl;
          
          final ApiUser user = ApiUser.fromJson(response.data);
          return user;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error con $baseUrl: $e');
        }
        continue;
      }
    }
    
    throw Exception("No se pudo conectar con el servidor de autenticación");
  }

  /// Obtener todas las URLs posibles para auth
  Future<List<String>> _getAllPossibleUrls() async {
    const int port = 3000;
    final List<String> urls = [];
    
    // URLs básicas
    urls.addAll([
      "http://localhost:$port/api_v1",
      "http://127.0.0.1:$port/api_v1",
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
            // Solo probar las IPs más comunes para auth (más rápido)
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

  /// Método para verificar conectividad del servicio de auth
  Future<bool> checkAuthConnection() async {
    final List<String> testUrls = await _getAllPossibleUrls();
    
    for (String testUrl in testUrls) {
      if (await _testConnection("$testUrl/login", isAuthEndpoint: true)) {
        if (kDebugMode) {
          print('Servidor de auth encontrado en: $testUrl');
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

  /// Método adicional para registro de usuario (si lo necesitas)
  Future<ApiUser> registerUser(String name, String email, String password) async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      await initialize();
    }
    
    try {
      final response = await _dio!.post(
        '/register',
        data: {
          "User_name": name,
          "User_mail": email,
          "User_password": password,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final ApiUser user = ApiUser.fromJson(response.data);
        return user;
      } else {
        throw Exception("Error al registrar usuario");
      }
    } on DioException catch (e) {
      // Si es un error de conexión, intentamos con IPs alternativas
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        
        if (kDebugMode) {
          print('Error de conexión en registro, intentando con IPs alternativas...');
        }
        
        return await _registerWithAlternativeIPs(name, email, password);
      }
      
      if (e.response?.statusCode == 409) {
        throw Exception("El usuario ya existe");
      }
      throw Exception("Error en registro: ${e.response?.data ?? e.message}");
    }
  }

  /// Intentar registro con IPs alternativas
  Future<ApiUser> _registerWithAlternativeIPs(String name, String email, String password) async {
    final List<String> alternativeUrls = await _getAllPossibleUrls();
    
    for (String baseUrl in alternativeUrls) {
      try {
        final alternativeDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ));

        if (kDebugMode) {
          print('Intentando registro con: $baseUrl');
        }

        final response = await alternativeDio.post(
          '/register',
          data: {
            "User_name": name,
            "User_mail": email,
            "User_password": password,
          },
        );

        if (response.statusCode == 201 && response.data != null) {
          if (kDebugMode) {
            print('Registro exitoso con: $baseUrl');
          }
          
          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = baseUrl;
          
          final ApiUser user = ApiUser.fromJson(response.data);
          return user;
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
}