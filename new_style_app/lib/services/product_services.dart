import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/products_model.dart';

class ProductService {
  late final Dio _dio;

  ProductService() {
    const String localIp = "192.168.1.2";
    const int port = 3000;

    final String baseUrl = kIsWeb
        ? "http://$localIp:3000/api_v1/products"
        : "http://10.0.2.2:3000/api_v1/products"; 

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      // ✅ Timeouts aumentados significativamente
      connectTimeout: const Duration(minutes: 2), // 120 segundos
      receiveTimeout: const Duration(minutes: 2), // 120 segundos
      sendTimeout: const Duration(minutes: 2),    // 120 segundos
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      // ✅ Configuraciones adicionales de red
      followRedirects: true,
      maxRedirects: 5,
    ));

    // ✅ Interceptor para debugging y manejo de errores
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      error: kDebugMode,
      logPrint: (obj) {
        if (kDebugMode) print(obj);
      },
    ));

    // ✅ Interceptor personalizado para manejo de errores
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          print('🚨 Error en petición: ${error.message}');
          print('🚨 Tipo de error: ${error.type}');
        }
        handler.next(error);
      },
    ));
  }

  /// ✅ Listar todos los productos con mejor manejo de errores
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('');
      
      // ✅ Validar que la respuesta no esté vacía
      if (response.data == null) {
        throw Exception("La respuesta del servidor está vacía");
      }
      
      final List<dynamic> data = response.data is List 
          ? response.data 
          : response.data['data'] ?? response.data['products'] ?? [];
      
      return data.map((json) => Product.fromJson(json)).toList();
      
    } on DioException catch (e) {
      // ✅ Manejo específico según el tipo de error
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Error inesperado: $e");
    }
  }

  /// ✅ Método con retry automático
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
          print('🔄 Reintentando... Intento $attempts de $maxRetries');
        }
      }
    }
    
    throw Exception('No se pudo conectar después de $maxRetries intentos');
  }

  /// 🔹 Obtener producto por ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/$id');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// 🔹 Crear producto
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _dio.post(
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

  /// 🔹 Actualizar producto
  Future<void> updateProduct(int id, Product product) async {
    try {
      await _dio.put(
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

  /// 🔹 Eliminar producto
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// ✅ Método privado para manejar errores de Dio de forma específica
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

  /// ✅ Método para verificar conectividad con múltiples URLs
  Future<bool> checkServerConnection() async {
    final List<String> testUrls = [
      "http://192.168.1.7:3000",
      "http://10.0.2.2:3000", 
      "http://localhost:3000"
    ];
    
    for (String testUrl in testUrls) {
      try {
        final testDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        final response = await testDio.get('$testUrl/api_v1/products');
        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('✅ Conexión exitosa con: $testUrl');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Falló conexión con: $testUrl - $e');
        }
        continue;
      }
    }
    return false;
  }

  /// ✅ Método alternativo usando diferentes configuraciones de red
  Future<List<Product>> getProductsAlternative() async {
    final List<String> baseUrls = [
      "http://192.168.1.2:3000/api_v1/products",
      "http://10.0.2.2:3000/api_v1/products",
      "http://localhost:3000/api_v1/products"
    ];

    for (String url in baseUrls) {
      try {
        final alternativeDio = Dio(BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "Flutter-App/1.0",
          },
        ));

        if (kDebugMode) {
          print('🔄 Intentando conectar con: $url');
        }

        final response = await alternativeDio.get('');
        
        if (response.statusCode == 200 && response.data != null) {
          if (kDebugMode) {
            print('✅ Conexión exitosa con: $url');
          }
          
          final List<dynamic> data = response.data is List 
              ? response.data 
              : response.data['data'] ?? response.data['products'] ?? [];
          
          return data.map((json) => Product.fromJson(json)).toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error con $url: $e');
        }
        continue;
      }
    }
    
    throw Exception("No se pudo conectar con ninguna URL del servidor");
  }
}