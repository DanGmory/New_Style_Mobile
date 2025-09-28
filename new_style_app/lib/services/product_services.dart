import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/products_model.dart';

class ProductService {
  Dio? _dio;
  String? _dynamicIp;
  bool _isInitialized = false;

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
        final testUrl = "http://$ip:$port/api_v1/products";
        if (await _testConnection(testUrl)) {
          _dynamicIp = ip;
          if (kDebugMode) {
            print('IP dinámica detectada para Products: $ip');
          }
          return testUrl;
        }
      }

      _dynamicIp = 'localhost';
      return "http://localhost:$port/api_v1/products";
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
              final testUrl = "http://$ip:$port/api_v1/products";
              if (await _testConnection(testUrl)) {
                _dynamicIp = ip;
                if (kDebugMode) {
                  print('IP dinámica detectada para Products: $ip');
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
      return "http://10.0.2.2:$port/api_v1/products";
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
  Future<bool> _testConnection(String url) async {
    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final response = await testDio.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Listar todos los productos con mejor manejo de errores
  Future<List<Product>> getProducts() async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.get('');

      // Validar que la respuesta no esté vacía
      if (response.data == null) {
        throw Exception("La respuesta del servidor está vacía");
      }

      // Debug: Imprimir respuesta
      if (kDebugMode) {
        print('Respuesta del servidor: ${response.data}');
        print('Tipo de respuesta: ${response.data.runtimeType}');
      }

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['data'] ?? response.data['products'] ?? [];

      // Debug: Imprimir productos
      if (kDebugMode) {
        for (int i = 0; i < data.length && i < 2; i++) {
          print('Producto $i: ${data[i]}');
        }
      }

      return data.map((json) {
        try {
          return Product.fromJson(json);
        } catch (e) {
          if (kDebugMode) {
            print('Error al parsear producto: $json');
            print('Error: $e');
          }
          rethrow;
        }
      }).toList();
    } on DioException catch (e) {
      // Si es un error de conexión, intentamos con IPs alternativas
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        if (kDebugMode) {
          print('Error de conexión, intentando con IPs alternativas...');
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

  /// Intentar obtener productos con IPs alternativas
  Future<List<Product>> _getProductsWithAlternativeIPs() async {
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
              "User-Agent": "Flutter-App/1.0",
            },
          ),
        );

        if (kDebugMode) {
          print('Intentando conectar con: $baseUrl');
        }

        final response = await alternativeDio.get('');

        if (response.statusCode == 200 && response.data != null) {
          if (kDebugMode) {
            print('Conexión exitosa con: $baseUrl');
          }

          // Actualizar la instancia principal con la URL que funcionó
          _dio?.options.baseUrl = baseUrl;

          final List<dynamic> data = response.data is List
              ? response.data
              : response.data['data'] ?? response.data['products'] ?? [];

          return data.map((json) => Product.fromJson(json)).toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error con $baseUrl: $e');
        }
        continue;
      }
    }

    throw Exception("No se pudo conectar con ninguna URL del servidor");
  }

  /// Obtener todas las URLs posibles para products
  Future<List<String>> _getAllPossibleUrls() async {
    const int port = 3000;
    final List<String> urls = [];

    // URLs básicas
    urls.addAll([
      "http://localhost:$port/api_v1/products",
      "http://127.0.0.1:$port/api_v1/products",
      "http://192.168.1.10:$port/api_v1/products", // IP del ejemplo
      "http://192.168.1.2:$port/api_v1/products",
    ]);

    // Agregar IP detectada dinámicamente
    if (_dynamicIp != null) {
      urls.add("http://$_dynamicIp:$port/api_v1/products");
    }

    // Para móviles
    if (!kIsWeb) {
      urls.add("http://10.0.2.2:$port/api_v1/products");

      try {
        final String? localIP = await _getLocalIP();
        if (localIP != null) {
          final parts = localIP.split('.');
          if (parts.length >= 3) {
            final networkBase = '${parts[0]}.${parts[1]}.${parts[2]}';
            // IPs más comunes
            final commonIPs = [1, 2, 10, 100, 101, 102, 200, 254];
            for (int ip in commonIPs) {
              urls.add("http://$networkBase.$ip:$port/api_v1/products");
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error generando IPs de red: $e');
      }
    }

    return urls;
  }

  /// Obtener producto por ID
  Future<Product> getProductById(int id) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.get('/$id');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Crear producto
  Future<Product> createProduct(Product product) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.post(
        '',
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
      return Product.fromJson(response.data['data'][0]);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(int id, Product product) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      await _dio!.put(
        '/$id',
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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(int id) async {
    if (!_isInitialized || _dio == null) {
      await initialize();
    }

    try {
      await _dio!.delete('/$id');
    } on DioException catch (e) {
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
