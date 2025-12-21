import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/ViewModel/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  final bool isReadOnly;

  const AddEditProductScreen({super.key, this.product, this.isReadOnly = false});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  late TextEditingController _stockController;
  late TextEditingController _warningStockController;
  late TextEditingController _imageUrlController;
  String? _imageUrl;
  List<String>? _selectedColors = [];
  List<String>? _selectedSizes = [];
  String _selectedGender = '';
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product != null ? 'TEE-BASIC-01' : ''); // Mock SKU
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _selectedGender = widget.product?.gender ?? '';
    
    // Fix: Safely handle price initialization
    String priceText = '';
    if (widget.product != null) {
      priceText = widget.product!.price.toStringAsFixed(0);
    }
    _priceController = TextEditingController(text: priceText);
    

    
    // Fix: Safely handle stock initialization
    String stockText = '';
    if (widget.product != null) {
      stockText = widget.product!.stock.toString();
    }
    _stockController = TextEditingController(text: stockText);
    
    _warningStockController = TextEditingController(); // Mock Warning Stock
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _imageUrl = widget.product?.imageUrl;
    
    // Fix: Safely handle colors initialization
    try {
      _selectedColors = List.from(widget.product?.colors ?? []);
    } catch (e) {
      _selectedColors = [];
    }
    
    // Fix: Safely handle sizes initialization
    try {
      _selectedSizes = List.from(widget.product?.sizes ?? []);
    } catch (e) {
      _selectedSizes = [];
    }

    _variants = List.from(widget.product?.variants ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();

    _stockController.dispose();
    _warningStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    // 1. Validate Form Fields (Name, required text fields)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Custom Validations

    // Description validation
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }

    // Category validation
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục'), backgroundColor: Colors.red),
      );
      return;
    }

    // Gender validation
    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giới tính'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Image validation
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập URL hình ảnh'), backgroundColor: Colors.red),
      );
      return;
    }

    // Sizes validation
    if (_selectedSizes == null || _selectedSizes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một size'), backgroundColor: Colors.red),
      );
      return;
    }

    // Colors validation
    if (_selectedColors == null || _selectedColors!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một màu sắc'), backgroundColor: Colors.red),
      );
      return;
    }

    // Warning stock validation
    final stock = int.tryParse(_stockController.text) ?? 0;
    final warningStock = int.tryParse(_warningStockController.text) ?? 0;
    
    if (warningStock >= stock && stock > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảnh báo tồn kho phải nhỏ hơn số lượng tồn kho'), backgroundColor: Colors.red),
      );
      return;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text,
      category: _categoryController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      imageUrl: _imageUrl ?? '',
      stock: stock,
      colors: _selectedColors ?? [],
      sizes: _selectedSizes ?? [],
      gender: _selectedGender,
      variants: _variants,
      description: _descriptionController.text,
    );

    try {
      if (widget.product == null) {
        await ref.read(productControllerProvider.notifier).addProduct(product);
      } else {
        await ref.read(productControllerProvider.notifier).updateProduct(product);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu sản phẩm thành công'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSizePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SizeConfigSheet(
          selectedSizes: _selectedSizes ?? <String>[],
          onSizesChanged: (sizes) {
            setState(() {
              _selectedSizes = sizes;
            });
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.isReadOnly 
              ? 'Chi tiết sản phẩm' 
              : (widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.more_horiz),
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
                    const Text(
                      'Thông tin cơ bản',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nhập tên, danh mục và mô tả sản phẩm',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _buildBasicInfoCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Giá & tồn kho',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceStockCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Phiên bản (size / màu)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Tùy chọn, có thể thêm sau',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _buildVariantsCard(),
                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isReadOnly) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Tên sản phẩm', 'Ví dụ: Áo thun basic cổ tròn', _nameController, readOnly: widget.isReadOnly),
          const SizedBox(height: 16),
          _buildTextField('SKU', 'Ví dụ: TEE-BASIC-01', _skuController, readOnly: widget.isReadOnly),
          const SizedBox(height: 16),
          // Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: widget.isReadOnly ? null : _showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _categoryController.text.isEmpty ? 'Chọn danh mục' : _categoryController.text,
                        style: TextStyle(
                          color: _categoryController.text.isEmpty ? Colors.grey : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      if (!widget.isReadOnly)
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gender Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender.isEmpty ? null : _selectedGender,
                    hint: const Text('Chọn giới tính'),
                    isExpanded: true,
                    // Disable dropdown if readOnly
                    onChanged: widget.isReadOnly ? null : (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      }
                    },
                    items: ['Nam', 'Nữ', 'Unisex'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Mô tả', 'Mô tả chất liệu, form dáng, hướng dẫn bảo quản...', _descriptionController, maxLines: 3, readOnly: widget.isReadOnly),
          const SizedBox(height: 16),
          if (!widget.isReadOnly)
             _buildTextField('Image URL', 'Điền đường dẫn ảnh', _imageUrlController, onChanged: (val) {
               setState(() {
                 _imageUrl = val.trim();
               });
             }),
           if (_imageUrl != null && _imageUrl!.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: SizedBox(
                 height: 100,
                 child: _buildImagePreview(_imageUrl!),
               ),
             ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _CategoryPickerSheet(
          onCategorySelected: (category) {
            setState(() {
              _categoryController.text = category;
            });
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, String subtitle, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _categoryController.text = title;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (_categoryController.text == title)
              const Icon(Icons.radio_button_checked, color: Colors.blue)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStockCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField('Giá bán', '₫ 0', _priceController, isNumber: true, suffix: 'Đã bao gồm thuế', readOnly: widget.isReadOnly),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Tồn kho', 'Số lượng hiện có', _stockController, isNumber: true, readOnly: widget.isReadOnly),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Tồn cảnh báo', 'Đặt tồn cảnh báo', _warningStockController, isNumber: true, readOnly: widget.isReadOnly),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Đặt tồn cảnh báo để hiển thị "Sắp hết hàng".',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.isReadOnly ? null : _showSizePicker,
                child: _buildChip('Size', true),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.isReadOnly ? null : _showColorPicker,
                child: _buildChip('Màu sắc', _selectedColors?.isNotEmpty ?? false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedSizes != null && _selectedSizes!.isNotEmpty) ...[
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: _selectedSizes!.map((size) => Chip(
                 label: Text('Size $size'),
                 onDeleted: widget.isReadOnly ? null : () {
                   setState(() {
                     _selectedSizes!.remove(size);
                   });
                 },
                 backgroundColor: Colors.blue.shade50,
                 labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                 deleteIconColor: Colors.blue,
               )).toList(),
             ),
             const SizedBox(height: 16),
          ],
          if (_selectedColors != null && _selectedColors!.isNotEmpty) ...[
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: _selectedColors!.map((color) => Chip(
                 label: Text(color),
                 onDeleted: widget.isReadOnly ? null : () {
                   setState(() {
                     _selectedColors!.remove(color);
                   });
                 },
               )).toList(),
             ),
             const SizedBox(height: 16),
          ],
          // Generate variant combinations dynamically
          if (_selectedSizes != null && _selectedSizes!.isNotEmpty && 
              _selectedColors != null && _selectedColors!.isNotEmpty) ...[
            ...() {
              List<Widget> variantWidgets = [];
              for (int i = 0; i < _selectedSizes!.length; i++) {
                for (int j = 0; j < _selectedColors!.length; j++) {
                  if (variantWidgets.isNotEmpty) {
                    variantWidgets.add(const Divider(height: 24));
                  }
                  
                  final size = _selectedSizes![i];
                  final color = _selectedColors![j];
                  
                  // Find existing variant or create temporary default
                  ProductVariant? existingVariant;
                  try {
                    existingVariant = _variants.firstWhere(
                      (v) => v.size == size && v.color == color
                    );
                  } catch (e) {
                    existingVariant = null;
                  }

                  final displayPrice = existingVariant?.price ?? double.tryParse(_priceController.text) ?? 0;
                  final displayStock = existingVariant?.stock ?? int.tryParse(_stockController.text) ?? 0;

                  variantWidgets.add(_buildVariantItem(
                    size, 
                    color,
                    'Giá: ₫${displayPrice.toStringAsFixed(0)} • Tồn: $displayStock',
                    existingVariant
                  ));
                }
              }
              return variantWidgets;
            }(),
          ],
        ],
      ),
    );
  }

  

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _ColorPickerSheet(
          selectedColors: _selectedColors ?? <String>[],
          onColorsChanged: (colors) {
            setState(() {
              _selectedColors = colors;
            });
          },
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVariantItem(String size, String color, String details, ProductVariant? variant) {
    return InkWell(
      onTap: widget.isReadOnly ? null : () {
        _showEditVariantDialog(size, color, variant);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size $size • $color', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          if (!widget.isReadOnly)
            const Icon(Icons.edit, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  void _showEditVariantDialog(String size, String color, ProductVariant? currentVariant) {
    final priceCtrl = TextEditingController(text: (currentVariant?.price ?? double.tryParse(_priceController.text) ?? 0).toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: (currentVariant?.stock ?? int.tryParse(_stockController.text) ?? 0).toString());
    final warningStockCtrl = TextEditingController(text: (currentVariant?.warningStock ?? int.tryParse(_warningStockController.text) ?? 0).toString());
    final imageUrlCtrl = TextEditingController(text: currentVariant?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Size: $size - Màu: $color'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                     controller: priceCtrl,
                     keyboardType: TextInputType.number,
                     decoration: const InputDecoration(labelText: 'Giá riêng'),
                   ),
                   TextField(
                     controller: stockCtrl,
                     keyboardType: TextInputType.number,
                     decoration: const InputDecoration(labelText: 'Tồn kho riêng'),
                   ),
                   TextField(
                     controller: warningStockCtrl,
                     keyboardType: TextInputType.number,
                     decoration: const InputDecoration(labelText: 'Cảnh báo tồn kho'),
                   ),
                   TextField(
                     controller: imageUrlCtrl,
                     decoration: const InputDecoration(labelText: 'URL Ảnh riêng (tùy chọn)'),
                     onChanged: (_) {
                        setState(() {});
                     },
                   ),
                   if (imageUrlCtrl.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 100, 
                          child: _buildImagePreview(imageUrlCtrl.text),
                        ),
                      )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  final newPrice = double.tryParse(priceCtrl.text) ?? 0;
                  final newStock = int.tryParse(stockCtrl.text) ?? 0;
                  final newWarningStock = int.tryParse(warningStockCtrl.text) ?? 0;
                  final newImageUrl = imageUrlCtrl.text;
                  
                  if (newWarningStock >= newStock && newStock > 0) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cảnh báo tồn kho phải nhỏ hơn tồn kho'), backgroundColor: Colors.red),
                     );
                     return;
                  }

                  // Update parent state
                  this.setState(() {
                    // Remove existing if present
                    _variants.removeWhere((v) => v.size == size && v.color == color);
                    // Add new/updated
                    _variants.add(ProductVariant(
                      size: size, 
                      color: color, 
                      price: newPrice, 
                      stock: newStock,
                      warningStock: newWarningStock,
                      imageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                    ));
                  });
                  Navigator.pop(context);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildImagePreview(String url) {
    if (url.trim().isEmpty) return const SizedBox();
    return UniversalImage(
      imageUrl: url.trim(),
      fit: BoxFit.contain,
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Tooltip(
      message: error.toString(),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey),
          Text('Lỗi ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {
    bool isNumber = false,
    bool isDropdown = false,
    int maxLines = 1,
    String? suffix,
    Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (suffix != null)
              Text(suffix, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          enabled: !readOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          validator: (value) {
            if (readOnly) return null;
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập ${label.toLowerCase()}';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: isDropdown ? const Icon(Icons.keyboard_arrow_down) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Lưu',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final Function(String) onCategorySelected;

  const _CategoryPickerSheet({
    required this.onCategorySelected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCategories = [];
  
  final List<Map<String, String>> _allCategories = [
    {'title': 'Áo thun', 'subtitle': 'Áo phông, áo thun basic', 'section': 'suggested'},
    {'title': 'Sơ mi', 'subtitle': 'Sơ mi tay dài, tay ngắn', 'section': 'suggested'},
    {'title': 'Quần', 'subtitle': 'Nam / Nữ', 'section': 'other'},
    {'title': 'Quần short', 'subtitle': 'Short kaki, short jean', 'section': 'other'},
    {'title': 'Đầm / Váy', 'subtitle': 'Váy liền, chân váy', 'section': 'other'},
    {'title': 'Phụ kiện', 'subtitle': 'Nón, dây lưng, túi xách', 'section': 'other'},
    {'title': 'Set đồ', 'subtitle': 'Set đồ bộ ', 'section': 'other'},
  
  ];

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(_allCategories);
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = _removeDiacritics(_searchController.text.toLowerCase());
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_allCategories);
      } else {
        _filteredCategories = _allCategories.where((category) {
          final title = _removeDiacritics(category['title']!.toLowerCase());
          final subtitle = _removeDiacritics(category['subtitle']!.toLowerCase());
          
          // Tìm kiếm theo tên đầy đủ
          if (title.contains(query) || subtitle.contains(query)) {
            return true;
          }
          
          // Tìm kiếm theo chữ cái đầu (ví dụ: "at" -> "Áo thun")
          final words = category['title']!.split(' ');
          final firstLetters = words.map((word) {
            if (word.isEmpty) return '';
            return _removeDiacritics(word[0].toLowerCase());
          }).join('');
          
          if (firstLetters.contains(query)) {
            return true;
          }
          
          return false;
        }).toList();
      }
    });
  }

  String _removeDiacritics(String str) {
    const withDiacritics = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final suggestedCategories = _filteredCategories.where((c) => c['section'] == 'suggested').toList();
    final otherCategories = _filteredCategories.where((c) => c['section'] == 'other').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left),
                  const Text(
                    'Chọn danh mục',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm danh mục',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (suggestedCategories.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Gợi ý', style: TextStyle(color: Colors.grey)),
                    ),
                    ...suggestedCategories.map((category) => _buildCategoryItem(category)),
                  ],
                  if (otherCategories.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Danh mục khác', style: TextStyle(color: Colors.grey)),
                    ),
                    ...otherCategories.map((category) => _buildCategoryItem(category)),
                  ],
                  if (_filteredCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Không tìm thấy danh mục phù hợp',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Xong',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, String> category) {
    return InkWell(
      onTap: () {
        widget.onCategorySelected(category['title']!);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['title']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['subtitle']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatefulWidget {
  final List<String>? selectedColors;
  final Function(List<String>) onColorsChanged;

  const _ColorPickerSheet({
    required this.selectedColors,
    required this.onColorsChanged,
  });

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late List<String> _currentSelectedColors;
  final TextEditingController _customColorController = TextEditingController();
  List<Map<String, String>> _filteredSuggestedColors = [];

  final List<Map<String, String>> _suggestedColors = [
    {'name': 'Trắng', 'en': 'White'},
    {'name': 'Đen', 'en': 'Black'},
    {'name': 'Xám', 'en': 'Gray'},
    {'name': 'Xanh navy', 'en': 'Navy'},
    {'name': 'Be', 'en': 'Beige'},
  ];

  @override
  void initState() {
    super.initState();
    _currentSelectedColors = List<String>.from(widget.selectedColors ?? <String>[]);
    _filteredSuggestedColors = List<Map<String, String>>.from(_suggestedColors);
    _customColorController.addListener(_filterColors);
  }

  @override
  void dispose() {
    _customColorController.removeListener(_filterColors);
    _customColorController.dispose();
    super.dispose();
  }

  void _filterColors() {
    final query = _removeDiacritics(_customColorController.text.toLowerCase());
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestedColors = List<Map<String, String>>.from(_suggestedColors);
      } else {
        _filteredSuggestedColors = _suggestedColors.where((color) {
          final name = _removeDiacritics(color['name']!.toLowerCase());
          final en = color['en']!.toLowerCase();
          return name.contains(query) || en.contains(query);
        }).toList();
      }
    });
  }

  String _removeDiacritics(String str) {
    const withDiacritics = 'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  void _toggleColor(String color) {
    setState(() {
      if (_currentSelectedColors.contains(color)) {
        _currentSelectedColors.remove(color);
      } else {
        if (_currentSelectedColors.length < 3) {
          _currentSelectedColors.add(color);
          _customColorController.clear(); // Clear search after selecting
        }
      }
    });
  }

  void _addCustomColor() {
    final color = _customColorController.text.trim();
    if (color.isNotEmpty && !_currentSelectedColors.contains(color)) {
      setState(() {
        if (_currentSelectedColors.length < 3) {
          _currentSelectedColors.add(color);
        }
      });
      _customColorController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left),
                  const Text(
                    'Màu sắc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text(
                    'Chọn màu cho sản phẩm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Áp dụng cho tất cả phiên bản size',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Màu đã chọn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentSelectedColors.map((color) => Chip(
                            label: Text(color),
                            onDeleted: () => _toggleColor(color),
                            backgroundColor: Colors.white,
                          )).toList(),
                        ),
                        const SizedBox(height: 8),
                        const Text('Chọn tối đa 3 màu cho sản phẩm.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customColorController,
                                onSubmitted: (_) => _addCustomColor(),
                                decoration: InputDecoration(
                                  hintText: 'Nhập tên màu (ví dụ: Be, Xám nhạt)',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  suffixIcon: _customColorController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.grey),
                                          onPressed: () {
                                            _customColorController.clear();
                                            // _filterColors will be called by listener
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gợi ý màu phổ biến',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Chọn nhanh từ danh sách bên dưới',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ..._filteredSuggestedColors.map((color) {
                    final isSelected = _currentSelectedColors.contains(color['name']);
                    return CheckboxListTile(
                      title: Text(color['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(color['en']!, style: const TextStyle(color: Colors.grey)),
                      value: isSelected,
                      onChanged: (val) => _toggleColor(color['name']!),
                      secondary: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getColorFromName(color['en']!),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onColorsChanged(_currentSelectedColors);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'gray': return Colors.grey;
      case 'navy': return const Color(0xFF000080);
      case 'beige': return const Color(0xFFF5F5DC);
      default: return Colors.transparent;
    }
  }
}

class _SizeConfigSheet extends StatefulWidget {
  final List<String>? selectedSizes;
  final Function(List<String>) onSizesChanged;

  const _SizeConfigSheet({
    required this.selectedSizes,
    required this.onSizesChanged,
  });

  @override
  State<_SizeConfigSheet> createState() => _SizeConfigSheetState();
}

class _SizeConfigSheetState extends State<_SizeConfigSheet> {
  late List<String> _currentSelectedSizes;
  final List<String> _allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _currentSelectedSizes = List<String>.from(widget.selectedSizes ?? <String>[]);
  }

  void _toggleSize(String size) {
    setState(() {
      if (_currentSelectedSizes.contains(size)) {
        _currentSelectedSizes.remove(size);
      } else {
        _currentSelectedSizes.add(size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left),
                  const Text(
                    'Cấu hình size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text(
                    'Chọn size áp dụng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Thiết lập giá và tồn kho cho từng size',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Danh sách size', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Chọn các size bạn bán', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _allSizes.map((size) {
                            final isSelected = _currentSelectedSizes.contains(size);
                            return GestureDetector(
                              onTap: () => _toggleSize(size),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Giá & tồn kho theo size',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Mặc định dùng giá chung nếu để trống',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ..._currentSelectedSizes.map((size) => _buildSizeConfigItem(size)).toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSizesChanged(_currentSelectedSizes);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Lưu size',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSizeConfigItem(String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Size $size', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Giá tùy chỉnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('Giá', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('₫', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                    const SizedBox(width: 4),
                    const Text('209.000', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Tồn', style: TextStyle(color: Colors.grey)),
              ),
              const Expanded(
                flex: 1,
                child: Text('32', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
