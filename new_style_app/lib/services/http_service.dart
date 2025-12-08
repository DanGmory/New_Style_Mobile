import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Servicio HTTP centralizado con optimizaciones de rendimiento
class HttpService {
  static final HttpService _instance = HttpService._internal();
  late Dio _dio;
  
  factory HttpService() {
    return _instance;
  }
  
  HttpService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.host,
        // Timeouts optimizados: reducir a 15s para respuestas rápidas
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          // Note: Accept-Encoding se maneja automáticamente en navegadores y causaría CORS en web
          // "Accept-Encoding": "gzip, deflate",
        },
        // Reutilizar conexiones
        persistentConnection: true,
        followRedirects: true,
        maxRedirects: 3,
      ),
    );

    // Interceptor para compresión y optimizaciones
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Añadir timestamp para debugging
          options.extra['startTime'] = DateTime.now();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Medir tiempo de respuesta
          final startTime = response.requestOptions.extra['startTime'] as DateTime?;
          if (startTime != null && kDebugMode) {
            final duration = DateTime.now().difference(startTime);
            debugPrint('✅ ${response.requestOptions.path} - ${duration.inMilliseconds}ms');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final startTime = error.requestOptions.extra['startTime'] as DateTime?;
            if (startTime != null) {
              final duration = DateTime.now().difference(startTime);
              debugPrint('❌ ${error.requestOptions.path} - ${duration.inMilliseconds}ms - ${error.message}');
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Log interceptor solo en debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // No loguear body completo para ahorrar I/O
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Actualizar base URL dinámicamente
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    if (kDebugMode) {
      debugPrint('🔄 Base URL actualizada: $newBaseUrl');
    }
  }

  /// Resetear el servicio (útil para logout/cambio de cuenta)
  void reset() {
    _initializeDio();
  }
}
