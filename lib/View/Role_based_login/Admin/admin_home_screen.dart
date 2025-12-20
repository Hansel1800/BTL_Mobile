import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/add_edit_product_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/dashboard_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/order_management_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/user_management_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/promotion_management_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:do_an_quan_ao/ViewModel/admin_provider.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TabNavigator(navigatorKey: _navigatorKeys[0], rootPage: const DashboardScreen()),
      const OrderManagementScreen(),
      TabNavigator(navigatorKey: _navigatorKeys[2], rootPage: const ProductListTab()),
      const UserManagementScreen(showBackButton: false),
      const PromotionManagementScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(adminIndexProvider);

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          // Handle back button for nested navigators
          final NavigatorState? navigator = _navigatorKeys[selectedIndex].currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          } else {
            // If on the first tab, exit app. Otherwise, go to first tab.
            if (selectedIndex != 0) {
               ref.read(adminIndexProvider.notifier).setIndex(0);
            } else {
               // Allow app exit
               // SystemNavigator.pop(); // Optional: explicit exit
               // For now, we can just let it stay or implement double-back-to-exit
            }
          }
        },
        child: IndexedStack(
          index: selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Khuyến mãi',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          ref.read(adminIndexProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class ProductListTab extends ConsumerStatefulWidget {
  const ProductListTab({super.key});

  @override
  ConsumerState<ProductListTab> createState() => _ProductListTabState();
}

class _ProductListTabState extends ConsumerState<ProductListTab> {
  String _selectedGenderFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              "AD",
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        title: const Text(
          "Sản phẩm",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
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
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Danh mục & Sản phẩm",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Quản lý tồn kho và thông tin sản phẩm",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                
                // Gender Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildGenderFilterChip("Tất cả"),
                      const SizedBox(width: 8),
                      _buildGenderFilterChip("Nam"),
                      const SizedBox(width: 8),
                      _buildGenderFilterChip("Nữ"),
                      const SizedBox(width: 8),
                      _buildGenderFilterChip("Unisex"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Tìm theo tên, SKU...",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Chips (Existing)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Đang bán", true),
                      const SizedBox(width: 8),
                      _buildFilterChip("Sắp hết hàng", false),
                      const SizedBox(width: 8),
                      _buildFilterChip("Ẩn", false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text("Thêm sản phẩm", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsyncValue.when(
              data: (products) {
                // Filter by Gender
                final filteredProducts = products.where((p) {
                   if (_selectedGenderFilter == 'Tất cả') return true;
                   return p.gender == _selectedGenderFilter;
                }).toList();

                // Group products by category
                final Map<String, List<Product>> groupedProducts = {};
                for (var product in filteredProducts) {
                  final category = product.category.isEmpty ? 'Khác' : product.category;
                  if (!groupedProducts.containsKey(category)) {
                    groupedProducts[category] = [];
                  }
                  groupedProducts[category]!.add(product);
                }

                if (groupedProducts.isEmpty) {
                   return const Center(child: Text("Không có sản phẩm nào."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedProducts.length,
                  itemBuilder: (context, index) {
                    final category = groupedProducts.keys.elementAt(index);
                    final categoryProducts = groupedProducts[category]!;
                    final lowStockCount = categoryProducts.where((p) => p.stock < 10).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${categoryProducts.length} sản phẩm • $lowStockCount sắp hết hàng",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Product List for this Category
                        ...categoryProducts.map((product) => _buildProductItem(context, product, ref)),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilterChip(String label) {
    final isSelected = _selectedGenderFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGenderFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade200 : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product, WidgetRef ref) {
    // Mock data logic
    String sku = "SKU-${product.id.substring(0, 6).toUpperCase()}";
    int soldToday = (product.price % 50).toInt(); // Random-ish number
    
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (product.stock == 0) {
      statusText = "Hết hàng";
      statusColor = Colors.red;
      statusBgColor = Colors.red.shade50;
    } else if (product.stock < 10) {
      statusText = "Sắp hết hàng";
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
    } else {
      statusText = "Đang bán tốt";
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[100],
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(child: Text("IMG", style: TextStyle(color: Colors.grey, fontSize: 10))),
                        )
                      : const Center(child: Text("IMG", style: TextStyle(color: Colors.grey, fontSize: 10))),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "SKU: $sku • ${product.category} • ${product.gender}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₫${product.price.toStringAsFixed(0)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tồn: ${product.stock} cái • Đã bán hôm nay: $soldToday",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionText("Xem chi tiết", Colors.blue, () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(product: product),
                    ),
                  );
              }),
              const SizedBox(width: 16),
              _buildActionText("Xóa sản phẩm", Colors.red, () {
                _showDeleteConfirmation(context, ref, product);
              }),
              const SizedBox(width: 16),
              _buildActionText("Sửa thông tin", Colors.blue, () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(product: product),
                    ),
                  );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionText(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa Sản Phẩm"),
        content: Text("Bạn có muốn xóa sản phẩm ${product.name}không ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(productControllerProvider.notifier)
                  .deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


class TabNavigator extends StatelessWidget {
  final Widget rootPage;
  final GlobalKey<NavigatorState>? navigatorKey;
  const TabNavigator({super.key, required this.rootPage, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }
}
