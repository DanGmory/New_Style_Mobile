import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/products_model.dart';
import '../config/api_config.dart';

class ProductService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;
  
  // Cache para conexiones rápidas
  static String? _cachedSuccessfulIP;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  ProductService();

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
            print('Error en petición: ${error.message}');
            print('Tipo de error: ${error.type}');
            print('IP actual: $_dynamicIp');
          }
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  /// Obtener la URL base con IP dinámica inteligente
  Future<String> _getBaseUrl() async {
    const int port = 3000;

    // Para Flutter Web
    if (kIsWeb) {
      final List<String> commonIPs = [
        'localhost',
        '127.0.0.1',
        '192.168.1.8',  // Tu IP específica detectada
        '192.168.1.1',
        await _getHostIP() ?? 'localhost',
      ];

      for (String ip in commonIPs) {
        final testUrl = "http://$ip:$port";
        if (await _testConnection("$testUrl${ApiConfig.urlProducts}", isProductEndpoint: true)) {
          _dynamicIp = ip;
          if (kDebugMode) {
            print('✅ IP dinámica detectada para Products: $ip');
          }
          return testUrl;
        }
      }

      _dynamicIp = 'localhost';
      return "http://localhost:$port";
    }
    // Para dispositivos móviles - Sistema inteligente
    else {
      // 1. Intentar IP cacheada primero (súper rápido)
      if (_isCacheValid()) {
        final cachedUrl = "http://$_cachedSuccessfulIP:$port";
        if (await _testConnection(
          "$cachedUrl${ApiConfig.urlProducts}", 
          isProductEndpoint: true,
          quickTest: true
        )) {
          _dynamicIp = _cachedSuccessfulIP;
          if (kDebugMode) print('⚡ Conectado con IP cacheada: $_cachedSuccessfulIP');
          return cachedUrl;
        }
      }
      
      // 2. Intentar detección inteligente primero (más rápido)
      final String? smartIP = await _detectMostLikelyServerIP();
      if (smartIP != null) {
        _dynamicIp = smartIP;
        _cacheSuccessfulIP(smartIP);
        if (kDebugMode) print('🧠 IP detectada inteligentemente: $smartIP');
        return "http://$smartIP:$port";
      }
      
      // 3. Si falla la detección inteligente, usar detección paralela completa
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

  /// Verifica si el cache de IP es válido
  bool _isCacheValid() {
    if (_cachedSuccessfulIP == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Cachea una IP exitosa para conexiones futuras
  void _cacheSuccessfulIP(String ip) {
    _cachedSuccessfulIP = ip;
    _cacheTimestamp = DateTime.now();
    if (kDebugMode) print('📌 IP cacheada para Products: $ip');
  }

  /// Detección paralela súper rápida de IP del servidor para productos
  Future<String?> _fastParallelIPDetection(int port) async {
    try {
      final List<String> detectedNetworks = await _getDetectedNetworks();
      
      if (kDebugMode) print('🌐 Redes detectadas: $detectedNetworks');
      
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
      
      // IPs más probables para cada red (optimizado y reducido)
      final List<String> priorityIPs = [
        '192.168.1.8',     // Tu IP específica (PRIMER intento - más probable)
        '10.0.2.2',        // Android emulator
        '127.0.0.1',       // Localhost
      ];
      
      // Para cada red detectada, agregar solo las IPs más probables
      for (String network in uniqueNetworks) {
        priorityIPs.addAll([
          '$network.8',   // Tu PC específica
          '$network.1',   // Router más común
          '$network.100', // Rango común para PCs
          '$network.2',   // Router alternativo
          '$network.10',  // Servidor común
        ]);
      }
      
      // Agregar algunas IPs adicionales solo para las redes más comunes
      if (uniqueNetworks.contains('192.168.1')) {
        priorityIPs.addAll(['192.168.1.101', '192.168.1.102', '192.168.1.50']);
      }
      
      if (kDebugMode) print('🚀 Probando ${priorityIPs.length} IPs en paralelo...');
      
      // Ejecutar todas las pruebas en paralelo con timeout agresivo y manejo silencioso de errores
      final List<Future<String?>> futures = priorityIPs.map((ip) async {
        try {
          final testUrl = "http://$ip:$port";
          final success = await _testConnection(
            "$testUrl${ApiConfig.urlProducts}",
            isProductEndpoint: true,
            quickTest: true
          );
          return success ? ip : null;
        } catch (e) {
          // Silenciar errores comunes de red durante detección paralela
          if (kDebugMode && !_isCommonNetworkError(e)) {
            debugPrint('🔍 Resultado de $ip: ${e.toString().split('\n')[0]}');
          }
          return null;
        }
      }).toList();
      
      // Esperar solo por la primera conexión exitosa
      final results = await Future.wait(futures);
      
      for (String? result in results) {
        if (result != null) {
          if (kDebugMode) print('⚡ IP encontrada súper rápido para Products: $result');
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
                  if (kDebugMode) print('🔍 Red detectada automáticamente: $network');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error detectando redes: $e');
    }
    return networks;
  }

  /// Verifica si es un error común de red que puede ser silenciado
  bool _isCommonNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('no route to host') ||
           errorString.contains('connection refused') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection timeout') ||
           errorString.contains('host is down');
  }

  /// Intenta detectar la IP más probable del servidor basándose en la información de red
  Future<String?> _detectMostLikelyServerIP() async {
    try {
      // Primero, intentar con IPs conocidas exitosas del cache de AuthService
      final knownGoodIPs = ['192.168.1.8']; // IPs que sabemos que funcionan
      
      for (String ip in knownGoodIPs) {
        final testUrl = "http://$ip:3000";
        if (await _testConnection("$testUrl${ApiConfig.urlProducts}", quickTest: true)) {
          if (kDebugMode) print('⚡ IP conocida funciona: $ip');
          return ip;
        }
      }

      // Si no funciona ninguna IP conocida, buscar en la red local del dispositivo
      final deviceIP = await _getDeviceIP();
      if (deviceIP != null) {
        final parts = deviceIP.split('.');
        if (parts.length >= 3) {
          final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
          
          // Probar IPs más probables primero
          final highPriorityIPs = [
            '$networkBase.8',   // IP específica conocida
            '$networkBase.1',   // Router
            '$networkBase.100', // Servidor común
          ];
          
          for (String ip in highPriorityIPs) {
            final testUrl = "http://$ip:3000";
            if (await _testConnection("$testUrl${ApiConfig.urlProducts}", quickTest: true)) {
              if (kDebugMode) print('🎯 IP encontrada en red local: $ip');
              return ip;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error en detección inteligente: $e');
      return null;
    }
  }

  /// Obtiene la IP del dispositivo actual
  Future<String?> _getDeviceIP() async {
    try {
      if (kIsWeb) return null;

      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        // Priorizar interfaces WiFi
        if (interface.name.toLowerCase().contains('wlan') || 
            interface.name.toLowerCase().contains('wifi')) {
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
      }
      
      // Si no hay WiFi, usar cualquier interfaz válida
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
      if (kDebugMode) print('Error obteniendo IP del dispositivo: $e');
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
    bool isProductEndpoint = false,
    bool quickTest = false,
  }) async {
    try {
      // Timeouts aún más agresivos para detección rápida
      final timeoutDuration = quickTest 
        ? const Duration(milliseconds: 800)   // 0.8 segundos para modo súper rápido
        : const Duration(seconds: 3);         // 3 segundos para modo normal
        
      final testDio = Dio(
        BaseOptions(
          connectTimeout: timeoutDuration,
          receiveTimeout: timeoutDuration,
          sendTimeout: timeoutDuration,
        ),
      );

      // Para endpoints de productos, hacemos un HEAD request más eficiente
      Response response;
      try {
        // HEAD es más rápido que GET para solo verificar disponibilidad
        response = await testDio.head(url.replaceAll(ApiConfig.urlProducts, '/api_v1'));
      } catch (e) {
        // Si HEAD no funciona, intentar GET como fallback
        response = await testDio.get(url.replaceAll(ApiConfig.urlProducts, '/api_v1'));
      }
      
      return response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 405; // 405 Method Not Allowed también indica servidor activo
    } catch (e) {
      // Para detección rápida, no hacer reintentos para reducir tiempo
      if (quickTest) {
        return false;
      }
      
      // Solo para modo normal, intentar con el endpoint directo
      try {
        final baseUrl = url.replaceAll(ApiConfig.urlProducts, '/api_v1');
        final Dio testDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        );
        final response = await testDio.get(baseUrl);
        return response.statusCode == 200;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Listar todos los productos con mejor manejo de errores
  Future<List<Product>> getProducts() async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) print('🚀 Iniciando carga de productos súper rápida...');
    
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      if (kDebugMode) print('⚙️ Inicializando servicio de productos...');
      await initialize();
      if (kDebugMode) print('✅ Servicio de productos inicializado en ${stopwatch.elapsedMilliseconds}ms');
    }

    try {
      final response = await _dio!.get(ApiConfig.urlProducts);

      // Validar que la respuesta no esté vacía
      if (response.data == null) {
        throw Exception("La respuesta del servidor está vacía");
      }

      // Debug: Imprimir respuesta
      if (kDebugMode) {
        print('📦 Respuesta del servidor de productos: ${response.data.runtimeType}');
        print('⏱️ Tiempo de respuesta: ${stopwatch.elapsedMilliseconds}ms');
      }

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['data'] ?? response.data['products'] ?? [];

      // Debug: Imprimir productos
      if (kDebugMode) {
        print('🎯 Se obtuvieron ${data.length} productos');
        for (int i = 0; i < data.length && i < 2; i++) {
          print('Producto $i: ${data[i]['Product_name'] ?? 'Sin nombre'}');
        }
      }

      final products = data.map((json) {
        try {
          return Product.fromJson(json);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error al parsear producto: $json');
            print('Error: $e');
          }
          rethrow;
        }
      }).toList();

      if (kDebugMode) print('✅ Productos cargados exitosamente en ${stopwatch.elapsedMilliseconds}ms');
      return products;

    } on DioException catch (e) {
      // Si es un error de conexión, intentamos con IPs alternativas
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        if (kDebugMode) {
          print('🔄 Error de conexión, intentando con IPs alternativas...');
        }

        return await _getProductsWithAlternativeIPs();
      }

      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }

  /// Método con retry automático
  Future<List<Product>> getProductsWithRetry({int maxRetries = 3}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        return await getProducts();
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }

        // Espera progresiva antes del siguiente intento
        await Future.delayed(Duration(seconds: attempts * 2));
        if (kDebugMode) {
          print('Reintentando... Intento $attempts de $maxRetries');
        }
      }
    }

    throw Exception('No se pudo conectar después de $maxRetries intentos');
  }

  /// Intentar obtener productos con IPs alternativas usando detección inteligente
  Future<List<Product>> _getProductsWithAlternativeIPs() async {
    try {
      if (kDebugMode) print('🔍 Iniciando búsqueda con IPs alternativas...');
      
      // Usar detección paralela para encontrar IPs que funcionan
      const port = 3000;
      final String? workingIP = await _fastParallelIPDetection(port);
      
      if (workingIP != null) {
        final workingUrl = "http://$workingIP:$port";
        
        final alternativeDio = Dio(
          BaseOptions(
            baseUrl: workingUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "User-Agent": "Flutter-App/1.0",
            },
          ),
        );

        if (kDebugMode) {
          print('✅ Conectando con IP encontrada: $workingUrl');
        }

        final response = await alternativeDio.get(ApiConfig.urlProducts);

        if (response.statusCode == 200 && response.data != null) {
          if (kDebugMode) {
            print('🎯 Conexión exitosa, actualizando configuración...');
          }

          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = workingUrl;
          _dynamicIp = workingIP;
          _cacheSuccessfulIP(workingIP); // Cachear para próximas conexiones

          final List<dynamic> data = response.data is List
              ? response.data
              : response.data['data'] ?? response.data['products'] ?? [];

          final products = data.map((json) => Product.fromJson(json)).toList();
          if (kDebugMode) print('📦 ${products.length} productos obtenidos con IP alternativa');
          return products;
        }
      }
      
      // Si falla la detección paralela, intentar con URLs predefinidas como fallback
      final List<String> fallbackUrls = ApiConfig.getAllPossibleUrls(ApiConfig.urlProducts, detectedIP: _dynamicIp);
      
      for (String fullUrl in fallbackUrls) {
        try {
          final uri = Uri.parse(fullUrl);
          final baseUrl = "${uri.scheme}://${uri.host}:${uri.port}";
          
          final fallbackDio = Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
              },
            ),
          );

          if (kDebugMode) {
            print('🔄 Probando URL fallback: $fullUrl');
          }

          final response = await fallbackDio.get(ApiConfig.urlProducts);

          if (response.statusCode == 200 && response.data != null) {
            if (kDebugMode) {
              print('✅ Conexión fallback exitosa: $baseUrl');
            }

            // Actualizar configuración
            _dio?.options.baseUrl = baseUrl;
            final parts = uri.host.split('.');
            if (parts.length >= 4) {
              _dynamicIp = uri.host;
              _cacheSuccessfulIP(uri.host);
            }

            final List<dynamic> data = response.data is List
                ? response.data
                : response.data['data'] ?? response.data['products'] ?? [];

            return data.map((json) => Product.fromJson(json)).toList();
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error con URL fallback $fullUrl: $e');
          }
          continue;
        }
      }

    } catch (e) {
      if (kDebugMode) print('❌ Error en búsqueda alternativa: $e');
    }

    throw Exception("❌ No se pudo conectar con ninguna IP del servidor de productos");
  }

  /// Obtener todas las URLs posibles para products usando configuración centralizada
  Future<List<String>> _getAllPossibleUrls() async {
    return ApiConfig.getAllPossibleUrls(ApiConfig.urlProducts, detectedIP: _dynamicIp);
  }

  /// Obtener producto por ID
  Future<Product> getProductById(int id) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      if (kDebugMode) print('📋 Obteniendo producto ID: $id');
      final response = await _dio!.get('${ApiConfig.urlProducts}/$id');
      
      if (kDebugMode) print('✅ Producto obtenido: ${response.data['Product_name'] ?? 'Sin nombre'}');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Error obteniendo producto $id: ${_handleDioError(e)}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Crear producto
  Future<Product> createProduct(Product product) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      if (kDebugMode) print('➕ Creando producto: ${product.name}');
      final response = await _dio!.post(
        ApiConfig.urlProducts,
        data: {
          "Name": product.name,
          "Amount": product.amount,
          "category": product.category,
          "description": product.description,
          "price": product.price,
          "Image_fk": product.imageUrl,
          "Brand_fk": product.brand,
          "Color_fk": product.color,
          "Size_fk": product.size,
          "Type_product_fk": product.typeProduct,
        },
      );
      
      final createdProduct = Product.fromJson(response.data['data'][0]);
      if (kDebugMode) print('✅ Producto creado exitosamente: ${createdProduct.name}');
      return createdProduct;
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Error creando producto: ${_handleDioError(e)}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(int id, Product product) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      if (kDebugMode) print('✏️ Actualizando producto ID $id: ${product.name}');
      await _dio!.put(
        '${ApiConfig.urlProducts}/$id',
        data: {
          "Name": product.name,
          "Amount": product.amount,
          "category": product.category,
          "description": product.description,
          "price": product.price,
          "Image_fk": product.imageUrl,
          "Brand_fk": product.brand,
          "Color_fk": product.color,
          "Size_fk": product.size,
          "Type_product_fk": product.typeProduct,
        },
      );
      if (kDebugMode) print('✅ Producto $id actualizado exitosamente');
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Error actualizando producto $id: ${_handleDioError(e)}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(int id) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      if (kDebugMode) print('🗑️ Eliminando producto ID: $id');
      await _dio!.delete('${ApiConfig.urlProducts}/$id');
      if (kDebugMode) print('✅ Producto $id eliminado exitosamente');
    } on DioException catch (e) {
      if (kDebugMode) print('❌ Error eliminando producto $id: ${_handleDioError(e)}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Método para verificar conectividad del servidor
  Future<bool> checkServerConnection() async {
    final List<String> testUrls = await _getAllPossibleUrls();

    for (String testUrl in testUrls) {
      if (await _testConnection(testUrl)) {
        if (kDebugMode) {
          print('Servidor de productos encontrado en: $testUrl');
        }
        return true;
      }
    }
    return false;
  }

  /// Método privado para manejar errores de Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Timeout de conexión: El servidor tardó demasiado en responder. Verifica tu conexión a internet.";

      case DioExceptionType.receiveTimeout:
        return "Timeout de recepción: El servidor no envió respuesta a tiempo.";

      case DioExceptionType.sendTimeout:
        return "Timeout de envío: No se pudo enviar la petición a tiempo.";

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return "Error del servidor ($statusCode): ${e.response?.statusMessage ?? 'Error desconocido'}";

      case DioExceptionType.connectionError:
        return "Error de conexión: No se pudo conectar al servidor. Verifica que el servidor esté ejecutándose.";

      case DioExceptionType.cancel:
        return "Petición cancelada";

      default:
        return "Error de red: ${e.message ?? 'Error desconocido'}";
    }
  }

  /// Obtener la IP actual en uso
  String? getCurrentIP() {
    return _dynamicIp;
  }

  /// Forzar reconexión con nueva detección de IP
  Future<void> reconnect() async {
    _dynamicIp = null;
    _isInitialized = false;
    _dio = null;
    await initialize();
  }

  /// Método alternativo (alias para compatibilidad)
  Future<List<Product>> getProductsAlternative() async {
    return await _getProductsWithAlternativeIPs();
  }
}
