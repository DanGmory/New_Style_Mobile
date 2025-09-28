import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import 'logger_service.dart';

class CartService {
  static const String _cartKey = 'user_cart_';

  // Obtener el ID del usuario actual del almacén local
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        // Extraer el ID del usuario directamente del JSON
        final user = userData['user'];
        if (user != null && user['id'] != null) {
          return user['id'].toString();
        }
      } catch (e) {
        LoggerService.error('Error obteniendo user ID', e);
      }
    }

    // Si no hay usuario logueado, usar un ID genérico
    return 'guest_user';
  }

  // Obtener la clave del carrito específica del usuario
  Future<String> _getCartKey() async {
    final userId = await _getCurrentUserId();
    return '$_cartKey$userId';
  }

  // Obtener todos los productos del carrito
  Future<List<CartItem>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = await _getCartKey();
      final cartData = prefs.getString(cartKey);

      if (cartData == null) return [];

      final List<dynamic> cartJson = json.decode(cartData);
      return cartJson.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      LoggerService.error('Error cargando carrito', e);
      return [];
    }
  }

  // Guardar carrito en almacenamiento local
  Future<void> _saveCartItems(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = await _getCartKey();
      final cartJson = items.map((item) => item.toJson()).toList();
      await prefs.setString(cartKey, json.encode(cartJson));
    } catch (e) {
      LoggerService.error('Error guardando carrito', e);
      throw Exception('No se pudo guardar el carrito');
    }
  }

  // Agregar producto al carrito
  Future<void> addToCart(
    Map<String, dynamic> product, {
    int quantity = 1,
  }) async {
    try {
      final cartItems = await getCartItems();
      final productId = product['Product_id'] ?? 0;

      // Buscar si el producto ya existe en el carrito
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.productId == productId,
      );

      if (existingItemIndex != -1) {
        // Si existe, aumentar la cantidad
        cartItems[existingItemIndex].quantity += quantity;
      } else {
        // Si no existe, agregar nuevo item
        final newItem = CartItem.fromProduct(product, quantity);
        cartItems.add(newItem);
      }

      await _saveCartItems(cartItems);
    } catch (e) {
      LoggerService.error('Error agregando al carrito', e);
      throw Exception('No se pudo agregar el producto al carrito');
    }
  }

  // Actualizar cantidad de un producto
  Future<void> updateQuantity(String productId, int newQuantity) async {
    try {
      final cartItems = await getCartItems();
      final itemIndex = cartItems.indexWhere(
        (item) => item.productId.toString() == productId,
      );

      if (itemIndex != -1) {
        if (newQuantity > 0) {
          cartItems[itemIndex].quantity = newQuantity;
        } else {
          cartItems.removeAt(itemIndex);
        }
        await _saveCartItems(cartItems);
      }
    } catch (e) {
      LoggerService.error('Error actualizando cantidad', e);
      throw Exception('No se pudo actualizar la cantidad');
    }
  }

  // Eliminar producto del carrito
  Future<void> removeFromCart(String productId) async {
    try {
      final cartItems = await getCartItems();
      cartItems.removeWhere((item) => item.productId.toString() == productId);
      await _saveCartItems(cartItems);
    } catch (e) {
      LoggerService.error('Error eliminando del carrito', e);
      throw Exception('No se pudo eliminar el producto del carrito');
    }
  }

  // Verificar si un producto está en el carrito
  Future<bool> isInCart(int productId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.any((item) => item.productId == productId);
    } catch (e) {
      LoggerService.error('Error verificando producto en carrito', e);
      return false;
    }
  }

  // Obtener cantidad de un producto específico en el carrito
  Future<int> getProductQuantity(int productId) async {
    try {
      final cartItems = await getCartItems();
      final item = cartItems.firstWhere(
        (item) => item.productId == productId,
        orElse: () => CartItem(
          productId: 0,
          productName: '',
          brandName: '',
          price: 0,
          quantity: 0,
          imageUrl: '',
          category: '',
          description: '',
          size: '',
          color: '',
        ),
      );
      return item.quantity;
    } catch (e) {
      LoggerService.error('Error obteniendo cantidad del producto', e);
      return 0;
    }
  }

  // Obtener número total de items en el carrito
  Future<int> getCartItemCount() async {
    try {
      final cartItems = await getCartItems();
      int total = 0;
      for (final item in cartItems) {
        total += item.quantity;
      }
      return total;
    } catch (e) {
      LoggerService.error('Error obteniendo total de items', e);
      return 0;
    }
  }

  // Obtener precio total del carrito
  Future<double> getCartTotal() async {
    try {
      final cartItems = await getCartItems();
      double total = 0.0;
      for (final item in cartItems) {
        total += item.totalPrice;
      }
      return total;
    } catch (e) {
      LoggerService.error('Error calculando total', e);
      return 0.0;
    }
  }

  // Limpiar todo el carrito
  Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartKey = await _getCartKey();
      await prefs.remove(cartKey);
    } catch (e) {
      LoggerService.error('Error limpiando carrito', e);
      throw Exception('No se pudo limpiar el carrito');
    }
  }

  // Migrar carrito cuando el usuario cambie (login/logout)
  Future<void> migrateCartForUser(String newUserId) async {
    try {
      // Obtener carrito actual
      final currentItems = await getCartItems();

      // Limpiar carrito actual
      await clearCart();

      // Si hay items y se está haciendo login (no logout), migrar los items
      if (currentItems.isNotEmpty && newUserId != 'guest_user') {
        final prefs = await SharedPreferences.getInstance();
        final newCartKey = '$_cartKey$newUserId';
        final cartJson = currentItems.map((item) => item.toJson()).toList();
        await prefs.setString(newCartKey, json.encode(cartJson));
      }
    } catch (e) {
      LoggerService.error('Error migrando carrito', e);
    }
  }
}
