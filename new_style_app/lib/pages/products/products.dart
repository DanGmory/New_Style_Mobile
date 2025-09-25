import 'package:flutter/material.dart';
import '../../services/product_services.dart';
import '../../models/products_model.dart';

// Enum para estados de carga más claros
enum ProductLoadingState {
  loading,
  loaded,
  error,
  empty,
  retrying,
}

// Clase para manejar el estado de la aplicación
class ProductState {
  final ProductLoadingState state;
  final List<Product> products;
  final String? errorMessage;
  final bool isRetrying;

  const ProductState({
    required this.state,
    this.products = const [],
    this.errorMessage,
    this.isRetrying = false,
  });

  ProductState copyWith({
    ProductLoadingState? state,
    List<Product>? products,
    String? errorMessage,
    bool? isRetrying,
  }) {
    return ProductState(
      state: state ?? this.state,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  ProductState _currentState = const ProductState(state: ProductLoadingState.loading);

  // Controladores para animaciones y scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Método para formatear precios de forma segura con validación mejorada
  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    
    try {
      if (price is String) {
        if (price.isEmpty) return '0.00';
        final parsedPrice = double.tryParse(price.replaceAll(',', ''));
        return parsedPrice?.toStringAsFixed(2) ?? '0.00';
      }
      
      if (price is num) {
        return price.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error formatting price: $e');
    }
    
    return '0.00';
  }

  /// Método para formatear cantidad de forma segura
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    
    try {
      if (amount is String) {
        return amount.isEmpty ? '0' : amount;
      }
      
      if (amount is num) {
        return amount.toString();
      }
    } catch (e) {
      debugPrint('Error formatting amount: $e');
    }
    
    return '0';
  }

  /// Método mejorado para agregar al carrito con mejor UX
  void _addToCart(Product product) {
    // Vibración táctil si está disponible
    // HapticFeedback.lightImpact();
    
    // Animación del botón o card
    // Aquí podrías agregar una animación
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Agregado por \$${_formatPrice(product.price)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ver Carrito',
          textColor: Colors.white,
          onPressed: () {
            // Navigator.pushNamed(context, '/cart');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navegación al carrito (implementar)'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
    
    debugPrint('Producto agregado: ${product.name} - \$${_formatPrice(product.price)}');
  }

  /// Método principal para cargar productos con mejor manejo de estados
  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _currentState = _currentState.copyWith(
        state: _currentState.products.isEmpty 
            ? ProductLoadingState.loading 
            : ProductLoadingState.loaded,
        isRetrying: _currentState.products.isNotEmpty,
      );
    });

    try {
      final products = await _loadProductsWithFallback();
      
      if (!mounted) return;

      setState(() {
        _currentState = ProductState(
          state: products.isEmpty 
              ? ProductLoadingState.empty 
              : ProductLoadingState.loaded,
          products: products,
          isRetrying: false,
        );
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentState = ProductState(
          state: ProductLoadingState.error,
          products: _currentState.products,
          errorMessage: e.toString(),
          isRetrying: false,
        );
      });
    }
  }

