import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileDetailScreen extends StatefulWidget {
  const UserProfileDetailScreen({super.key});

  @override
  State<UserProfileDetailScreen> createState() => _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedCity;
  List<String> _selectedPreferences = [];
  String? _avatarUrl;

  // Mock Data
  final List<String> _cities = ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ', 'Hải Phòng'];
  final List<String> _preferencesOptions = ['Streetwear', 'Đơn giản', 'Công sở', 'Phụ kiện', 'Thể thao'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['fullName'] ?? '';
            _emailController.text = data['email'] ?? _currentUser!.email ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _dobController.text = data['dob'] ?? '';
            _addressController.text = data['address'] ?? '';
            _selectedGender = data['gender'];
            _selectedCity = data['city'];
            _selectedPreferences = List<String>.from(data['preferences'] ?? []);
            _avatarUrl = data['avatarUrl'];
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user details: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
          'fullName': _nameController.text,
          'phoneNumber': _phoneController.text,
          'dob': _dobController.text,
          'address': _addressController.text,
          'gender': _selectedGender,
          'city': _selectedCity,
          'preferences': _selectedPreferences,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.grey),
                                    )
                                  : const Icon(Icons.person, size: 60, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'Người dùng',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thành viên từ 2023',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildSectionTitle('Họ và tên'),
                    _buildTextField(_nameController, 'Nhập họ và tên'),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle('Email'),
                    _buildTextField(_emailController, 'Email', readOnly: true, suffixText: 'Đã xác minh'),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Số điện thoại'),
                    _buildTextField(_phoneController, 'Nhập số điện thoại', suffixText: 'Thay đổi'),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Ngày sinh'),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(_dobController, 'dd/mm/yyyy', suffixIcon: Icons.calendar_today),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Giới tính'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Nam', 'Nữ', 'Khác', 'Không tiết lộ'].map((gender) {
                        final isSelected = _selectedGender == gender;
                        return ChoiceChip(
                          label: Text(gender),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGender = selected ? gender : null;
                            });
                          },
                          selectedColor: const Color(0xFFD29062),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Tỉnh/Thành phố'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          hint: const Text('Chọn tỉnh/thành phố'),
                          isExpanded: true,
                          items: _cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Địa chỉ giao hàng'),
                    _buildTextField(_addressController, 'Nhập số nhà, tên đường...'),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Sở thích mua sắm'),
                        const Text('Tùy chỉnh gợi ý cho bạn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferencesOptions.map((pref) {
                        final isSelected = _selectedPreferences.contains(pref);
                        return FilterChip(
                          label: Text(pref),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(pref);
                              } else {
                                _selectedPreferences.remove(pref);
                              }
                            });
                          },
                          selectedColor: const Color(0xFFD29062),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          checkmarkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide.none,
                      backgroundColor: Colors.grey[200],
                    ),
                    child: const Text('Hủy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD29062),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {
    bool readOnly = false,
    String? suffixText,
    IconData? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixText: suffixText,
          suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black54) : null,
        ),
      ),
    );
  }
}
