import 'dart:math' as math;
import 'package:do_an_quan_ao/View/Role_based_login/User/Cart/user_cart_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Wishlist/user_wishlist_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Home/user_home_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_profile_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Category/user_category_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserMainScreen extends ConsumerStatefulWidget {
  const UserMainScreen({super.key});

  @override
  ConsumerState<UserMainScreen> createState() => UserMainScreenState();
}

class UserMainScreenState extends ConsumerState<UserMainScreen> {
  int _currentIndex = 0;

  void navigateToTab(int index) {
      setState(() {
          _currentIndex = index;
      });
  }

  List<Widget> get _screens => [
    const UserHomeScreen(),
    const UserCategoryScreen(),
    const UserCartScreen(),
    const UserWishlistScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for notch transparency
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'cartable', // Avoid hero tag conflict
          onPressed: () {
            setState(() {
              _currentIndex = 2;
            });
          },
          backgroundColor: _currentIndex == 2 ? const Color(0xFFA07048) : const Color(0xFFD29062), // Darken if selected
          elevation: 4,
          shape: const CircleBorder(),
          child: Icon(Icons.shopping_bag_outlined, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CustomNotchedRectangle(),
        notchMargin: 8, // Increased margin for better look
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 20,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Trang chủ', 0),
              _buildNavItem(Icons.grid_view_outlined, Icons.grid_view, 'Danh mục', 1),
              
              const SizedBox(width: 48), // Spacer for FAB

              _buildNavItem(Icons.favorite_border, Icons.favorite, 'Yêu thích', 3),
              _buildNavItem(Icons.person_outline, Icons.person, 'Hồ sơ', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFFD29062) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFD29062) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomNotchedRectangle extends NotchedShape {
  const CustomNotchedRectangle();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRect(host);
    }

    // Add a margin to the notch radius to create a visible gap
    const double margin = 12.0;
    final double notchRadius = guest.width / 2.0 + margin;

    const double s1 = 25.0; // Horizontal smoothing distance
    const double s2 = 10.0; // Vertical smoothing/depth

    final double r = notchRadius;
    final double a = -1.0 * r - s2;
    final double b = host.top - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final List<Offset> p = List.filled(6, Offset.zero);

    // p0, p1, and p2 are the control points for segment A.
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    // p3, p4, and p5 are the control points for segment B, which is a mirror of segment A.
    p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

    // translate all points back to the absolute coordinate system.
    for (int i = 0; i < p.length; i += 1) {
      p[i] += guest.center;
    }

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(
        p[3],
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}
