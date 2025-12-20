import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Product/user_product_detail_screen.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:do_an_quan_ao/ViewModel/promotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/ViewModel/favorite_provider.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tất cả', 'Nam', 'Nữ', 'Phụ kiện'];

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD29062),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Mãnh Hổ Vương',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm, thương hiệu...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD29062) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Banner
            SliverToBoxAdapter(
              child: bannersAsync.when(
                data: (banners) {
                  if (banners.isEmpty) return const SizedBox.shrink();
                  // Filter active banners if needed, for now show all
                  return SizedBox(
                    height: 180,
                    child: PageView.builder(
                      itemCount: banners.length,
                      itemBuilder: (context, index) {
                        final banner = banners[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(banner.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD29062),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Mua ngay'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // New Arrivals Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hàng mới về',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),

            // New Arrivals List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: productsAsync.when(
                  data: (products) {
                    // Sort by date or just take first few for demo
                    final newProducts = products.take(5).toList();
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: newProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(newProducts[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Lỗi tải sản phẩm')),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Best Sellers Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bán chạy',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),

            // Best Sellers List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: productsAsync.when(
                  data: (products) {
                    // Mock best sellers by reversing or random
                    final bestSellers = products.reversed.take(5).toList();
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: bestSellers.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(bestSellers[index], isHot: true);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Lỗi tải sản phẩm')),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, {bool isHot = false}) {
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
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                ),
                if (isHot)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Hot',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final favorites = ref.watch(favoriteProvider);
                      final isFavorite = favorites.any((p) => p.id == product.id);
                      return GestureDetector(
                        onTap: () {
                          ref.read(favoriteProvider.notifier).toggleFavorite(product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border, 
                            size: 16, 
                            color: isFavorite ? Colors.red : Colors.grey
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₫${NumberFormat('#,###').format(product.price)}',
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
