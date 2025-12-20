import 'package:flutter/material.dart';

class SuccessDialog extends StatefulWidget {
  final String title;
  final VoidCallback? onDismiss;

  const SuccessDialog({super.key, required this.title, this.onDismiss});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    
    // Auto dismiss or just wait for user? "hiển thị đã lưu thành công" often implies auto-close or simple OK.
    // User requested "dialog display... with animation". Usually these auto-close.
    Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
            Navigator.of(context).pop();
            if (widget.onDismiss != null) widget.onDismiss!();
        }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
