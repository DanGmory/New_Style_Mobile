import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Servicio dedicado para el manejo de imágenes de productos
class ImageService {
  static const String defaultImagePath = '/assets/img/products/';
  static const String fallbackImageUrl = 'https://via.placeholder.com/400x400/E5E7EB/6B7280?text=Producto';
  
  /// Construir URL de imagen completa con múltiples fallbacks
  static String buildImageUrl(String imageUrl, {String? serverIP}) {
    if (imageUrl.isEmpty) {
      return fallbackImageUrl;
    }
    
    // Si ya es una URL completa, usarla tal como está
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Determinar IP del servidor
    final ip = serverIP ?? '192.168.1.8';
    final baseUrl = 'http://$ip:3000';
    
    // Si la imagen empieza con '/', agregarla directamente
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    
    // Construir diferentes rutas posibles
    final possiblePaths = [
      '$baseUrl/assets/img/$imageUrl',
      '$baseUrl/assets/img/products/$imageUrl',
      '$baseUrl/public/img/$imageUrl',
      '$baseUrl/public/assets/img/$imageUrl',
      '$baseUrl/uploads/$imageUrl',
      '$baseUrl/static/img/$imageUrl',
    ];
    
    // En desarrollo, mostrar las rutas que estamos intentando
    if (kDebugMode) {
      debugPrint('🖼️ Construyendo URL para imagen: $imageUrl');
      debugPrint('🌐 IP del servidor: $ip');
      debugPrint('📍 URL principal: ${possiblePaths.first}');
    }
    
    // Retornar la primera URL construida (puedes implementar lógica de prueba aquí)
    return possiblePaths.first;
  }
  
  /// Verificar si una URL de imagen es válida
  static Future<bool> isImageUrlValid(String url) async {
    if (url.isEmpty || !url.startsWith('http')) {
      return false;
    }
    
    try {
      final dio = Dio();
      final response = await dio.head(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verificando imagen $url: $e');
      }
      return false;
    }
  }
  
  /// Obtener lista de URLs alternativas para una imagen
  static List<String> getAlternativeImageUrls(String imageUrl, {String? serverIP}) {
    if (imageUrl.isEmpty) {
      return [fallbackImageUrl];
    }
    
    final ip = serverIP ?? '192.168.1.8';
    final baseUrl = 'http://$ip:3000';
    
    final alternatives = <String>[];
    
    // Si ya es una URL completa, agregarla primera
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      alternatives.add(imageUrl);
    }
    
    // Generar múltiples rutas posibles
    final paths = [
      '/assets/img/',
      '/assets/img/products/',
      '/public/img/',
      '/public/assets/img/',
      '/uploads/',
      '/static/img/',
      '/images/',
      '/img/',
    ];
    
    for (String path in paths) {
      if (imageUrl.startsWith('/')) {
        alternatives.add('$baseUrl$imageUrl');
      } else {
        alternatives.add('$baseUrl$path$imageUrl');
      }
    }
    
    // Agregar imagen de fallback al final
    alternatives.add(fallbackImageUrl);
    
    return alternatives;
  }
  
  /// Probar múltiples URLs y devolver la primera que funcione
  static Future<String> findWorkingImageUrl(String originalUrl, {String? serverIP}) async {
    final alternatives = getAlternativeImageUrls(originalUrl, serverIP: serverIP);
    
    for (String url in alternatives) {
      if (await isImageUrlValid(url)) {
        if (kDebugMode) {
          debugPrint('✅ URL de imagen válida encontrada: $url');
        }
        return url;
      }
    }
    
    if (kDebugMode) {
      debugPrint('❌ No se encontró URL válida para: $originalUrl, usando fallback');
    }
    
    return fallbackImageUrl;
  }
  
  /// Generar diferentes variaciones de nombre de archivo
  static List<String> generateImageNameVariations(String imageName) {
    if (imageName.isEmpty) return [];
    
    final variations = <String>[];
    final nameWithoutExtension = imageName.split('.').first;
    final extension = imageName.contains('.') ? imageName.split('.').last : 'jpg';
    
    // Variaciones comunes
    variations.addAll([
      imageName, // Original
      '$nameWithoutExtension.jpg',
      '$nameWithoutExtension.jpeg',
      '$nameWithoutExtension.png',
      '$nameWithoutExtension.webp',
      '${nameWithoutExtension}_thumb.$extension',
      '${nameWithoutExtension}_small.$extension',
      '${nameWithoutExtension}_medium.$extension',
      '${nameWithoutExtension}_large.$extension',
      imageName.toLowerCase(),
      imageName.toUpperCase(),
    ]);
    
    return variations.toSet().toList(); // Eliminar duplicados
  }
}