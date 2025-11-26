import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/ViewModel/promotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddEditBannerDialog extends ConsumerStatefulWidget {
  final BannerModel? banner;

  const AddEditBannerDialog({super.key, this.banner});

  @override
  ConsumerState<AddEditBannerDialog> createState() => _AddEditBannerDialogState();
}

class _AddEditBannerDialogState extends ConsumerState<AddEditBannerDialog> {
  late TextEditingController titleController;
  late TextEditingController imageUrlController;
  late TextEditingController positionController;
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.banner?.title ?? '');
    imageUrlController = TextEditingController(text: widget.banner?.imageUrl ?? '');
    positionController = TextEditingController(text: widget.banner?.position.toString() ?? '1');
    startDate = widget.banner?.startDate ?? DateTime.now();
    endDate = widget.banner?.endDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    titleController.dispose();
    imageUrlController.dispose();
    positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.banner != null;

    return AlertDialog(
      title: Text(isEditing ? 'Chỉnh sửa banner' : 'Thêm banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(labelText: 'URL Hình ảnh'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Vị trí hiển thị'),
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
            final newBanner = BannerModel(
              id: isEditing ? widget.banner!.id : DateTime.now().millisecondsSinceEpoch.toString(),
              title: titleController.text,
              imageUrl: imageUrlController.text,
              startDate: startDate,
              endDate: endDate,
              position: int.tryParse(positionController.text) ?? 1,
              isActive: true,
              clickCount: widget.banner?.clickCount ?? 0,
              conversionRate: widget.banner?.conversionRate ?? 0.0,
            );

            if (isEditing) {
              await ref.read(promotionControllerProvider.notifier).updateBanner(newBanner);
            } else {
              await ref.read(promotionControllerProvider.notifier).addBanner(newBanner);
            }

            if (context.mounted) {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }
}

