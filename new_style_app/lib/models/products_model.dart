class Product {
  final int id;
  final String name;
  final int amount;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final String imageName;
  final String brand;
  final String color;
  final String size;
  final String typeProduct;

  Product({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.imageName,
    required this.brand,
    required this.color,
    required this.size,
    required this.typeProduct,
  });

  ///  Crear objeto desde JSON de la API
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['Product_id'],
      name: json['Product_name'],
      amount: json['Product_amount'],
      category: json['Product_category'],
      description: json['Product_description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['Image_url'] ?? '',
      imageName: json['Image_name'] ?? '',
      brand: json['Brand_name'] ?? '',
      color: json['Color_name'] ?? '',
      size: json['Size_name'] ?? '',
      typeProduct: json['Type_product_name'] ?? '',
    );
  }

  ///  Getters útiles (como en tu modelo de Pokemon)
  String get capitalizedName =>
      name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : name;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get formattedId => '#${id.toString().padLeft(3, '0')}';
}
