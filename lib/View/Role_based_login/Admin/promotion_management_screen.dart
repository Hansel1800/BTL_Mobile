import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/ViewModel/promotion_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/add_edit_banner_dialog.dart';
import 'package:intl/intl.dart';

class PromotionManagementScreen extends ConsumerStatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  ConsumerState<PromotionManagementScreen> createState() => _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends ConsumerState<PromotionManagementScreen> {
  int _selectedTab = 0; // 0: Banner, 1: Voucher
  String _voucherSearchQuery = '';
  String _voucherFilterStatus = 'Tất cả'; // 'Tất cả', 'Đang chạy', 'Sắp diễn ra', 'Đã hết hạn'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Khuyến mãi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
          _buildTabs(),
          Expanded(
            child: _selectedTab == 0 ? _buildBannerTab() : _buildVoucherTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTab == 0
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Banner',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0 ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTab == 1
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Voucher',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 1 ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BANNER TAB ---

  Widget _buildBannerTab() {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      data: (banners) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Banner slider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Hiển thị trên trang chủ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditBannerDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm banner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (banners.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có banner nào')))
              else
                ...banners.map((banner) => _buildBannerItem(banner)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildBannerItem(BannerModel banner) {
    final now = DateTime.now();
    String statusText = 'Đang chạy';
    Color statusColor = Colors.green;

    if (banner.startDate.isAfter(now)) {
      statusText = 'Sắp diễn ra';
      statusColor = Colors.orange;
    } else if (banner.endDate.isBefore(now)) {
      statusText = 'Đã kết thúc';
      statusColor = Colors.grey;
    } else if (!banner.isActive) {
      statusText = 'Tạm dừng';
      statusColor = Colors.grey;
    }

    return Container(
      key: ValueKey(banner.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, spreadRadius: 1)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: banner.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
                  'Hiển thị ở vị trí ${banner.position} • ${DateFormat('dd/MM').format(banner.startDate)} - ${DateFormat('dd/MM').format(banner.endDate)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Click: ${banner.clickCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text('Chuyển đổi: ${banner.conversionRate}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _showAddEditBannerDialog(context, banner: banner),
                      child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _deleteBanner(banner.id),
                      child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- VOUCHER TAB ---

  Widget _buildVoucherTab() {
    final vouchersAsync = ref.watch(vouchersProvider);

    return vouchersAsync.when(
      data: (vouchers) {
        // Filter logic
        List<VoucherModel> filteredVouchers = vouchers;
        final now = DateTime.now();

        if (_voucherFilterStatus != 'Tất cả') {
          filteredVouchers = filteredVouchers.where((v) {
            if (_voucherFilterStatus == 'Đang chạy') {
              return v.isActive && v.startDate.isBefore(now) && v.endDate.isAfter(now);
            } else if (_voucherFilterStatus == 'Sắp diễn ra') {
              return v.startDate.isAfter(now);
            } else if (_voucherFilterStatus == 'Đã hết hạn') {
              return v.endDate.isBefore(now);
            }
            return true;
          }).toList();
        }

        if (_voucherSearchQuery.isNotEmpty) {
          final query = _voucherSearchQuery.toLowerCase();
          filteredVouchers = filteredVouchers.where((v) {
            return v.code.toLowerCase().contains(query) || v.title.toLowerCase().contains(query);
          }).toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Áp dụng cho đơn hàng', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditVoucherDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo voucher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _voucherSearchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã, tên chiến dịch...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đang chạy'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sắp diễn ra'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã hết hạn'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filteredVouchers.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không tìm thấy voucher nào')))
              else
                ...filteredVouchers.map((voucher) => _buildVoucherItem(voucher)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Lỗi: $e')),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _voucherFilterStatus == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _voucherFilterStatus = label);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade200),
    );
  }

  Widget _buildVoucherItem(VoucherModel voucher) {
    final now = DateTime.now();
    String statusText = 'Đang chạy';
    Color statusColor = Colors.green;

    if (voucher.startDate.isAfter(now)) {
      statusText = 'Sắp diễn ra';
      statusColor = Colors.orange;
    } else if (voucher.endDate.isBefore(now)) {
      statusText = 'Đã hết hạn';
      statusColor = Colors.grey;
    } else if (!voucher.isActive) {
      statusText = 'Tạm dừng';
      statusColor = Colors.grey;
    }

    return Container(
      key: ValueKey(voucher.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                voucher.code,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
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
            voucher.description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('dd/MM').format(voucher.startDate)} - ${DateFormat('dd/MM').format(voucher.endDate)} • Toàn bộ danh mục',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã dùng: ${voucher.usageCount}/${voucher.usageLimit}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: voucher.code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã')));
                    },
                    child: const Text('Sao chép mã', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showAddEditVoucherDialog(context, voucher: voucher),
                    child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _deleteVoucher(voucher.id),
                    child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _deleteBanner(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa banner'),
        content: const Text('Bạn có chắc chắn muốn xóa banner này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(promotionControllerProvider.notifier).deleteBanner(id);
    }
  }

  Future<void> _deleteVoucher(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa voucher'),
        content: const Text('Bạn có chắc chắn muốn xóa voucher này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(promotionControllerProvider.notifier).deleteVoucher(id);
    }
  }

  void _showAddEditBannerDialog(BuildContext context, {BannerModel? banner}) {
    showDialog(
      context: context,
      builder: (context) => AddEditBannerDialog(banner: banner),
    );
  }

  void _showAddEditVoucherDialog(BuildContext context, {VoucherModel? voucher}) {
    final isEditing = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final titleController = TextEditingController(text: voucher?.title ?? '');
    final descController = TextEditingController(text: voucher?.description ?? '');
    final discountValueController = TextEditingController(text: voucher?.discountValue.toString() ?? '0');
    final minOrderController = TextEditingController(text: voucher?.minOrderValue.toString() ?? '0');
    final limitController = TextEditingController(text: voucher?.usageLimit.toString() ?? '100');
    
    String discountType = voucher?.discountType ?? 'amount'; // 'amount' or 'percent'
    DateTime startDate = voucher?.startDate ?? DateTime.now();
    DateTime endDate = voucher?.endDate ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa voucher' : 'Tạo voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Mã voucher (VD: SUMMER50)'),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên chiến dịch'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Loại giảm giá: '),
                    DropdownButton<String>(
                      value: discountType,
                      items: const [
                        DropdownMenuItem(value: 'amount', child: Text('Số tiền')),
                        DropdownMenuItem(value: 'percent', child: Text('Phần trăm')),
                      ],
                      onChanged: (val) => setState(() => discountType = val!),
                    ),
                  ],
                ),
                TextField(
                  controller: discountValueController,
                  decoration: const InputDecoration(labelText: 'Giá trị giảm'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(labelText: 'Đơn tối thiểu'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: limitController,
                  decoration: const InputDecoration(labelText: 'Giới hạn sử dụng'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => startDate = date);
                        },
                        child: Text('Bắt đầu: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => endDate = date);
                        },
                        child: Text('Kết thúc: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final newVoucher = VoucherModel(
                  id: isEditing ? voucher.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  code: codeController.text.toUpperCase(),
                  title: titleController.text,
                  description: descController.text,
                  discountType: discountType,
                  discountValue: double.tryParse(discountValueController.text) ?? 0,
                  minOrderValue: double.tryParse(minOrderController.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                  usageLimit: int.tryParse(limitController.text) ?? 100,
                  usageCount: voucher?.usageCount ?? 0,
                  isActive: true,
                );

                if (isEditing) {
                  await ref.read(promotionControllerProvider.notifier).updateVoucher(newVoucher);
                } else {
                  await ref.read(promotionControllerProvider.notifier).addVoucher(newVoucher);
                }
                
                if (context.mounted) {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Cập nhật' : 'Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}
