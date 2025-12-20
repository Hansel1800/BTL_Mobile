import 'package:cloud_firestore/cloud_firestore.dart';

class ProductVariant {
  final String color;
  final String size;
  final double price;
  final int stock;

  ProductVariant({
    required this.color,
    required this.size,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'size': size,
      'price': price,
      'stock': stock,
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final int stock;
  final List<String> colors;
  final List<String> sizes;
  final String gender;
  final List<ProductVariant> variants;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.stock,
    this.colors = const [],
    this.sizes = const [],
    this.gender = 'Unisex',
    this.variants = const [],
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'colors': colors,
      'sizes': sizes,
      'gender': gender,
      'variants': variants.map((v) => v.toJson()).toList(),
      'description': description,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      stock: json['stock'] ?? 0,
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
      gender: json['gender'] ?? 'Unisex',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['description'] ?? '',
    );
  }

  factory Product.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      stock: data['stock'] ?? 0,
      colors: List<String>.from(data['colors'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      gender: data['gender'] ?? 'Unisex',
      variants: (data['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      description: data['description'] ?? '',
    );
  }
}
