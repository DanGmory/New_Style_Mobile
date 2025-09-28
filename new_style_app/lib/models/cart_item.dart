class CartItem {
  final int productId;
  final String productName;
  final String brandName;
  final double price;
  int quantity;
  final String imageUrl;
  final String category;
  final String description;
  final String size;
  final String color;

  CartItem({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.size,
    required this.color,
  });

  // Convertir de JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['Product_id'] ?? json['productId'] ?? 0,
      productName: json['Product_name'] ?? json['productName'] ?? '',
      brandName: json['Brand_name'] ?? json['brandName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['Image_url'] ?? json['imageUrl'] ?? '',
      category: json['Product_category'] ?? json['category'] ?? '',
      description: json['Product_description'] ?? json['description'] ?? '',
      size: json['Size_name'] ?? json['size'] ?? '',
      color: json['Color_name'] ?? json['color'] ?? '',
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'brandName': brandName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
      'size': size,
      'color': color,
    };
  }

  // Crear desde un producto existente
  factory CartItem.fromProduct(Map<String, dynamic> product, int quantity) {
    return CartItem(
      productId: product['Product_id'] ?? 0,
      productName: product['Product_name'] ?? '',
      brandName: product['Brand_name'] ?? '',
      price: (product['price'] ?? 0).toDouble(),
      quantity: quantity,
      imageUrl: product['Image_url'] ?? '',
      category: product['Product_category'] ?? '',
      description: product['Product_description'] ?? '',
      size: product['Size_name'] ?? '',
      color: product['Color_name'] ?? '',
    );
  }

  // Calcular total para este item
  double get totalPrice => price * quantity;

  // Crear una copia con modificaciones
  CartItem copyWith({
    int? productId,
    String? productName,
    String? brandName,
    double? price,
    int? quantity,
    String? imageUrl,
    String? category,
    String? description,
    String? size,
    String? color,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      brandName: brandName ?? this.brandName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      description: description ?? this.description,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $productId, name: $productName, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
