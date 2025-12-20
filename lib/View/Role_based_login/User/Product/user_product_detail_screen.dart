import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/ViewModel/cart_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Cart/user_cart_screen.dart';
import 'package:do_an_quan_ao/ViewModel/favorite_provider.dart';

class UserProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const UserProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<UserProductDetailScreen> createState() => _UserProductDetailScreenState();
}

class _UserProductDetailScreenState extends ConsumerState<UserProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    // Removed auto-selection to force user to choose
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'trắng': return Colors.white;
      case 'đen': return Colors.black;
      case 'xám': return Colors.grey;
      case 'xanh navy': return const Color(0xFF000080);
      case 'be': return const Color(0xFFF5F5DC);
      case 'đỏ': return Colors.red;
      case 'xanh lá': return Colors.green;
      case 'vàng': return Colors.yellow;
      case 'cam': return Colors.orange;
      case 'tím': return Colors.purple;
      case 'hồng': return Colors.pink;
      case 'nâu': return Colors.brown;
      default: return Colors.grey.shade200;
    }
  }

  double get _currentPrice {
    if (_selectedSize != null && _selectedColor != null) {
      // Find variant match
      try {
        final variant = widget.product.variants.firstWhere(
          (v) => v.size == _selectedSize && v.color == _selectedColor
        );
        return variant.price;
      } catch (e) {
        // No specific variant found
      }
    }
    return widget.product.price;
  }
  
  int get _currentStock {
     if (_selectedSize != null && _selectedColor != null) {
      try {
        final variant = widget.product.variants.firstWhere(
          (v) => v.size == _selectedSize && v.color == _selectedColor
        );
        return variant.stock;
      } catch (e) {
        // No specific variant found
      }
    }
    return widget.product.stock;
  }

  void _validateAndAddToCart() {
    if ((widget.product.sizes.isNotEmpty && _selectedSize == null) || 
        (widget.product.colors.isNotEmpty && _selectedColor == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Kích thước và Màu sắc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Add to cart
    ref.read(cartProvider.notifier).addToCart(
      widget.product, 
      _selectedSize, 
      _selectedColor, 
      1
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
    );
  }

  void _validateAndBuyNow() {
    if ((widget.product.sizes.isNotEmpty && _selectedSize == null) || 
        (widget.product.colors.isNotEmpty && _selectedColor == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Kích thước và Màu sắc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Add to cart and navigate
    ref.read(cartProvider.notifier).addToCart(
      widget.product, 
      _selectedSize, 
      _selectedColor, 
      1
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
    );

    // Ideally navigate to Cart tab. 
    // Since we don't have direct access to MainScreen state, 
    // providing a consistent "Cart" push screen or popping to main and switching tab is complex.
    // For now, let's just push the CartScreen on top.
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserCartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.product.imageUrl.isNotEmpty
                  ? Container(
                      color: Colors.white, // Background for non-filling images
                      child: CachedNetworkImage(
                        imageUrl: widget.product.imageUrl,
                        fit: BoxFit.contain, // Show full image
                      ),
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 100)),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final favorites = ref.watch(favoriteProvider);
                  final isFavorite = favorites.any((p) => p.id == widget.product.id);
                  return IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black,
                      ),
                    ),
                    onPressed: () {
                      ref.read(favoriteProvider.notifier).toggleFavorite(widget.product);
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₫${NumberFormat('#,###').format(_currentPrice)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD29062)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Text(
                        'Danh mục: ${widget.product.category}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                       Text(
                        'Tồn kho: $_currentStock',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                 
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isEmpty 
                        ? 'Chưa có mô tả cho sản phẩm này.' 
                        : widget.product.description,
                    style: TextStyle(color: widget.product.description.isEmpty ? Colors.grey : Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kích thước',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: widget.product.sizes.map((size) {
                      final isSelected = size == _selectedSize;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSize = size;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.transparent,
                            border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            size, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Màu sắc: ${_selectedColor ?? ''}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: widget.product.colors.map((colorName) {
                      final isSelected = colorName == _selectedColor;
                      final color = _getColorFromName(colorName);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = colorName;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 36, 
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateAndAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Thêm vào giỏ'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateAndBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD29062),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mua ngay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
