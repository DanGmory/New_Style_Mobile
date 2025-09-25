import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Lista de productos mock
    final List<Map<String, dynamic>> cartItems = [
      {"name": "Producto A", "price": 25000, "quantity": 1},
      {"name": "Producto B", "price": 18000, "quantity": 2},
      {"name": "Producto C", "price": 32000, "quantity": 1},
    ];

    // 🔹 Calcular total
    double total = cartItems.fold(0, (sum, item) => sum + (item["price"] * item["quantity"]));

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Carrito"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // 🔹 Lista de productos
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(item["name"]),
                  subtitle: Text("Cantidad: ${item["quantity"]}"),
                  trailing: Text("\$${item["price"] * item["quantity"]}"),
                );
              },
            ),
          ),

          // 🔹 Total + Botón pagar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$$total", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aquí conectas con tu pasarela de pagos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Procesando pago...")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Pagar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