  /// Método con estrategias de fallback mejoradas
  Future<List<Product>> _loadProductsWithFallback() async {
    final strategies = [
      () => _productService.getProducts(),
      () => _productService.getProductsAlternative(),
      // () => _alternativeService.getProducts(), // Si implementas el servicio alternativo
    ];

    Exception? lastException;

    for (int i = 0; i < strategies.length; i++) {
      try {
        debugPrint('Intentando estrategia ${i + 1}');
        final products = await strategies[i]();
        debugPrint('Estrategia ${i + 1} exitosa: ${products.length} productos');
        return products;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('Estrategia ${i + 1} falló: $e');
        
        // Pequeña pausa entre intentos
        if (i < strategies.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    throw lastException ?? Exception('Todos los métodos de conexión fallaron');
  }

  /// Método de reintento con mejor feedback
  Future<void> _retryConnection() async {
    if (_currentState.isRetrying) return;

    setState(() {
      _currentState = _currentState.copyWith(isRetrying: true);
    });

    // Diagnóstico rápido primero
    try {
      final canConnect = await _productService.checkServerConnection();
      if (!canConnect && mounted) {
        _showConnectivityHint();
      }
    } catch (e) {
      debugPrint('Error en diagnóstico: $e');
    }

    await _loadProducts();
  }

  /// Mostrar sugerencias de conectividad
  void _showConnectivityHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Problema de conexión'),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Verifica que el servidor esté ejecutándose y tu conexión a internet',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Diagnóstico mejorado con más información
  Future<void> _showDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Diagnóstico'),
          ],
        ),
        content: const Text('Probando conexiones...'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final diagnostics = await _runDiagnostics();
      
      if (mounted) {
        Navigator.of(context).pop();
        _showDiagnosticResults(diagnostics);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError('Error ejecutando diagnóstico: $e');
      }
    }
  }

  Future<Map<String, String>> _runDiagnostics() async {
    final results = <String, String>{};
    
    // Probar conectividad básica
    try {
      await _productService.checkServerConnection();
      results['Servidor Principal'] = '✅ Conectado';
    } catch (e) {
      results['Servidor Principal'] = '❌ ${e.toString().substring(0, 50)}...';
    }

    // Probar método alternativo
    try {
      await _productService.getProductsAlternative();
      results['Método Alternativo'] = '✅ Funcionando';
    } catch (e) {
      results['Método Alternativo'] = '❌ ${e.toString().substring(0, 50)}...';
    }

    results['Estado Actual'] = _currentState.state.toString();
    results['Productos Cargados'] = '${_currentState.products.length}';
    
    if (_currentState.errorMessage != null) {
      results['Último Error'] = '${_currentState.errorMessage!.substring(0, 100)}...';
    }

    return results;
  }

  void _showDiagnosticResults(Map<String, String> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Resultados del Diagnóstico'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: results.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: entry.value),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _retryConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Modal de detalles del producto mejorado
  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del producto
                      if (product.imageUrl.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Nombre del producto
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Precio
                      Row(
                        children: [
                          const Text(
                            'Precio: ',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            '\$${_formatPrice(product.price)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Cantidad disponible
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Disponible: ${_formatAmount(product.amount)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botón agregar al carrito
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToCart(product);
                          },
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Agregar al Carrito'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar el estado de carga
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _currentState.isRetrying 
                ? 'Reintentando conexión...' 
                : 'Cargando productos...',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar el estado de error
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Error al cargar productos",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentState.errorMessage ?? 'Error desconocido',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentState.isRetrying ? null : _retryConnection,
                  icon: _currentState.isRetrying 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _currentState.isRetrying ? 'Reintentando...' : 'Reintentar'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showDiagnostic,
                  icon: const Icon(Icons.settings_ethernet),
                  label: const Text('Diagnóstico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No hay productos disponibles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Intenta actualizar la página",
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryConnection,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar la lista de productos
  Widget _buildProductGrid() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          controller: _scrollController,
          itemCount: _currentState.products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final product = _currentState.products[index];
            return _buildProductCard(product);
          },
        ),
      ),
    );
  }

  /// Widget mejorado para la tarjeta de producto
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Imagen del producto
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    // Botón de agregar al carrito flotante
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Información del producto
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        children: [
                          Text(
                            "\$${_formatPrice(product.price)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Stock: ${_formatAmount(product.amount)}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_currentState.state) {
          ProductLoadingState.loading => _buildLoadingState(),
          ProductLoadingState.error => _buildErrorState(),
          ProductLoadingState.empty => _buildEmptyState(),
          ProductLoadingState.loaded => _buildProductGrid(),
          ProductLoadingState.retrying => _buildProductGrid(),
        },
      ),
    );
  }
}