import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // para kIsWeb
import '../models/products_model.dart';

class ProductService {
  late final Dio _dio;

  ProductService() {
    const String localIp = "192.168.1.7";
    const int port = 3000;

    final String baseUrl = kIsWeb
        ? "http://$localIp:3000/api_v1/products"
        : "http://10.0.2.2:3000/api_v1/products"; 

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ));
  }

  /// Listar todos los productos
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception("Error al obtener productos: ${e.message}");
    }
  }

  /// Obtener producto por ID
  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/$id');
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception("Error al obtener producto: ${e.message}");
    }
  }

  /// Crear producto
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
      throw Exception("Error al crear producto: ${e.message}");
    }
  }

  /// Actualizar producto
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
      throw Exception("Error al actualizar producto: ${e.message}");
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/$id');
    } on DioException catch (e) {
      throw Exception("Error al eliminar producto: ${e.message}");
    }
  }
}
