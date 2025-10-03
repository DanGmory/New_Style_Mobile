import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/register_model.dart';
import '../config/api_config.dart';

class AuthService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;
  
  // Cache para conexiones rápidas
  static String? _cachedSuccessfulIP;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  AuthService();

  /// Inicializar servicio con IP dinámica (debe llamarse antes del primer uso)
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
            print('Error en petición de auth: ${error.message}');
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
        await _getHostIP() ?? 'localhost',
      ];

      for (String ip in commonIPs) {
        final testUrl = "http://$ip:$port";
        if (await _testConnection("$testUrl${ApiConfig.urlLogin}", isAuthEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) {
            print('IP dinámica detectada para Auth: $ip');
          }
          return testUrl;
        }
      }

      _dynamicIp = 'localhost';
      return "http://localhost:$port";
    }
    // Para dispositivos móviles - Conexión optimizada
    else {
      // 0. Verificar conectividad básica primero
      final hasNetwork = await _checkNetworkConnectivity();
      if (!hasNetwork) {
        if (kDebugMode) print('❌ Sin conectividad de red, usando fallback');
        _dynamicIp = '10.0.2.2';
        return "http://10.0.2.2:$port";
      }
      
      // 1. Intentar IP cacheada primero (súper rápido)
      if (_isCacheValid()) {
        final cachedUrl = "http://$_cachedSuccessfulIP:$port";
        if (await _testConnection(
          "$cachedUrl${ApiConfig.urlLogin}", 
          isAuthEndpoint: true,
          quickTest: true
        )) {
          _dynamicIp = _cachedSuccessfulIP;
          if (kDebugMode) print('✅ Conectado con IP cacheada: $_cachedSuccessfulIP');
          return cachedUrl;
        }
      }
      
      // 2. Si no hay cache, usar detección paralela súper rápida
      final String? fastIP = await _fastParallelIPDetection(port);
      if (fastIP != null) {
        _dynamicIp = fastIP;
        _cacheSuccessfulIP(fastIP); // Cachear para próxima vez
        return "http://$fastIP:$port";
      }

      _dynamicIp = '10.0.2.2';
      return "http://10.0.2.2:$port";
    }
  }

  /// Obtener todas las IPs locales del dispositivo y sus redes
  Future<List<String>> _getAllLocalNetworks() async {
    final Set<String> networks = {};
    
    try {
      // Solo intentar obtener interfaces de red en móviles, no en web
      if (kIsWeb) return [];

      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
              
              // Extraer la red base (primeros 3 octetos)
              final parts = ip.split('.');
              if (parts.length >= 3) {
                final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
                networks.add(networkBase);
                
                if (kDebugMode) {
                  print('🌐 Red detectada: $networkBase (desde $ip en ${interface.name})');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo interfaces de red: $e');
      }
    }
    
    return networks.toList();
  }

  /// Obtener IP local principal del dispositivo (compatibilidad con código existente)
  Future<String?> _getLocalIP() async {
    final networks = await _getAllLocalNetworks();
    if (networks.isEmpty) return null;
    
    // Retornar la primera IP encontrada de la primera red
    return '${networks.first}.${networks.first.startsWith('192.168') ? '100' : '50'}';
  }

  /// Verifica si el cache de IP es válido
  bool _isCacheValid() {
    if (_cachedSuccessfulIP == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Verificar conectividad básica de red
  Future<bool> _checkNetworkConnectivity() async {
    try {
      if (kIsWeb) return true;
      
      // Intentar resolver DNS como prueba básica de conectividad
      final result = await InternetAddress.lookup('google.com');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (kDebugMode) {
        print('📡 Conectividad de red: ${hasConnection ? "✅ OK" : "❌ Sin conexión"}');
      }
      
      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print('📡 Error verificando conectividad: $e');
      }
      return false; // Asumir que hay conexión si no se puede verificar
    }
  }

  /// Cachea una IP exitosa para conexiones futuras
  void _cacheSuccessfulIP(String ip) {
    _cachedSuccessfulIP = ip;
    _cacheTimestamp = DateTime.now();
    if (kDebugMode) print('📌 IP cacheada: $ip');
  }

  /// Detección paralela súper rápida de IP del servidor
  Future<String?> _fastParallelIPDetection(int port) async {
    try {
      // 🚀 Detectar automáticamente TODAS las redes del dispositivo
      final List<String> detectedNetworks = await _getAllLocalNetworks();
      
      if (kDebugMode) {
        print('🔍 Redes detectadas automáticamente: $detectedNetworks');
      }
      
      // Lista de redes comunes como fallback
      final List<String> fallbackNetworks = [
        '192.168.1',   // Red doméstica común
        '192.168.0',   // Red doméstica alternativa
        '10.0.0',      // Red corporativa
        '172.16.0',    // Red privada
        '192.168.4',   // Hotspot móvil común
        '10.8.217',    // Red específica detectada anteriormente
      ];
      
      // ✨ Combinar redes detectadas + fallback (detectadas tienen prioridad)
      final Set<String> allNetworks = {};
      allNetworks.addAll(detectedNetworks);
      allNetworks.addAll(fallbackNetworks);
      
      if (kDebugMode) {
        print('🌐 Probando ${allNetworks.length} redes: ${allNetworks.toList()}');
      }
      
      // 🎯 IPs más probables para servidores de desarrollo
      final List<String> priorityIPs = [];
      for (String network in allNetworks) {
        priorityIPs.addAll([
          '$network.8',    // IP común para desarrollo (tu caso específico)
          '$network.1',    // Router/Gateway más común
          '$network.100',  // Rango común para PCs/servidores
          '$network.101',  // Rango común para PCs/servidores
          '$network.102',  // Rango común para PCs/servidores
          '$network.10',   // Servidor común
          '$network.50',   // IP media del rango
          '$network.2',    // Router alternativo
          '$network.5',    // IP común
          '$network.254',  // Último host común
        ]);
      }
      
      // 🚀 IPs especiales para emuladores y localhost
      priorityIPs.insertAll(0, [
        '10.0.2.2',      // Android emulator (siempre primero en emulador)
        '127.0.0.1',     // Localhost
      ]);
      
      if (kDebugMode) {
        print('🚀 Probando ${priorityIPs.length} IPs en paralelo...');
        print('🎯 Primeras 10 IPs a probar: ${priorityIPs.take(10).toList()}');
      }
      
      // Ejecutar todas las pruebas en paralelo con timeout agresivo
      final List<Future<String?>> futures = priorityIPs.map((ip) async {
        try {
          final testUrl = "http://$ip:$port";
          final success = await _testConnection(
            "$testUrl${ApiConfig.urlLogin}",
            isAuthEndpoint: true,
            quickTest: true
          );
          return success ? ip : null;
        } catch (e) {
          return null;
        }
      }).toList();
      
      // Esperar solo por la primera conexión exitosa
      final results = await Future.wait(futures);
      
      for (String? result in results) {
        if (result != null) {
          if (kDebugMode) print('⚡ IP encontrada súper rápido: $result');
          return result;
        }
      }
      
      if (kDebugMode) print('❌ No se encontró IP en detección rápida');
      return null;
      
    } catch (e) {
      if (kDebugMode) print('Error en detección paralela: $e');
      return null;
    }
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
    bool isAuthEndpoint = false,
    bool quickTest = false,
  }) async {
    try {
      // Timeouts súper agresivos para modo rápido
      final timeoutDuration = quickTest 
        ? const Duration(milliseconds: 1500)  // 1.5 segundos para modo rápido
        : const Duration(seconds: 5);         // 5 segundos para modo normal
        
      final testDio = Dio(
        BaseOptions(
          connectTimeout: timeoutDuration,
          receiveTimeout: timeoutDuration,
          sendTimeout: timeoutDuration,
        ),
      );

      // Para endpoints de auth, hacemos un GET simple para ver si responde
      final response = await testDio.get(url.replaceAll(ApiConfig.urlLogin, '/api_v1/status'));
      return response.statusCode == 200 ||
          response.statusCode ==
              404; // 404 también indica que el servidor responde
    } catch (e) {
      // Si falla el /status, probamos directamente con el endpoint base
      try {
        final baseUrl = url.replaceAll(ApiConfig.urlLogin, '/api_v1');
        final Dio testDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        final response = await testDio.get(baseUrl);
        return response.statusCode == 200;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Método de login con reintentos automáticos
  Future<ApiUser> loginUser(String email, String password) async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) print('🚀 Iniciando login súper rápido...');
    
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      if (kDebugMode) print('⚙️ Inicializando servicio...');
      await initialize();
      if (kDebugMode) print('✅ Servicio inicializado en ${stopwatch.elapsedMilliseconds}ms');
    }

    try {
      final response = await _dio!.post(
        ApiConfig.urlLogin,
        data: {"User_mail": email, "User_password": password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final ApiUser user = ApiUser.fromJson(response.data);
        
        // 🚀 CACHEAR IP EXITOSA para conexiones futuras súper rápidas
        if (_dynamicIp != null) {
          _cacheSuccessfulIP(_dynamicIp!);
        }
        
        stopwatch.stop();
        if (kDebugMode) print('⚡ LOGIN EXITOSO en ${stopwatch.elapsedMilliseconds}ms');
        
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
  Future<ApiUser> _loginWithAlternativeIPs(
    String email,
    String password,
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
          print('Intentando login con: $baseUrl');
        }

        final response = await alternativeDio.post(
          ApiConfig.urlLogin,
          data: {"User_mail": email, "User_password": password},
        );

        if (response.statusCode == 200 && response.data != null) {
          if (kDebugMode) {
            print('Login exitoso con: $baseUrl');
          }

          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = baseUrl;
          
          // 🚀 CACHEAR IP EXITOSA para conexiones futuras súper rápidas
          final uri = Uri.parse(baseUrl);
          if (uri.host != 'localhost' && uri.host != '127.0.0.1') {
            _cacheSuccessfulIP(uri.host);
            _dynamicIp = uri.host;
          }

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

  /// Obtener todas las URLs posibles para auth (optimizado con cache)
  Future<List<String>> _getAllPossibleUrls() async {
    const int port = 3000;
    final List<String> urls = [];

    // 🚀 PRIORIDAD MÁXIMA: IP cacheada primero (súper rápido)
    if (_isCacheValid()) {
      urls.add("http://$_cachedSuccessfulIP:$port");
      if (kDebugMode) print('🎯 Usando IP cacheada como prioridad: $_cachedSuccessfulIP');
    }

    // URLs básicas (solo para web)
    if (kIsWeb) {
      urls.addAll([
        "http://localhost:$port",
        "http://127.0.0.1:$port",
      ]);
    }

    // IP detectada dinámicamente (si es diferente al cache)
    if (_dynamicIp != null && _dynamicIp != _cachedSuccessfulIP) {
      urls.add("http://$_dynamicIp:$port");
    }

    // Para móviles
    if (!kIsWeb) {
      urls.add("http://10.0.2.2:$port");

      try {
        final String? localIP = await _getLocalIP();
        if (localIP != null) {
          final parts = localIP.split('.');
          if (parts.length >= 3) {
            final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
            // Solo probar las IPs más comunes para auth (más rápido)
            final commonIPs = [1, 2, 5, 8, 10, 15, 100, 101, 102, 200, 254];
            for (int ip in commonIPs) {
              urls.add("http://$networkBase.$ip:$port");
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
      if (await _testConnection("$testUrl${ApiConfig.urlLogin}", isAuthEndpoint: true)) {
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
  Future<ApiUser> registerUser(
    String name,
    String email,
    String password,
  ) async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.post(
        ApiConfig.urlRegister,
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
          print(
            'Error de conexión en registro, intentando con IPs alternativas...',
          );
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
  Future<ApiUser> _registerWithAlternativeIPs(
    String name,
    String email,
    String password,
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
          ApiConfig.urlRegister,
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
