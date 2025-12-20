import 'package:do_an_quan_ao/Model/voucher_model.dart';
import 'package:do_an_quan_ao/Services/voucher_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final VoucherRepository _voucherRepo = VoucherRepository();

  void _showAddEditVoucherDialog([Voucher? voucher]) {
    final codeCtrl = TextEditingController(text: voucher?.code ?? '');
    final valueCtrl = TextEditingController(text: voucher != null ? voucher.value.toString() : '');
    final minOrderCtrl = TextEditingController(text: voucher != null ? voucher.minOrderValue.toString() : '0');
    final maxDiscountCtrl = TextEditingController(text: voucher != null ? voucher.maxDiscount.toString() : '0');
    final limitCtrl = TextEditingController(text: voucher != null ? voucher.usageLimit.toString() : '100');
    
    String type = voucher?.type ?? 'percent'; // 'percent' or 'fixed'
    
    // Date Range
    DateTime startDate = voucher?.startDate ?? DateTime.now();
    DateTime endDate = voucher?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(voucher == null ? 'Thêm Voucher' : 'Sửa Voucher'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Mã Voucher (Code)'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: type,
                            items: const [
                              DropdownMenuItem(value: 'percent', child: Text('Phần trăm (%)')),
                              DropdownMenuItem(value: 'fixed', child: Text('Số tiền (VNĐ)')),
                            ],
                            onChanged: (val) => setState(() => type = val!),
                            decoration: const InputDecoration(labelText: 'Loại'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: valueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá trị'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                        controller: minOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Đơn hàng tối thiểu')),
                    const SizedBox(height: 8),
                    if (type == 'percent')
                      TextField(
                          controller: maxDiscountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Giảm tối đa (VNĐ)')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: limitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giới hạn sử dụng')),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Thời gian áp dụng'),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          initialDateRange: DateTimeRange(start: startDate, end: endDate),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (codeCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;

                    final newVoucher = Voucher(
                      id: voucher?.id ?? '',
                      code: codeCtrl.text.toUpperCase(),
                      type: type,
                      value: double.tryParse(valueCtrl.text) ?? 0,
                      minOrderValue: double.tryParse(minOrderCtrl.text) ?? 0,
                      maxDiscount: double.tryParse(maxDiscountCtrl.text) ?? 0,
                      startDate: startDate,
                      endDate: endDate,
                      usageLimit: int.tryParse(limitCtrl.text) ?? 0,
                      usedCount: voucher?.usedCount ?? 0,
                      isActive: true,
                    );

                    if (voucher == null) {
                      await _voucherRepo.addVoucher(newVoucher);
                    } else {
                      await _voucherRepo.updateVoucher(newVoucher);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Voucher')),
      body: StreamBuilder<List<Voucher>>(
        stream: _voucherRepo.getVouchers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vouchers = snapshot.data!;
          
          if (vouchers.isEmpty) return const Center(child: Text('Chưa có voucher nào'));

          return ListView.builder(
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final v = vouchers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${v.code} (${v.type == 'percent' ? '${v.value}%' : '${NumberFormat('#,###').format(v.value)}đ'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('HSD: ${DateFormat('dd/MM/yyyy').format(v.endDate)} | SL: ${v.usedCount}/${v.usageLimit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: v.isActive, 
                        onChanged: (val) {
                          _voucherRepo.updateVoucher(
                            Voucher(
                              id: v.id,
                              code: v.code,
                              type: v.type,
                              value: v.value,
                              minOrderValue: v.minOrderValue,
                              maxDiscount: v.maxDiscount,
                              startDate: v.startDate,
                              endDate: v.endDate,
                              isActive: val,
                              usageLimit: v.usageLimit,
                              usedCount: v.usedCount,
                            )
                          );
                        }
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditVoucherDialog(v)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _voucherRepo.deleteVoucher(v.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditVoucherDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
