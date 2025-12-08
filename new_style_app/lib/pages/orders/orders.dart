import 'package:flutter/material.dart';

enum OrderStatus { pending, processing, shipped, completed, cancelled }

class Order {
  final String id;
  final DateTime date;
  final OrderStatus status;
  final double total;
  final int items;
  final String image;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    required this.image,
  });
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Datos de ejemplo - En una app real, estos vendrían de una API
  final List<Order> _orders = [
    Order(
      id: 'ORD-2024-001',
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: OrderStatus.completed,
      total: 250.50,
      items: 3,
      image: 'https://via.placeholder.com/100?text=Producto1',
    ),
    Order(
      id: 'ORD-2024-002',
      date: DateTime.now().subtract(const Duration(days: 10)),
      status: OrderStatus.completed,
      total: 180.00,
      items: 2,
      image: 'https://via.placeholder.com/100?text=Producto2',
    ),
    Order(
      id: 'ORD-2024-003',
      date: DateTime.now().subtract(const Duration(days: 15)),
      status: OrderStatus.processing,
      total: 420.75,
      items: 5,
      image: 'https://via.placeholder.com/100?text=Producto3',
    ),
    Order(
      id: 'ORD-2024-004',
      date: DateTime.now().subtract(const Duration(days: 20)),
      status: OrderStatus.shipped,
      total: 95.25,
      items: 1,
      image: 'https://via.placeholder.com/100?text=Producto4',
    ),
  ];

  OrderStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _selectedFilter == null
        ? _orders
        : _orders.where((order) => order.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Órdenes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedFilter == null,
                  onSelected: (_) {
                    setState(() => _selectedFilter = null);
                  },
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getStatusLabel(status)),
                      selected: _selectedFilter == status,
                      onSelected: (_) {
                        setState(() => _selectedFilter = status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay órdenes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index], context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(
            order.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.id,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items} artículo${order.items > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              _formatDate(order.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                Chip(
                  label: Text(_getStatusLabel(order.status)),
                  backgroundColor: _getStatusColor(order.status),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _showOrderDetails(context, order);
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Detalles de Orden',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Número de Orden', order.id),
                    _buildDetailRow(
                      'Fecha',
                      _formatDate(order.date),
                    ),
                    _buildDetailRow(
                      'Estado',
                      _getStatusLabel(order.status),
                      valueColor: _getStatusColor(order.status),
                    ),
                    _buildDetailRow(
                      'Cantidad de Artículos',
                      '${order.items}',
                    ),
                    _buildDetailRow(
                      'Total',
                      '\$${order.total.toStringAsFixed(2)}',
                      valueColor: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rastreo en desarrollo'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Rastrear Envío'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.processing:
        return 'Procesando';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
