import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Product/user_product_detail_screen.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:do_an_quan_ao/ViewModel/promotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/ViewModel/favorite_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_order_history_screen.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/Model/order_model.dart' as ModelOrder;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Category/user_category_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Category/user_category_detail_screen.dart';
import 'package:do_an_quan_ao/ViewModel/navigation_provider.dart';
import 'package:do_an_quan_ao/Services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Chat/user_chat_screen.dart';
import 'package:do_an_quan_ao/Services/chat_service.dart';
import 'package:do_an_quan_ao/Model/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tất cả', 'Nam', 'Nữ', 'Phụ kiện'];

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
    _checkNewUser();
  }

  Future<void> _checkNewUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists && (doc.data()?['isNewUser'] == true)) {
        if (!mounted) return;
        
        // Construct voucher code logic same as AuthService
        String voucherCode = "TV${user.uid.substring(0, 5).toUpperCase()}";
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Chào mừng bạn mới!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chào mừng bạn đến với Mãnh Hổ Vương. \nTặng bạn mã giảm giá 10% cho đơn hàng đầu tiên:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(voucherCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.orange),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: voucherCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã!')));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('(Mã đã được lưu vào ví của bạn)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await docRef.update({'isNewUser': false});
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Tuyệt vời'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      floatingActionButton: StreamBuilder<List<ChatMessage>>(
        stream: ChatService().getMessages(FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData) {
              unreadCount = snapshot.data!.where((m) => m.isAdmin && !m.isRead).length;
          }
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserChatScreen()));
            },
            backgroundColor: const Color(0xFFD29062), // Orange theme
            child: Stack(
                clipBehavior: Clip.none,
                children: [
                    const Icon(Icons.chat_bubble, color: Colors.white),
                    if (unreadCount > 0)
                        Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                ),
                            ),
                        )
                ],
            ),
          );
        }
      ),
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
                        Row(
                          children: [
                            // Chat Icon with Badge
                             StreamBuilder<List<ChatMessage>>(
                                stream: ChatService().getMessages(FirebaseAuth.instance.currentUser?.uid ?? ''),
                                builder: (context, snapshot) {
                                  int unreadCount = 0;
                                  if (snapshot.hasData) {
                                      unreadCount = snapshot.data!.where((m) => m.isAdmin && !m.isRead).length;
                                  }
                                  return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                          IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 26),
                                              onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserChatScreen()));
                                              },
                                          ),
                                          if (unreadCount > 0)
                                              Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                      ),
                                                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                                      child: Text(
                                                          '$unreadCount',
                                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                      ),
                                                  ),
                                              )
                                      ],
                                  );
                                }
                             ),
                             const SizedBox(width: 8),

                            // Order History Icon with Badge
                            StreamBuilder<List<ModelOrder.Order>>(
                          stream: OrderRepository().getOrdersByUserId(FirebaseAuth.instance.currentUser?.uid ?? ''),
                          builder: (context, snapshot) {
                            int count = 0;
                            if (snapshot.hasData) {
                              count = snapshot.data!.where((o) {
                                final status = o.status.toLowerCase().trim();
                                return status != 'đã hủy' && status != 'giao hàng thành công';
                              }).length;
                            }
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.receipt_long_outlined, color: Colors.black, size: 28),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserOrderHistoryScreen()));
                                  },
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 5,
                                    top: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserCategoryDetailScreen(
                              categoryName: 'Tìm kiếm',
                              categorySubtitle: 'Tìm kiếm sản phẩm',
                              gender: 'Unisex',
                              autoFocusSearch: true,
                            ),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm sản phẩm...',
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
                                  onPressed: () {
                                    ref.read(navigationProvider.notifier).goToCategoryFromHome();
                                  },
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
                  child: UniversalImage(
                    imageUrl: product.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
