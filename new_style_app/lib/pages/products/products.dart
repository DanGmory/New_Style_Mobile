import 'package:flutter/material.dart';
import '../../services/product_services.dart';
// import '../../services/alternative_product_service.dart'; // Descomenta si quieres usar el servicio alternativo
import '../../models/products_model.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  // final AlternativeProductService _alternativeService = AlternativeProductService(); // Descomenta si usas el alternativo
  late Future<List<Product>> _futureProducts;
  bool _isRetrying = false;
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// ✅ Método para cargar productos con múltiples estrategias
  void _loadProducts() {
    setState(() {
      _futureProducts = _loadProductsWithFallback();
    });
  }

  /// ✅ Método que intenta diferentes estrategias de carga
  Future<List<Product>> _loadProductsWithFallback() async {
    try {
      // Estrategia 1: Método normal
      return await _productService.getProducts();
    } catch (e1) {
      print('❌ Método normal falló: $e1');
      _lastError = 'Método principal: $e1';
      
      try {
        // Estrategia 2: Método alternativo con diferentes URLs
        return await _productService.getProductsAlternative();
      } catch (e2) {
        print('❌ Método alternativo falló: $e2');
        _lastError = 'Método alternativo: $e2';
        
        try {
          // Estrategia 3: HTTP nativo (descomenta si implementas AlternativeProductService)
          // return await _alternativeService.getProducts();
          
          // Por ahora, lanzamos el error
          throw Exception('Todos los métodos de conexión fallaron:\n'
              'Principal: ${e1.toString().substring(0, 50)}...\n'
              'Alternativo: ${e2.toString().substring(0, 50)}...');
        } catch (e3) {
          print('❌ HTTP nativo falló: $e3');
          rethrow;
        }
      }
    }
  }

  /// ✅ Método para reintentar manualmente con diagnóstico
  void _retryConnection() async {
    setState(() {
      _isRetrying = true;
    });

    // Mostrar información de diagnóstico
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnosticando conexión...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Probar conectividad primero
      bool canConnect = await _productService.checkServerConnection();
      
      if (!canConnect && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ No se puede conectar al servidor'),
                const Text('Verifica:'),
                const Text('• Servidor ejecutándose en puerto 3000'),
                const Text('• Misma red WiFi'),
                const Text('• IP correcta: 192.168.1.7'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error en diagnóstico: $e');
    }

    // Esperar un momento antes de reintentar
    await Future.delayed(const Duration(seconds: 1));
    
    _loadProducts();
    
    setState(() {
      _isRetrying = false;
    });
  }

  /// ✅ Método para mostrar diagnóstico completo
  void _showDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Ejecutando diagnóstico...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Probando conexiones...'),
          ],
        ),
      ),
    );

    try {
      // Probar conectividad con el servicio alternativo si está disponible
      String diagnosticResult = 'Diagnóstico de conectividad:\n\n';
      
      try {
        await _productService.checkServerConnection();
        diagnosticResult += '✅ ProductService: Conectado\n';
      } catch (e) {
        diagnosticResult += '❌ ProductService: $e\n';
      }

      diagnosticResult += '\nÚltimo error: $_lastError';

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Diagnóstico de Red'),
            content: SingleChildScrollView(
              child: Text(diagnosticResult),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _retryConnection();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text("Categoría: ${product.category}"),
              const SizedBox(height: 5),
              Text("Descripción: ${product.description}"),
              const SizedBox(height: 5),
              Text(
                "Precio: \${product.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              Text("Cantidad: ${product.amount}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _isRetrying ? 'Reintentando conexión...' : 'Cargando productos...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Error al cargar productos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _retryConnection,
                    icon: _isRetrying 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRetrying ? 'Reintentando...' : 'Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showDiagnostic,
                    icon: const Icon(Icons.settings_ethernet),
                    label: const Text('Diagnóstico'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No hay productos disponibles",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retryConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _loadProducts(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () => _showProductDetails(product),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (product.imageUrl.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                product.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported, 
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}