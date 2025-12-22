import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
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
  final bool autoFocusSearch;

  const UserCategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categorySubtitle,
    required this.gender,
    this.autoFocusSearch = false,
  });

  @override
  ConsumerState<UserCategoryDetailScreen> createState() => _UserCategoryDetailScreenState();
}

class _UserCategoryDetailScreenState extends ConsumerState<UserCategoryDetailScreen> {
  String _selectedSort = 'Phổ biến nhất';
  late bool _showSearch;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter States
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedPriceRange; 

  @override
  void initState() {
    super.initState();
    _showSearch = widget.autoFocusSearch;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Lavender Blush / Light Pink
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
                     // Search Filter
                     if (_searchController.text.isNotEmpty) {
                        final query = _removeDiacritics(_searchController.text.toLowerCase());
                        final pName = _removeDiacritics(p.name.toLowerCase());
                        final pCat = _removeDiacritics(p.category.toLowerCase());
                        
                        if (!pName.contains(query) && !pCat.contains(query)) {
                          return false;
                        }
                     }

                     // Filter by Gender (Inclusive)
                     // Filter by Gender (Inclusive)
                     final pGenderLowercase = p.gender.trim().toLowerCase();
                     final targetGenderLowercase = widget.gender.trim().toLowerCase();
                     bool genderMatch = false;

                     if (targetGenderLowercase == 'tất cả') {
                        genderMatch = true;
                     } else if (targetGenderLowercase == 'nam') {
                        genderMatch = (pGenderLowercase == 'nam' || pGenderLowercase == 'unisex');
                     } else if (targetGenderLowercase == 'nữ') {
                        genderMatch = (pGenderLowercase == 'nữ' || pGenderLowercase == 'unisex');
                     } else {
                        genderMatch = (pGenderLowercase == targetGenderLowercase);
                     }
                     
                     if (!genderMatch) return false;

                     // Filter by Size
                     if (_selectedSize != null && !p.sizes.contains(_selectedSize)) {
                       return false;
                     }

                     // Filter by Color
                     if (_selectedColor != null && !p.colors.contains(_selectedColor)) {
                       return false;
                     }

                     // Filter by Price
                     if (_selectedPriceRange != null) {
                        if (_selectedPriceRange == '< 200k') {
                           if (p.price >= 200000) return false;
                        } else if (_selectedPriceRange == '200k - 500k') {
                           if (p.price < 200000 || p.price > 500000) return false;
                        } else if (_selectedPriceRange == '> 500k') {
                           if (p.price <= 500000) return false;
                        }
                     }

                     // Filter by Category (Smart Matching)
                     final pCat = p.category.trim().toLowerCase();
                     final targetCat = widget.categoryName.trim().toLowerCase();

                     if (targetCat == 'tìm kiếm' || targetCat == 'tất cả') {
                        // Skip category filter if strictly searching or viewing all
                        // But wait, if searching, we relied on the search query check above.
                        // If search query is empty and category is 'Tìm kiếm', show all? Yes.
                        return true; 
                     }

                     if (targetCat.contains('áo')) {
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

                  // Sorting Logic
                  if (_selectedSort == 'Giá thấp - cao') {
                    filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                  } else if (_selectedSort == 'Giá cao - thấp') {
                    filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                  } else if (_selectedSort == 'Mới nhất') {
                    
                  }

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
                              child: InkWell(
                                onTap: _showSortBottomSheet,
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
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
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

  void _showSortBottomSheet() {
    final options = ['Phổ biến nhất', 'Giá thấp - cao', 'Giá cao - thấp', 'Mới nhất'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ...options.map((option) => ListTile(
              title: Text(option, style: TextStyle(color: _selectedSort == option ? const Color(0xFFD29062) : Colors.black)),
              trailing: _selectedSort == option ? const Icon(Icons.check, color: Color(0xFFD29062)) : null,
              onTap: () {
                setState(() {
                  _selectedSort = option;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFFF0F5), // Light Pink Header
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
          if (!_showSearch)
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
            )
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm ${widget.categoryName}...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(fontSize: 14),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ),
          // IconButton(
          //   icon: const Icon(Icons.tune, color: Colors.black),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    // Extract colors dynamically from loaded products
    final products = ref.watch(productsProvider).value ?? [];
    
    // Dynamic Colors
    final List<String> availableColors = products
        .expand((p) => p.colors)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    availableColors.sort(); // Alphabetical

    final colorsToShow = availableColors.isNotEmpty 
        ? availableColors 
        : ['Trắng', 'Đen', 'Xám', 'Đỏ', 'Xanh', 'Be', 'Vàng', 'Hồng', 'Nâu'];

    // Dynamic Sizes
    final List<String> availableSizes = products
        .expand((p) => p.sizes)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    
    // Custom Sort for Sizes
    const sizeOrder = ['XXS', 'XS', 'S', 'M', 'L', 'XL', '2XL', 'XXL', '3XL', 'FreeSize'];
    availableSizes.sort((a, b) {
      // Normalize comparison (handle case sensitivity if needed, usually uppercase)
      final sa = a.toUpperCase();
      final sb = b.toUpperCase();
      
      int indexA = sizeOrder.indexOf(sa);
      if (indexA == -1) indexA = sizeOrder.indexOf(a); // Try Exact
      
      int indexB = sizeOrder.indexOf(sb);
      if (indexB == -1) indexB = sizeOrder.indexOf(b);

      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1; // Known sizes come first
      if (indexB != -1) return 1;
      return a.compareTo(b); // Fallback to alphabetical
    });

    final sizesToShow = availableSizes.isNotEmpty
        ? availableSizes
        : ['S', 'M', 'L', 'XL', 'XXL'];

    return Container(
      color: const Color(0xFFFFF0F5),
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Size', _selectedSize, sizesToShow),
            _buildFilterChip('Màu sắc', _selectedColor, colorsToShow),
            _buildFilterChip('Khoảng giá', _selectedPriceRange, ['< 200k', '200k - 500k', '> 500k']),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? selectedValue, List<String> options) {
    final isSelected = selectedValue != null;
    return GestureDetector(
      onTap: () {
        _showFilterOptions(label, options, selectedValue);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD29062) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list, 
              size: 14, 
              color: isSelected ? Colors.white : Colors.grey[600]
            ),
            const SizedBox(width: 4),
            Text(
              isSelected ? selectedValue : label,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down, 
              size: 16, 
              color: isSelected ? Colors.white : Colors.grey[600]
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(String title, List<String> options, String? currentValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chọn $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (currentValue != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (title == 'Size') _selectedSize = null;
                          if (title == 'Màu sắc') _selectedColor = null;
                          if (title == 'Khoảng giá') _selectedPriceRange = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Xóa lọc', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: options.map((option) {
                  final isSelected = option == currentValue;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (title == 'Size') _selectedSize = selected ? option : null;
                        if (title == 'Màu sắc') _selectedColor = selected ? option : null;
                        if (title == 'Khoảng giá') _selectedPriceRange = selected ? option : null;
                      });
                      Navigator.pop(context);
                    },
                    selectedColor: const Color(0xFFD29062),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
                    child: UniversalImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
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

  String _removeDiacritics(String str) {
    var withDia = 'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    var withoutDia = 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }
}
