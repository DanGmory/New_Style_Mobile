import 'package:flutter/material.dart';
import '../../services/product_services.dart';
import '../../models/products_model.dart';
import '../../widgets/product_image.dart';
import 'product_detail.dart';

class SearchProductsScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchProductsScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<SearchProductsScreen> createState() => _SearchProductsScreenState();
}

class _SearchProductsScreenState extends State<SearchProductsScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Filtros
  String? _selectedCategory;
  String? _selectedBrand;
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _showFilters = false;

  List<String> _availableCategories = [];
  List<String> _availableBrands = [];
  double _maxAvailablePrice = 10000;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _extractFilterOptions();
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _extractFilterOptions() {
    final categories = <String>{};
    final brands = <String>{};
    double maxPrice = 0;

    for (final product in _allProducts) {
      if (product.category.isNotEmpty) categories.add(product.category);
      if (product.brand.isNotEmpty) brands.add(product.brand);
      final price = double.tryParse(product.price.toString()) ?? 0;
      if (price > maxPrice) maxPrice = price;
    }

    setState(() {
      _availableCategories = categories.toList()..sort();
      _availableBrands = brands.toList()..sort();
      _maxAvailablePrice = maxPrice;
      _maxPrice = maxPrice;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    _filteredProducts = _allProducts.where((product) {
      // Búsqueda de texto
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);

      // Filtro de categoría
      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;

      // Filtro de marca
      final matchesBrand =
          _selectedBrand == null || product.brand == _selectedBrand;

      // Filtro de precio
      final price = double.tryParse(product.price.toString()) ?? 0;
      final matchesPrice = price >= _minPrice && price <= _maxPrice;

      return matchesQuery && matchesCategory && matchesBrand && matchesPrice;
    }).toList();

    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedBrand = null;
      _minPrice = 0;
      _maxPrice = _maxAvailablePrice;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Productos'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Botón de filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showFilters = !_showFilters);
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _showFilters ? Colors.blue : Colors.grey[300],
                      foregroundColor:
                          _showFilters ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Panel de filtros
          if (_showFilters) _buildFiltersPanel(context),

          // Resultado de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Grid de productos
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product, context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categoría
            if (_availableCategories.isNotEmpty) ...[
              Text(
                'Categoría',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _applyFilters();
                    },
                  ),
                  ..._availableCategories.map((category) {
                    return FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                        _applyFilters();
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Marca
            if (_availableBrands.isNotEmpty) ...[
              Text(
                'Marca',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _selectedBrand == null,
                    onSelected: (_) {
                      setState(() => _selectedBrand = null);
                      _applyFilters();
                    },
                  ),
                  ..._availableBrands.map((brand) {
                    return FilterChip(
                      label: Text(brand),
                      selected: _selectedBrand == brand,
                      onSelected: (_) {
                        setState(() => _selectedBrand = brand);
                        _applyFilters();
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Rango de precio
            Text(
              'Precio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RangeSlider(
              min: 0,
              max: _maxAvailablePrice,
              values: RangeValues(_minPrice, _maxPrice),
              onChanged: (range) {
                setState(() {
                  _minPrice = range.start;
                  _maxPrice = range.end;
                });
                _applyFilters();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${_minPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_maxPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: ProductImage(imageUrl: product.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
