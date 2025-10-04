import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../../widgets/appbar.dart';
import '../../services/logger_service.dart';
import '../checkout/simple_thank_you_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const CartScreen({super.key, this.onBackPressed});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _cartService.getCartItems();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error cargando carrito', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeFromCart(productId);
    } else {
      await _cartService.updateQuantity(productId, newQuantity);
      await _loadCartItems();
    }
  }

  Future<void> _removeFromCart(String productId) async {
    await _cartService.removeFromCart(productId);
    await _loadCartItems();
  }

  double get _totalPrice {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(title: 'Mi Carrito', showBackButton: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildCartSummary(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agrega productos para comenzar a comprar',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          // Imagen del producto
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[800],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : Image.asset(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.brandName,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Controles de cantidad
          Column(
            children: [
              // Botón eliminar
              IconButton(
                onPressed: () => _removeFromCart(item.productId.toString()),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                iconSize: 20,
              ),
              const SizedBox(height: 8),
              // Control de cantidad
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(
                        item.productId.toString(),
                        item.quantity - 1,
                      ),
                      icon: const Icon(Icons.remove),
                      color: Colors.white,
                      iconSize: 16,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(
                        item.productId.toString(),
                        item.quantity + 1,
                      ),
                      icon: const Icon(Icons.add),
                      color: Colors.white,
                      iconSize: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[700]!, Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.checkroom, color: Colors.white54, size: 40),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resumen de compra
          Column(
            children: [
              _buildSummaryRow(
                'Subtotal:',
                '\$${_totalPrice.toStringAsFixed(0)}',
              ),
              _buildSummaryRow('Envío:', '\$0'),
              _buildSummaryRow(
                'IVA:',
                '\$${(_totalPrice * 0.19).toStringAsFixed(0)}',
              ),
              const Divider(color: Colors.grey, thickness: 0.5, height: 24),
              _buildSummaryRow(
                'Total:',
                '\$${(_totalPrice * 1.19).toStringAsFixed(0)}',
                isTotal: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón de comprar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cartItems.isNotEmpty ? _processOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'FINALIZAR COMPRA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _cartItems.isNotEmpty
                      ? Colors.black
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey[400],
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirmar Pedido',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Deseas finalizar tu compra por \$${(_totalPrice * 1.19).toStringAsFixed(0)}?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Generar número de orden único
        final orderNumber = 'NSM${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}${Random().nextInt(99)}';
        final totalAmount = _totalPrice * 1.19;
        
        // Procesar el pedido y limpiar el carrito
        await _cartService.clearCart();

        if (mounted) {
          // Navegar a la pantalla de agradecimiento
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SimpleThankYouScreen(
                orderNumber: orderNumber,
                totalAmount: totalAmount,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar el pedido: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
