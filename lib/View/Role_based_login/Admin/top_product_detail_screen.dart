import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TopProductDetailScreen extends ConsumerWidget {
  final Product product;

  const TopProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          // 1. Filter orders containing this product
          final productOrders = orders.where((order) {
            return order.products.any((item) => item.productId == product.id);
          }).toList();

          // 2. Calculate Stats
          double totalRevenue = 0;
          int totalSold = 0;
          Map<String, int> sizeSales = {};
          Map<String, double> sizeRevenue = {};

          for (var order in productOrders) {
            for (var item in order.products) {
              if (item.productId == product.id) {
                totalRevenue += item.price * item.quantity;
                totalSold += item.quantity;
                
                // Size stats
                String size = item.size ?? 'N/A';
                sizeSales[size] = (sizeSales[size] ?? 0) + item.quantity;
                sizeRevenue[size] = (sizeRevenue[size] ?? 0) + (item.price * item.quantity);
              }
            }
          }

          // Sort orders by date (newest first)
          productOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sản phẩm top hôm nay • $totalSold đơn',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                
                // Product Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: UniversalImage(
                          imageUrl: product.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₫${NumberFormat('#,###').format(product.price)} • SKU: ${product.id.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Danh mục: ${product.category}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Đang bán tốt',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard('Doanh thu', '₫${NumberFormat.compact().format(totalRevenue)}', '+22% vs hôm qua'),
                    _buildStatCard('Đã bán', '$totalSold cái', 'Tỷ lệ hoàn: 1.8%'),
                    _buildStatCard('Tồn kho', '${product.stock} cái', 'Dự kiến đủ 5 ngày'),
                    _buildActionCard('Quản lý tồn', 'Điều chỉnh', 'Cập nhật stock theo size'),
                  ],
                ),
                const SizedBox(height: 24),

                // Size Analysis
                const Text(
                  'Phân tích theo size',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Hiệu suất bán theo từng size',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: sizeSales.keys.map((size) {
                      final sold = sizeSales[size] ?? 0;
                      final revenue = sizeRevenue[size] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              child: Text(size, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sold > 10 ? 'Bán tốt' : 'Ổn định', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: totalSold > 0 ? sold / totalSold : 0,
                                    backgroundColor: Colors.grey.shade100,
                                    color: Colors.blue,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$sold cái • ₫${NumberFormat.compact().format(revenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Tồn: -', style: const TextStyle(color: Colors.grey, fontSize: 10)), // Mock stock split
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Orders
                const Text(
                  'Đơn gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Đơn có chứa ${product.name}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...productOrders.take(5).map((order) => _buildOrderItem(order, product.id)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String action, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(action, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Order order, String productId) {
    final item = order.products.firstWhere((i) => i.productId == productId);
    
    Color statusColor = Colors.green;
    if (order.status == 'Pending') statusColor = Colors.orange;
    if (order.status == 'Cancelled') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Text('#${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${item.quantity} cái • Size ${item.size ?? "N/A"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Hôm nay - ${DateFormat('HH:mm').format(order.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('₫${NumberFormat('#,###').format(item.price * item.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
