import 'package:do_an_quan_ao/View/Role_based_login/User/Category/user_category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserCategoryScreen extends ConsumerStatefulWidget {
  const UserCategoryScreen({super.key});

  @override
  ConsumerState<UserCategoryScreen> createState() => _UserCategoryScreenState();
}



class _UserCategoryScreenState extends ConsumerState<UserCategoryScreen> {
  String _selectedGender = 'Nam';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh mục',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tối giản nhưng đầy đủ lựa chọn',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // "Theo giới tính" Section
              const Text(
                'Theo giới tính',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildGenderCard('Nam', Icons.person_outline),
                    const SizedBox(width: 12),
                    _buildGenderCard('Nữ', Icons.person_2_outlined),
                    const SizedBox(width: 12),
                    _buildGenderCard('Unisex', Icons.people_outline),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // "Danh mục chính" Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh mục chính',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Đang xem: $_selectedGender',
                    style: const TextStyle(color: Color(0xFFD29062), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Quần áo & phụ kiện (không bao gồm giày)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              
              // Category List
              _buildCategoryItem(Icons.checkroom, 'Áo', 'Áo thun, sơ mi, polo, sweater', '90+ sp'),
              _buildCategoryItem(Icons.pause_presentation, 'Quần', 'Quần tây, jeans, ống rộng, short', '80+ sp'),
              _buildCategoryItem(Icons.grid_view, 'Váy & đầm', 'Váy chữ A, midi, maxi, đầm suông', '60+ sp'),
              _buildCategoryItem(Icons.layers, 'Áo khoác', 'Jacket, blazer, trench, hoodie', '40+ sp'),
              _buildCategoryItem(Icons.auto_awesome, 'Set đồ', 'Bộ phối sẵn theo phong cách', '30+ sp'),
              _buildCategoryItem(Icons.watch, 'Phụ kiện', 'Túi, thắt lưng, mũ, khăn, trang sức', '70+ sp'),
              
              const SizedBox(height: 80), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String title, IconData icon) {
    final isSelected = _selectedGender == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD29062) : const Color(0xFFEBE4DB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD29062).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: isSelected ? Colors.white : Colors.black87
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: isSelected ? Colors.white70 : Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, String subtitle, String count) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserCategoryDetailScreen(
              categoryName: title,
              categorySubtitle: subtitle,
              gender: _selectedGender,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EAE4), // Light beige background for icon
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              count,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
