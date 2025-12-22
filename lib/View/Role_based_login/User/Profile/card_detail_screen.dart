import 'dart:math';
import 'package:do_an_quan_ao/Model/payment_method_model.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardDetailScreen extends StatefulWidget {
  final PaymentMethod paymentMethod;

  const CardDetailScreen({super.key, required this.paymentMethod});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  bool _isEditing = false;
  bool _showCVV = false;
  
  late TextEditingController _numberController;
  late TextEditingController _holderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    
    final d = widget.paymentMethod.details;
    _numberController = TextEditingController(text: d['cardNumber'] ?? '');
    _holderController = TextEditingController(text: d['holder'] ?? '');
    _expiryController = TextEditingController(text: d['expiry'] ?? '');
    _cvvController = TextEditingController(text: d['cvv'] ?? '');
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }



  void _toggleCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    // Extract details safely
    final details = widget.paymentMethod.details;
    final cardNumber = details['cardNumber'] ?? '0000 0000 0000 0000';
    final cardHolder = details['holder'] ?? 'Unknown';
    final expiryDate = details['expiry'] ?? 'MM/YY';
    final cvv = details['cvv'] ?? '***';


    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thẻ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F2027),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // IconButton(
          //   icon: Icon(_isEditing ? Icons.save : Icons.edit),
          //   onPressed: () {
          //      if (_isEditing) {
          //        _saveChanges();
          //      } else {
          //        setState(() => _isEditing = true);
          //      }
          //   },
          // )
        ],
      ),
      body: SingleChildScrollView( 
       child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Full height gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _toggleCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isBack = angle >= pi / 2;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: isBack
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _buildCardBack(cvv),
                          )
                        : _buildCardFront(cardNumber, cardHolder, expiryDate),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 40),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Column(
                 children: [
                    const Text('CHỈNH SỬA THÔNG TIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 20),
                    _buildEditField('Số thẻ', _numberController, icon: Icons.credit_card, 
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16), CardNumberFormatter()]),
                    const SizedBox(height: 16),
                    _buildEditField('Chủ thẻ', _holderController, icon: Icons.person, isUpperCase: true,
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildEditField('Hết hạn (MM/YY)', _expiryController, icon: Icons.calendar_today,
                            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), DateFormatter()])),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEditField('CVV', _cvvController, icon: Icons.lock, 
                            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)])),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C6D), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _saveChanges,
                            child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                        ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: _deleteCard,
                        child: const Text('Xóa thẻ này', style: TextStyle(color: Colors.redAccent, fontSize: 14))
                    ),
                    const SizedBox(height: 40),
                 ],
               )
             ),
          ],
        ),
       ),
      ),
    );
  }
  
  Widget _buildEditField(String label, TextEditingController ctrl, {IconData? icon, bool isUpperCase = false, List<TextInputFormatter>? formatters}) {
      return TextField(
        controller: ctrl,
        inputFormatters: formatters,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        onChanged: (val) {
             if (isUpperCase) {
                final upper = val.toUpperCase();
                if (ctrl.text != upper) {
                    ctrl.value = ctrl.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                }
             }
             setState(() {}); // Refresh visual card
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _deleteCard() async {
      try {
         final user = FirebaseAuth.instance.currentUser;
         if (user != null) {
              await UserRepository().deletePaymentMethod(user.uid, widget.paymentMethod.id);
              if (mounted) {
                  showDialog(
                     context: context,
                     builder: (context) => SuccessDialog(
                         title: 'Đã xóa thẻ!',
                         onDismiss: () {
                             // Wait a bit or let user click?
                             // Typically we automatically go back
                         },
                     )
                  );
                  
                  // Wait for dialog to be visible then close screen
                  // SuccessDialog auto-pops in 2s. We should listen to pop.
                  // Or just:
                  await Future.delayed(const Duration(seconds: 2));
                  if(mounted) Navigator.pop(context);
              }
         }
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  Future<void> _saveChanges() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
           final repo = UserRepository();
           // Update this specific card
           // Since we don't have a direct "updateCard" in repo that targets ID easily without fetching,
           // we will delete old and add new. This is a hack but works for this level.
           // Ideally: repo.updatePaymentMethod(uid, newMethod)
           
           // Validation
           if (_numberController.text.replaceAll(' ', '').length != 16) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số thẻ không hợp lệ')));
              return;
           }
           if (_holderController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên chủ thẻ')));
              return;
           }
            // Expiry Check
           if (_expiryController.text.length == 5) {
              final parts = _expiryController.text.split('/');
              if (parts.length == 2) {
                final month = int.tryParse(parts[0]) ?? 0;
                final year = int.tryParse(parts[1]) ?? 0;
                 if (month < 1 || month > 12) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tháng không hợp lệ')));
                    return;
                 }
                 final now = DateTime.now();
                 final expiryDate = DateTime(2000 + year, month);
                 if (expiryDate.isBefore(DateTime(now.year, now.month + 1))) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thẻ hết hạn hoặc sắp hết hạn')));
                    return;
                 }
              }
           } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày hết hạn sai định dạng')));
               return;
           }

           final newMethod = PaymentMethod(
             id: widget.paymentMethod.id, 
             type: widget.paymentMethod.type,
             title: 'Visa ending ${_numberController.text.replaceAll(' ', '').length >= 4 ? _numberController.text.replaceAll(' ', '').substring(_numberController.text.replaceAll(' ', '').length - 4) : '????'}',
             subtitle: _holderController.text.toUpperCase(),
             details: {
               'cardNumber': _numberController.text, // Store with spaces as formatted
               'holder': _holderController.text, 
               'expiry': _expiryController.text,
               'cvv': _cvvController.text,
             },
             isDefault: widget.paymentMethod.isDefault,
           );

           await repo.updatePaymentMethod(user.uid, newMethod);
           
           setState(() => _isEditing = false);
           if (mounted) {
             showDialog(
                 context: context,
                 builder: (context) => SuccessDialog(
                     title: 'Đã lưu thay đổi!',
                     onDismiss: () => Navigator.pop(context),
                 )
             );
           }
        }
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
  }


  Widget _buildCardFront(String cardNumber, String cardHolder, String expiryDate) {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1E32), Color(0xFF203A43)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -50, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
          Positioned(bottom: -30, left: -30, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MasterCard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(
                      height: 30,
                      child: Stack(
                         children: [
                           Container(width: 30, height: 30, decoration:  BoxDecoration(color: Colors.red.withOpacity(0.8), shape: BoxShape.circle)),
                           Positioned(left: 18, child: Container(width: 30, height: 30, decoration:  BoxDecoration(color: Colors.orange.withOpacity(0.8), shape: BoxShape.circle))),
                         ],
                      ),
                    )
                  ],
                ),
                
                Container(
                  width: 40, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.amber[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.wifi, size: 20, color: Colors.black54),
                ),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _numberController.text.isEmpty ? cardNumber : _numberController.text,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Courier', letterSpacing: 2, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                  ),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Card Holder', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text((_holderController.text.isEmpty ? cardHolder : _holderController.text).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expires', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(_expiryController.text.isEmpty ? expiryDate : _expiryController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardBack(String cvv) {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1c2e4a),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(height: 40, width: double.infinity, color: Colors.black),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    color: Colors.grey[300],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(_showCVV ? (_cvvController.text.isEmpty ? cvv : _cvvController.text) : '***', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCVV = !_showCVV;
                    });
                  },
                  child: Icon(
                    _showCVV ? Icons.visibility : Icons.visibility_off, 
                    color: Colors.white, 
                    size: 20
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [Text('CVV', style: TextStyle(color: Colors.white, fontSize: 10))],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                  Text('Service Hotline: 1800-123-456', style: TextStyle(color: Colors.grey[500], fontSize: 10))
               ],
            ),
          )
        ],
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var inputText = newValue.text.replaceAll(' ', '');
    if (newValue.selection.baseOffset == 0) return newValue;
    var bufferString = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      bufferString.write(inputText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != inputText.length) bufferString.write(' ');
    }
    var string = bufferString.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var inputText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var bufferString = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      bufferString.write(inputText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != inputText.length) bufferString.write('/');
    }
    var string = bufferString.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}
