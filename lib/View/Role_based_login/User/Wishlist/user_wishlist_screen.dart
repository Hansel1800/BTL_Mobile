import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Product/user_product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/ViewModel/favorite_provider.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';

class UserWishlistScreen extends ConsumerWidget {
  const UserWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Row(
                   children: [
                     Container(
                       decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                        color: Color(0xFFEBE4DB),
                       ),
                       child: IconButton(
                         icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                         onPressed: () {
                           context.findAncestorStateOfType<UserMainScreenState>()?.navigateToTab(0);
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text(
                           'Yêu thích',
                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           'Lưu trữ các sản phẩm bạn quan tâm',
                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                         ),
                       ],
                     ),
                   ],
                 ),
                 Container(
                    decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                        color: Color(0xFFEBE4DB),
                       ),
                   child: IconButton(
                     icon: const Icon(Icons.delete_outline, size: 20),
                     onPressed: () {
                       ref.read(favoriteProvider.notifier).clearFavorites();
                       
                     },
                   ),
                 ),
                ],
              ),
            ),
            
            // Info Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${favorites.length} sản phẩm đã lưu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chạm để xem chi tiết hoặc thêm vào giỏ',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE4DB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Yêu thích', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid
            Expanded(
              child: favorites.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Danh sách yêu thích trống', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    return _buildProductItem(context, ref, product);
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, WidgetRef ref, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                // Heart Icon
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(favoriteProvider.notifier).toggleFavorite(product);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, size: 16, color: Colors.red),
                    ),
                  ),
                ),
                // Tag (Mock)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAA92A), // Yellowish
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Hot', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                   const SizedBox(height: 8),
                  Text(
                    '${NumberFormat('#,###').format(product.price)}đ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
