import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/products_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import 'cache_service.dart';

class ProductService {
  late Dio _dio;
  final CacheService _cacheService = CacheService();
  
  static const String _productsCacheKey = 'products_all';
  static const String _productCachePrefix = 'product_';

  ProductService() {
    _dio = HttpService().dio;
  }

  /// Obtener todos los productos con caché inteligente
  Future<List<Product>> getProducts() async {
    try {
      // 1. Intentar obtener del caché primero
      final cachedProducts = _cacheService.getCache<List<dynamic>>(_productsCacheKey);
      if (cachedProducts != null) {
        if (kDebugMode) debugPrint('⚡ Productos desde caché');
        return cachedProducts
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 2. Si no está en caché, obtener del servidor
      if (kDebugMode) debugPrint('📡 Obteniendo productos del servidor...');
      final response = await _dio.get(ApiConfig.urlProducts);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data : response.data['data'] ?? [];
        
        // 3. Guardar en caché
        await _cacheService.setCache(
          _productsCacheKey,
          data,
          cacheDuration: CacheService.productCacheDuration,
        );

        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }

      throw Exception('❌ Respuesta inválida del servidor');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo productos: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Obtener productos con paginación (lazy loading)
  Future<List<Product>> getProductsPaginated({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final cacheKey = 'products_page_${page}_size_$pageSize';

      // 1. Intentar obtener del caché primero
      final cached = _cacheService.getCache<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Página $page desde caché');
        return cached
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 2. Obtener del servidor con parámetros de paginación
      if (kDebugMode) debugPrint('📡 Obteniendo página $page (offset: $offset, limit: $pageSize)');
      final response = await _dio.get(
        ApiConfig.urlProducts,
        queryParameters: {
          'offset': offset,
          'limit': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data : response.data['data'] ?? [];
        
        // 3. Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          data,
          cacheDuration: CacheService.productCacheDuration,
        );

        if (kDebugMode) debugPrint('✅ ${data.length} productos en página $page');
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }

      throw Exception('❌ Respuesta inválida del servidor');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo página $page: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Obtener producto por ID con caché
  Future<Product> getProductById(int id) async {
    try {
      final cacheKey = '$_productCachePrefix$id';
      
      // Intentar caché
      final cached = _cacheService.getCache<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Producto $id desde caché');
        return Product.fromJson(cached);
      }

      // Obtener del servidor
      if (kDebugMode) debugPrint('📡 Obteniendo producto $id del servidor');
      final response = await _dio.get('${ApiConfig.urlProducts}/$id');

      if (response.statusCode == 200 && response.data != null) {
        final product = Product.fromJson(response.data as Map<String, dynamic>);
        
        // Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          response.data,
          cacheDuration: CacheService.productCacheDuration,
        );

        return product;
      }

      throw Exception('❌ Producto no encontrado');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo producto: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Crear nuevo producto
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      if (kDebugMode) debugPrint('📝 Creando nuevo producto...');
      final response = await _dio.post(
        ApiConfig.urlProducts,
        data: productData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final product = Product.fromJson(response.data as Map<String, dynamic>);
        
        // Invalidar caché de lista
        await _cacheService.removeCache(_productsCacheKey);
        
        return product;
      }

      throw Exception('❌ No se pudo crear el producto');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error creando producto: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Actualizar producto
  Future<Product> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      if (kDebugMode) debugPrint('✏️ Actualizando producto $id...');
      final response = await _dio.put(
        '${ApiConfig.urlProducts}/$id',
        data: productData,
      );

      if (response.statusCode == 200) {
        final product = Product.fromJson(response.data as Map<String, dynamic>);
        
        // Invalidar caché del producto y la lista
        await Future.wait([
          _cacheService.removeCache('$_productCachePrefix$id'),
          _cacheService.removeCache(_productsCacheKey),
        ]);
        
        return product;
      }

      throw Exception('❌ No se pudo actualizar el producto');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error actualizando producto: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(int id) async {
    try {
      if (kDebugMode) debugPrint('🗑️ Eliminando producto $id...');
      final response = await _dio.delete('${ApiConfig.urlProducts}/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalidar caché
        await Future.wait([
          _cacheService.removeCache('$_productCachePrefix$id'),
          _cacheService.removeCache(_productsCacheKey),
        ]);
      } else {
        throw Exception('❌ No se pudo eliminar el producto');
      }
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error eliminando producto: ${_handleDioError(e)}');
      rethrow;
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

  /// Limpiar caché de productos
  Future<void> clearProductsCache() async {
    await Future.wait([
      _cacheService.removeCache(_productsCacheKey),
      _cacheService.clearCachePattern('$_productCachePrefix.*'),
      _cacheService.clearCachePattern('products_page_.*'),
      _cacheService.clearCachePattern('products_search_.*'),
    ]);
    if (kDebugMode) debugPrint('🧹 Caché de productos limpiado');
  }

  /// Buscar productos por nombre con caché
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) {
        return getProducts();
      }

      final cacheKey = 'products_search_${query.toLowerCase()}';
      
      // Intentar caché
      final cached = _cacheService.getCache<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Búsqueda "$query" desde caché');
        return cached
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Buscar del servidor
      if (kDebugMode) debugPrint('📡 Buscando productos con: "$query"');
      final response = await _dio.get(
        ApiConfig.urlProducts,
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data : response.data['data'] ?? [];
        
        // Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          data,
          cacheDuration: CacheService.productCacheDuration,
        );

        if (kDebugMode) debugPrint('✅ ${data.length} resultados encontrados');
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error buscando productos: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Obtener productos por categoría con caché
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final cacheKey = 'products_category_${category.toLowerCase()}';
      
      // Intentar caché
      final cached = _cacheService.getCache<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Categoría "$category" desde caché');
        return cached
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Obtener del servidor
      if (kDebugMode) debugPrint('📡 Obteniendo productos de categoría: "$category"');
      final response = await _dio.get(
        ApiConfig.urlProducts,
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data : response.data['data'] ?? [];
        
        // Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          data,
          cacheDuration: CacheService.productCacheDuration,
        );

        if (kDebugMode) debugPrint('✅ ${data.length} productos en categoría "$category"');
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo categoría: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Obtener productos por marca con caché
  Future<List<Product>> getProductsByBrand(String brand) async {
    try {
      final cacheKey = 'products_brand_${brand.toLowerCase()}';
      
      // Intentar caché
      final cached = _cacheService.getCache<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Marca "$brand" desde caché');
        return cached
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Obtener del servidor
      if (kDebugMode) debugPrint('📡 Obteniendo productos de marca: "$brand"');
      final response = await _dio.get(
        ApiConfig.urlProducts,
        queryParameters: {'brand': brand},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data =
            response.data is List ? response.data : response.data['data'] ?? [];
        
        // Guardar en caché
        await _cacheService.setCache(
          cacheKey,
          data,
          cacheDuration: CacheService.productCacheDuration,
        );

        if (kDebugMode) debugPrint('✅ ${data.length} productos de marca "$brand"');
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('❌ Error obteniendo marca: ${_handleDioError(e)}');
      rethrow;
    }
  }

  /// Verificar conectividad del servidor
  Future<bool> checkServerConnection() async {
    try {
      if (kDebugMode) debugPrint('🔌 Verificando conectividad del servidor...');
      final response = await _dio.get(
        ApiConfig.urlProducts,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Obtener tamaño del caché de productos en KB
  int getProductsCacheSize() {
    return _cacheService.getCacheSize();
  }
}
