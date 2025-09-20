import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/products_model.dart';

class ProductService {
  final String baseUrl = "http://localhost:3000/api_v1/products"; 
  // cámbialo por la URL real de tu backend (ej: tu IP en LAN o dominio)

  /// Listar todos los productos
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener productos: ${response.reasonPhrase}");
    }
  }

  /// 🔹 Obtener producto por ID
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception("Producto no encontrado");
    } else {
      throw Exception("Error al obtener producto: ${response.reasonPhrase}");
    }
  }

  /// 🔹 Crear producto
  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Name": product.name,
        "Amount": product.amount,
        "category": product.category,
        "description": product.description,
        "price": product.price,
        "Image_fk": product.imageUrl,   // ⚠️ tu API espera ID de imagen, ajusta si necesario
        "Brand_fk": product.brand,
        "Color_fk": product.color,
        "Size_fk": product.size,
        "Type_product_fk": product.typeProduct,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['data'][0]);
    } else {
      throw Exception("Error al crear producto: ${response.reasonPhrase}");
    }
  }

  /// 🔹 Actualizar producto
  Future<void> updateProduct(int id, Product product) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
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
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al actualizar producto: ${response.reasonPhrase}");
    }
  }

  /// 🔹 Eliminar producto
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200) {
      throw Exception("Error al eliminar producto: ${response.reasonPhrase}");
    }
  }
}
