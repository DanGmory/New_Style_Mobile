import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'dart:core';

/// Servicio dedicado para el manejo de imágenes de productos
class ImageService {
  static const String defaultImagePath = '/assets/img/products/';
  static const String fallbackImageUrl = 'https://via.placeholder.com/400x400/E5E7EB/6B7280?text=Producto';
  
  /// Construir URL de imagen completa usando el host base configurado
  static String buildImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) {
      return fallbackImageUrl;
    }
    
    // Si ya es una URL completa, usarla tal como está
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Usar el host configurado en ApiConfig
    final baseUrl = ApiConfig.host;
    
    // Si la imagen empieza con '/', agregarla directamente
    if (imageUrl.startsWith('/')) {
      final encoded = Uri.encodeFull(imageUrl);
      return '$baseUrl$encoded';
    }
    
    // Construir ruta estándar de assets de imagen
    final encoded = Uri.encodeFull(imageUrl);
    final finalUrl = '$baseUrl/assets/img/$encoded';
    
    if (kDebugMode) {
      debugPrint('🖼️ URL de imagen: $finalUrl');
    }
    
    // Retornar la URL construida
    return finalUrl;
  }
  
  /// Verificar si una URL de imagen es válida
  static Future<bool> isImageUrlValid(String url) async {
    if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) {
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
  
  /// Obtener lista de URLs alternativas para una imagen (solo URL principal)
  static List<String> getAlternativeImageUrls(String imageUrl) {
    if (imageUrl.isEmpty) {
      return [fallbackImageUrl];
    }

    final alternatives = <String>[];

    // Si la ruta es un asset local, devolverlo como tal
    if (imageUrl.startsWith('assets/')) {
      return [imageUrl, fallbackImageUrl];
    }

    // Si ya es una URL completa, agregarla primera
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      alternatives.add(imageUrl);
      alternatives.add(fallbackImageUrl);
      return alternatives;
    }

    // Construir URL usando el host configurado
    final encoded = Uri.encodeFull(imageUrl);
    final baseUrl = ApiConfig.host;
    
    if (imageUrl.startsWith('/')) {
      alternatives.add('$baseUrl$encoded');
    } else {
      alternatives.add('$baseUrl/assets/img/$encoded');
    }

    // Agregar imagen de fallback al final
    alternatives.add(fallbackImageUrl);

    return alternatives;
  }
  
  /// Probar múltiples URLs y devolver la primera que funcione
  static Future<String> findWorkingImageUrl(String originalUrl) async {
    final alternatives = getAlternativeImageUrls(originalUrl);
    
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