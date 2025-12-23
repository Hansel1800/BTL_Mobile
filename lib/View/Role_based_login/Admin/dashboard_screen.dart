import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/top_product_detail_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/order_management_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/revenue_detail_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/user_management_screen.dart';
import 'package:do_an_quan_ao/ViewModel/admin_provider.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:do_an_quan_ao/ViewModel/user_provider.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:do_an_quan_ao/ViewModel/promotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(ordersProvider);
    final usersAsyncValue = ref.watch(usersProvider);
    final productsAsyncValue = ref.watch(productsProvider);
    final bannersAsyncValue = ref.watch(bannersProvider);
    final vouchersAsyncValue = ref.watch(vouchersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Panel',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await AuthService().signOut();
                // AuthStateHandler will handle navigation
              }
            },
          ),
        ],
      ),
      body: ordersAsyncValue.when(
        data: (allOrders) {
          return usersAsyncValue.when(
            data: (users) {
              // 1. Filter out Cancelled orders for all stats
              final activeOrders = allOrders.where((o) => o.status != 'Đã hủy').toList();

              // Calculate statistics based on ACTIVE orders
              final now = DateTime.now();
              final todayOrders = activeOrders.where((order) {
                return order.createdAt.year == now.year &&
                    order.createdAt.month == now.month &&
                    order.createdAt.day == now.day;
              }).toList();

              final yesterday = DateTime(now.year, now.month, now.day - 1);
              final yesterdayOrders = activeOrders.where((order) {
                return order.createdAt.year == yesterday.year &&
                    order.createdAt.month == yesterday.month &&
                    order.createdAt.day == yesterday.day;
              }).toList();

              final totalRevenue = activeOrders.fold<double>(0, (sum, order) => sum + order.totalPrice);
              final todayRevenue = todayOrders.fold<double>(0, (sum, order) => sum + order.totalPrice);
              final yesterdayRevenue = yesterdayOrders.fold<double>(0, (sum, order) => sum + order.totalPrice);

              // Calculate percentage change
              final revenueChange = yesterdayRevenue > 0 
                  ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100)
                  : 0.0;

              final revenueChangeText = revenueChange >= 0 
                  ? '+${revenueChange.toStringAsFixed(0)}% vs hôm qua'
                  : '${revenueChange.toStringAsFixed(0)}% vs hôm qua';

              // User stats
              final todayUsers = users.where((u) => 
                u.createdAt.year == now.year && 
                u.createdAt.month == now.month && 
                u.createdAt.day == now.day
              ).length;

              // Product stats
              final int productCount = productsAsyncValue.maybeWhen(
                data: (products) => products.length,
                orElse: () => 0,
              );

              // Promotion stats
              final int bannerCount = bannersAsyncValue.maybeWhen(
                data: (banners) => banners.length,
                orElse: () => 0,
              );
              final int voucherCount = vouchersAsyncValue.maybeWhen(
                data: (vouchers) => vouchers.length,
                orElse: () => 0,
              );

              // Find Top Product (from Active Orders only)
              String topProductName = 'Chưa có dữ liệu';
              String topProductSales = '0 đơn';
              Product? topProduct;

              if (activeOrders.isNotEmpty) {
                Map<String, int> productSales = {};
                for (var order in activeOrders) {
                  for (var item in order.products) {
                    productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
                  }
                }

                if (productSales.isNotEmpty) {
                  var sortedKeys = productSales.keys.toList(growable: false)
                    ..sort((k1, k2) => productSales[k2]!.compareTo(productSales[k1]!));
                  String topProductId = sortedKeys.first;
                  int sales = productSales[topProductId]!;

                  productsAsyncValue.whenData((products) {
                    try {
                      topProduct = products.firstWhere((p) => p.id == topProductId);
                      topProductName = topProduct!.name;
                      topProductSales = '$sales sản phẩm';
                    } catch (e) {
                      topProductName = 'Sản phẩm đã xóa';
                    }
                  });
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Tổng quan hôm nay',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          context, 
                          'Doanh thu', 
                          '₫${(todayRevenue / 1000000).toStringAsFixed(1)}M', 
                          revenueChangeText, 
                          revenueChange >= 0 ? Colors.green : Colors.red
                        ),
                        _buildStatCard(
                          context, 
                          'Đơn hàng', 
                          '${activeOrders.length}', 
                          '+${todayOrders.length} mới', 
                          Colors.green
                        ),
                        _buildStatCard(
                          context, 
                          'Tổng User', 
                          '${users.length}', 
                          '+$todayUsers hôm nay', 
                          Colors.green
                        ),
                        _buildStatCard(
                          context, 
                          'Sản phẩm top', 
                          topProductName, 
                          topProductSales, 
                          Colors.green,
                          product: topProduct
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quản lý nhanh',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionItem(
                      context, 
                      ref, 
                      'Đơn hàng', 
                      'Lọc theo trạng thái, cập nhật Processing, Shipping...', 
                      '${activeOrders.where((o) {
                        final s = o.status.toLowerCase();
                        return s != 'giao hàng thành công' && s != 'delivered';
                      }).length} Processing', 
                      Colors.blue[50]!, 
                      Colors.blue
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionItem(context, ref, 'Danh mục & Sản phẩm', 'CRUD danh mục, form sản phẩm chọn danh mục từ Firebase.', '$productCount sản phẩm', Colors.blue[50]!, Colors.blue),
                    const SizedBox(height: 12),
                    _buildQuickActionItem(context, ref, 'User', 'Danh sách user, xem lịch sử đơn hàng, khóa tài khoản.', '${users.length} user', Colors.blue[50]!, Colors.blue),
                    const SizedBox(height: 12),
                    _buildQuickActionItem(context, ref, 'Khuyến mãi', 'Quản lý banner slider & tạo mã voucher.', '$bannerCount banner • $voucherCount voucher', Colors.blue[50]!, Colors.blue),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Lỗi tải user: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải dữ liệu: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String badgeText, Color badgeColor, {Product? product}) {
    return GestureDetector(
      onTap: () {
        if (title == 'Doanh thu') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RevenueDetailScreen()),
          );
        } else if (title == 'Đơn hàng') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderManagementScreen()),
          );
        } else if (title == 'Tổng User') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserManagementScreen()),
          );
        } else if (title == 'Sản phẩm top' && product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TopProductDetailScreen(product: product)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              value, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, WidgetRef ref, String title, String subtitle, String badgeText, Color badgeBgColor, Color badgeTextColor) {
    return GestureDetector(
      onTap: () {
        if (title == 'Đơn hàng') {
          // Switch to Order tab (index 1)
          ref.read(adminIndexProvider.notifier).setIndex(1);
        } else if (title == 'Danh mục & Sản phẩm') {
          // Switch to Product tab (index 2)
          ref.read(adminIndexProvider.notifier).setIndex(2);
        } else if (title == 'User') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserManagementScreen()),
          );
        } else if (title == 'Khuyến mãi') {
          // Switch to Promotions tab (index 4)
          ref.read(adminIndexProvider.notifier).setIndex(4);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
