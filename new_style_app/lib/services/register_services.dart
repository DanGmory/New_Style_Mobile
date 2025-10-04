import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/register_model.dart';
import '../config/api_config.dart';

class RegisterService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;
  
  // Cache para conexiones rápidas
  static String? _cachedSuccessfulIP;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

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

  /// Obtener la URL base con detección inteligente de red súper optimizada
  Future<String> _getBaseUrl() async {
    const int port = 3000;

    if (kDebugMode) print('🔍 Iniciando detección inteligente de red para RegisterService...');

    // 1. Para Flutter Web - detección simple pero efectiva
    if (kIsWeb) {
      final List<String> webIPs = [
        '192.168.1.8',  // Tu IP específica (PRIORIDAD 1)
        'localhost',
        '127.0.0.1',
        '192.168.1.1',
        await _getHostIP() ?? 'localhost',
      ];

      if (kDebugMode) print('🌐 Probando IPs para Web Register: $webIPs');

      for (String ip in webIPs) {
        final testUrl = "http://$ip:$port";
        if (kDebugMode) print('🔍 Probando IP Web: $ip');
        
        if (await _testConnection("$testUrl${ApiConfig.urlRegister}", isRegisterEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) print('✅ IP detectada para Register (Web): $ip usando ${ApiConfig.urlRegister}');
          return testUrl;
        }
      }

      if (kDebugMode) print('⚠️ Ninguna IP funcionó, usando localhost por defecto');
      _dynamicIp = 'localhost';
      return "http://localhost:$port";
    }
    
    // 2. Para dispositivos móviles - SISTEMA INTELIGENTE COMPLETO
    else {
      // PASO 1: Verificar cache (conexión instantánea)
      if (_isCacheValid()) {
        final cachedUrl = "http://$_cachedSuccessfulIP:$port";
        if (kDebugMode) print('🚀 Probando IP cacheada: $_cachedSuccessfulIP');
        
        final success = await _testConnection(
          "$cachedUrl${ApiConfig.urlRegister}", 
          isRegisterEndpoint: true,
          quickTest: true
        );
        
        if (success) {
          _dynamicIp = _cachedSuccessfulIP;
          if (kDebugMode) print('⚡ ÉXITO con IP cacheada para Register: $_cachedSuccessfulIP');
          return cachedUrl;
        } else {
          if (kDebugMode) print('❌ IP cacheada falló, iniciando nueva detección...');
        }
      }

      // PASO 2: Detección paralela súper rápida
      final detectedIP = await _fastParallelIPDetection(port);
      if (detectedIP != null) {
        _cacheSuccessfulIP(detectedIP);
        _dynamicIp = detectedIP;
        if (kDebugMode) print('🎯 IP detectada por algoritmo paralelo para Register: $detectedIP');
        return "http://$detectedIP:$port";
      }

      // PASO 3: Fallbacks finales si todo falla
      final List<String> fallbackIPs = [
        '192.168.1.8',   // Tu IP específica
        '10.0.2.2',      // Android emulator
        '192.168.1.1',   // Router común
        'localhost',     // Último recurso
      ];

      for (String ip in fallbackIPs) {
        final testUrl = "http://$ip:$port";
        final fullEndpoint = "$testUrl${ApiConfig.urlRegister}";
        if (kDebugMode) print('🔄 Probando fallback IP: $fullEndpoint');
        
        if (await _testConnection(fullEndpoint, isRegisterEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) print('✅ IP fallback exitosa para Register: $ip');
          return testUrl;
        }
      }

      // Último recurso
      if (kDebugMode) print('⚠️ Usando fallback final para Register: 192.168.1.8');
      _dynamicIp = '192.168.1.8';
      return "http://192.168.1.8:$port";
    }
  }

  /// Verifica si el cache de IP es válido
  bool _isCacheValid() {
    if (_cachedSuccessfulIP == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Cachea una IP exitosa para conexiones futuras
  void _cacheSuccessfulIP(String ip) {
    _cachedSuccessfulIP = ip;
    _cacheTimestamp = DateTime.now();
    if (kDebugMode) print('📌 IP cacheada para Register: $ip');
  }

  /// Detección paralela súper rápida de IP del servidor para registro
  Future<String?> _fastParallelIPDetection(int port) async {
    try {
      final List<String> detectedNetworks = await _getDetectedNetworks();
      
      if (kDebugMode) print('🌐 Redes detectadas para Register: $detectedNetworks');
      
      // Lista de redes comunes para probar (incluye tu red específica)
      final List<String> networksToTry = [
        '192.168.1',  // Tu red específica
        '10.8.217',   // Red que detectó tu dispositivo
        '192.168.0',  // Red común de routers
        '10.0.0',     // Red común corporativa
        ...detectedNetworks, // Agregar redes detectadas automáticamente
      ];
      
      // Eliminar duplicados manteniendo orden
      final uniqueNetworks = <String>[];
      for (String network in networksToTry) {
        if (!uniqueNetworks.contains(network)) {
          uniqueNetworks.add(network);
        }
      }
      
      // IPs más probables para cada red (menos IPs para registro, más rápido)
      final List<String> priorityIPs = [];
      for (String network in uniqueNetworks) {
        priorityIPs.addAll([
          '$network.8',   // Tu PC específica (192.168.1.8)
          '$network.1',   // Router más común
          '$network.100', // Rango común para PCs
          '$network.10',  // Servidor común
          '$network.2',   // Router alternativo
        ]);
      }
      
      // Agregar IPs especiales y tu IP específica PRIMERO
      priorityIPs.insertAll(0, [
        '192.168.1.8',     // Tu IP específica (PRIMER intento)
        '10.0.2.2',        // Android emulator
        '127.0.0.1',       // Localhost
      ]);
      
      if (kDebugMode) print('🚀 Probando ${priorityIPs.length} IPs en paralelo para Register...');
      
      // Ejecutar todas las pruebas en paralelo con timeout agresivo
      final List<Future<String?>> futures = priorityIPs.map((ip) async {
        try {
          final testUrl = "http://$ip:$port";
          final fullEndpoint = "$testUrl${ApiConfig.urlRegister}";
          if (kDebugMode && ip == '192.168.1.8') debugPrint('🎯 Probando IP prioritaria: $fullEndpoint');
          
          final success = await _testConnection(
            fullEndpoint,
            isRegisterEndpoint: true,
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
          if (kDebugMode) print('⚡ IP encontrada súper rápido para Register: $result');
          return result;
        }
      }
      
      if (kDebugMode) print('❌ No se encontró IP en detección rápida para Register');
      return null;
      
    } catch (e) {
      if (kDebugMode) print('Error en detección paralela para Register: $e');
      return null;
    }
  }

  /// Detecta automáticamente todas las redes del dispositivo
  Future<List<String>> _getDetectedNetworks() async {
    final networks = <String>[];
    try {
      if (kIsWeb) return networks;

      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
              final parts = ip.split('.');
              if (parts.length >= 3) {
                final network = '${parts[0]}.${parts[1]}.${parts[2]}';
                if (!networks.contains(network)) {
                  networks.add(network);
                  if (kDebugMode) print('🔍 Red detectada automáticamente para Register: $network');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error detectando redes para Register: $e');
    }
    return networks;
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
    bool quickTest = false,
  }) async {
    try {
      final testDio = Dio(
        BaseOptions(
          // Timeouts súper agresivos para quickTest (detección paralela)
          connectTimeout: quickTest 
            ? const Duration(milliseconds: 800)
            : const Duration(seconds: 5),
          receiveTimeout: quickTest 
            ? const Duration(milliseconds: 800)
            : const Duration(seconds: 5),
          sendTimeout: quickTest 
            ? const Duration(milliseconds: 800)
            : const Duration(seconds: 5),
        ),
      );

      // Para endpoints de registro, probamos diferentes estrategias
      if (isRegisterEndpoint) {
        if (kDebugMode) print('🧪 Probando endpoint de registro: $url');
        
        // Primero intentamos el endpoint de registro completo con POST
        try {
          final response = await testDio.post(url, data: {
            'test': true, // Data mínima para probar endpoint
            'username': 'test_user',
            'email': 'test@example.com',
            'password': 'test123'
          });
          if (kDebugMode) print('✅ Registro endpoint respondió: ${response.statusCode}');
          return response.statusCode != null;
        } catch (e) {
          if (e is DioException && e.response != null) {
            if (kDebugMode) print('✅ Servidor responde con error (válido): ${e.response?.statusCode}');
            return true; // Servidor responde, aunque sea con error de validación
          }
          if (kDebugMode) print('❌ Error de conexión: $e');
        }
        
        // Si falla POST, intentamos GET al endpoint base para verificar que el servidor esté vivo
        try {
          final baseUrl = url.replaceAll(ApiConfig.urlRegister, '/api_v1');
          if (kDebugMode) print('🔍 Probando base API: $baseUrl');
          final response = await testDio.get(baseUrl);
          return response.statusCode == 200 || response.statusCode == 404;
        } catch (e) {
          if (kDebugMode) print('❌ Base API no responde: $e');
        }
      }

      // Para otros endpoints, GET simple
      final response = await testDio.get(url);
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return true; // Servidor responde, aunque sea con error
      }
      return false;
    }
  }

  /// Registro de usuario con manejo de IP dinámica inteligente
  Future<ApiUser> registerUser(
    String username,
    String password,
    String email,
  ) async {
    if (kDebugMode) {
      print('🚀 RegisterService: Iniciando registro de usuario...');
      print('📧 Email: $email');
      print('👤 Username: $username');
    }

    // Asegurar que el servicio esté inicializado con detección inteligente
    if (!_isInitialized || _dio == null) {
      if (kDebugMode) print('🔄 Inicializando RegisterService...');
      await initialize();
    }

    if (kDebugMode) {
      if (kDebugMode) {
        print('🌐 IP detectada para Register: $_dynamicIp');
        print('🔗 Base URL: ${_dio?.options.baseUrl}');
      }
    }

    try {
      if (kDebugMode) print('📡 Enviando POST a: ${ApiConfig.urlRegister}');
      
      final response = await _dio!.post(
        ApiConfig.urlRegister,  // POST a /api_v1/users (endpoint correcto)
        data: {
          "User_name": username,
          "User_mail": email,
          "User_password": password,
          // Solo campos esenciales, como en AuthService
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
