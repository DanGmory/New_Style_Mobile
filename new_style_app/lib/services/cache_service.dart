import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio de caché centralizado para optimizar tiempos de respuesta
class CacheService {
  static final CacheService _instance = CacheService._internal();
  SharedPreferences? _prefs;
  bool _initialized = false;
  
  // Configuración de duración de caché
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration productCacheDuration = Duration(minutes: 30);
  static const Duration userCacheDuration = Duration(hours: 2);

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  /// Inicializar el servicio (debe llamarse al inicio de la app)
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('📦 CacheService inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CacheService: SharedPreferences no disponible en esta plataforma: $e');
      }
      _initialized = true; // Marcar como inicializado aunque falle
    }
  }

  /// Guardar datos en caché con timestamp
  Future<void> setCache<T>(
    String key,
    T value, {
    Duration? cacheDuration,
  }) async {
    if (_prefs == null) return;
    try {
      final expiryTime = DateTime.now().add(cacheDuration ?? defaultCacheDuration);
      final cacheData = {
        'value': value,
        'expiry': expiryTime.toIso8601String(),
      };
      
      final json = jsonEncode(cacheData);
      await _prefs?.setString(key, json);
      
      if (kDebugMode) {
        debugPrint('💾 Caché guardado: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error guardando caché $key: $e');
      }
    }
  }

  /// Obtener datos del caché si son válidos
  Future<T?> getCacheAsync<T>(String key) async {
    if (_prefs == null) return null;
    try {
      final json = _prefs?.getString(key);
      if (json == null) return null;

      final cacheData = jsonDecode(json) as Map<String, dynamic>;
      final expiryString = cacheData['expiry'] as String;
      final expiry = DateTime.parse(expiryString);

      // Verificar si el caché expiró
      if (DateTime.now().isAfter(expiry)) {
        await removeCache(key);
        if (kDebugMode) {
          debugPrint('⏰ Caché expirado: $key');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ Caché válido: $key');
      }
      return cacheData['value'] as T?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error leyendo caché $key: $e');
      }
      return null;
    }
  }

  /// Obtener datos del caché de forma síncrona (sin esperar)
  T? getCache<T>(String key) {
    if (_prefs == null) return null;
    try {
      final json = _prefs?.getString(key);
      if (json == null) return null;

      final cacheData = jsonDecode(json) as Map<String, dynamic>;
      final expiryString = cacheData['expiry'] as String;
      final expiry = DateTime.parse(expiryString);

      // Verificar si el caché expiró
      if (DateTime.now().isAfter(expiry)) {
        _prefs?.remove(key);
        if (kDebugMode) {
          debugPrint('⏰ Caché expirado: $key');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ Caché válido: $key');
      }
      return cacheData['value'] as T?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error leyendo caché $key: $e');
      }
      return null;
    }
  }

  /// Verificar si un caché existe y es válido
  bool isCacheValid(String key) {
    final value = getCache(key);
    return value != null;
  }

  /// Remover un caché específico
  Future<void> removeCache(String key) async {
    if (_prefs == null) return;
    await _prefs?.remove(key);
    if (kDebugMode) {
      debugPrint('🗑️ Caché removido: $key');
    }
  }

  /// Limpiar todo el caché
  Future<void> clearAllCache() async {
    if (_prefs == null) return;
    await _prefs?.clear();
    if (kDebugMode) {
      debugPrint('🧹 Todo el caché fue limpiado');
    }
  }

  /// Limpiar caché con patrón (ej: "products_*")
  Future<void> clearCachePattern(String pattern) async {
    if (_prefs == null) return;
    final keys = _prefs?.getKeys() ?? <String>{};
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    
    for (String key in keys) {
      if (regex.hasMatch(key)) {
        await _prefs?.remove(key);
      }
    }
    
    if (kDebugMode) {
      debugPrint('🧹 Caché pattern limpiado: $pattern');
    }
  }

  /// Obtener tamaño aproximado del caché en KB
  int getCacheSize() {
    if (_prefs == null) return 0;
    int totalSize = 0;
    for (String key in _prefs?.getKeys() ?? <String>{}) {
      final value = _prefs?.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    }
    return (totalSize / 1024).toInt();
  }

  /// Generar clave de caché con prefijo
  static String generateCacheKey(String prefix, String identifier) {
    return '${prefix}_$identifier';
  }
}
