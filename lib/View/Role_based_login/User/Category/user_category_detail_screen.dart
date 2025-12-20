import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Product/user_product_detail_screen.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UserCategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final String categorySubtitle;
  final String gender;

  const UserCategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categorySubtitle,
    required this.gender,
  });

  @override
  ConsumerState<UserCategoryDetailScreen> createState() => _UserCategoryDetailScreenState();
}

class _UserCategoryDetailScreenState extends ConsumerState<UserCategoryDetailScreen> {
  String _selectedSort = 'Phổ biến nhất';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Filter products based on category and mock gender logic
                  // Note: In a real app, products would have a 'gender' field.
                  // For now, we will just filter by category.
                  final filteredProducts = products.where((p) {
                     // Normalize strings for comparison
                     final pCat = p.category.trim().toLowerCase();
                     final targetCat = widget.categoryName.trim().toLowerCase();
                     final pGender = p.gender.trim();
                     final targetGender = widget.gender.trim();

                     // Filter by Gender (Strict)
                     if (pGender != targetGender) return false;
                     
                     // Filter by Category (Smart Matching)
                     if (targetCat.contains('áo')) {
                       // Match generic "áo" but also specific types like "sơ mi"
                       if (pCat.contains('áo') || pCat.contains('sơ mi') || pCat.contains('polo') || pCat.contains('sweater') || pCat.contains('hoodie')) {
                         return true;
                       }
                     }
                     
                     if (targetCat.contains('quần')) {
                       if (pCat.contains('quần') || pCat.contains('jean') || pCat.contains('kaki') || pCat.contains('short')) {
                         return true;
                       }
                     }

                     if (targetCat.contains('váy') || targetCat.contains('đầm')) {
                       if (pCat.contains('váy') || pCat.contains('đầm')) {
                         return true;
                       }
                     }

                     // Fallback simple containment
                     return pCat.contains(targetCat) || targetCat.contains(pCat);
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Không tìm thấy sản phẩm nào trong danh mục này."),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredProducts.length} sản phẩm',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_vert, size: 16, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedSort,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(filteredProducts[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Lỗi: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF9F5F0), // Light beige header bg
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.categorySubtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Size', 'Màu sắc', 'Khoảng giá', 'Thương hiệu', 'Chất liệu'];
    return Container(
      color: const Color(0xFFF9F5F0),
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 14, color: Colors.grey[600]), // Generic icon
                const SizedBox(width: 4),
                Text(
                  filter,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAB308), // Yellow badge
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(product.price),
                        style: const TextStyle(
                          color: Color(0xFFD29062),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Mock discount badge if needed
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }
}
