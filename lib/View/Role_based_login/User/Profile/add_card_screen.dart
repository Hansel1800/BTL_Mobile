import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  
  final FocusNode _cvvFocusNode = FocusNode();
  
  String _cardNumber = 'XXXX XXXX XXXX XXXX';
  String _expiryDate = 'MM/YY';
  String _cardHolder = 'CARD HOLDER';
  String _cvv = '***';
  
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);

    _cardNumberController.addListener(() {
      setState(() {
        _cardNumber = _cardNumberController.text.isEmpty ? 'XXXX XXXX XXXX XXXX' : _cardNumberController.text;
      });
    });
    
    _cardHolderController.addListener(() {
      setState(() {
        _cardHolder = _cardHolderController.text.isEmpty ? 'CARD HOLDER' : _cardHolderController.text.toUpperCase();
      });
    });

    _expiryController.addListener(() {
      setState(() {
        _expiryDate = _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;
      });
    });

    _cvvController.addListener(() {
      setState(() {
        _cvv = _cvvController.text.isEmpty ? '***' : _cvvController.text;
      });
    });

    _cvvFocusNode.addListener(() {
      if (_cvvFocusNode.hasFocus) {
        _flipController.forward();
        setState(() => _isFront = false);
      } else {
        _flipController.reverse();
        setState(() => _isFront = true);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    final rawCardNumber = _cardNumberController.text.replaceAll(' ', '');
    
    if (rawCardNumber.length != 16) {
      _showError('Số thẻ không hợp lệ (phải đủ 16 số)');
      return;
    }
    
    if (_cardHolderController.text.trim().isEmpty) {
      _showError('Vui lòng nhập họ tên chủ thẻ');
      return;
    }

    if (_expiryController.text.length != 5) {
      _showError('Ngày hết hạn không hợp lệ (MM/YY)');
      return;
    }
    
    // Simple Month check
    final parts = _expiryController.text.split('/');
    if (parts.length == 2) {
      final month = int.tryParse(parts[0]) ?? 0;
      if (month < 1 || month > 12) {
        _showError('Tháng không hợp lệ');
        return;
      }
    }

    if (_cvvController.text.length != 3) {
      _showError('Mã CVV phải có 3 số');
      return;
    }

    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thêm thẻ thành công!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
               // Header
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     IconButton(
                       icon: const Icon(Icons.close, color: Colors.white), 
                       onPressed: () => Navigator.pop(context),
                     ),
                     const Text('Thêm thẻ mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                     IconButton(
                       icon: const Icon(Icons.check, color: Colors.white), 
                       onPressed: _validateAndSave,
                     ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 20),
               
               // Card Visual
               AnimatedBuilder(
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
                            child: _buildCardBack()
                          ) 
                        : _buildCardFront(),
                    );
                 },
               ),
               
               const SizedBox(height: 40),
               
               // Inputs
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.all(24),
                   decoration: const BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                   ),
                   child: SingleChildScrollView(
                     child: Column(
                       children: [
                         _buildTextField(
                           controller: _cardNumberController,
                           label: 'Số thẻ',
                           icon: Icons.credit_card,
                           hint: 'XXXX XXXX XXXX XXXX',
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             LengthLimitingTextInputFormatter(16),
                             CardNumberFormatter(),
                           ],
                           keyboardType: TextInputType.number,
                         ),
                         const SizedBox(height: 16),
                         _buildTextField(
                           controller: _cardHolderController,
                           label: 'Họ tên chủ thẻ',
                           icon: Icons.person_outline,
                           hint: 'HỌ TÊN CHỦ THẺ',
                           inputFormatters: [
                             FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                           ],
                           textCapitalization: TextCapitalization.characters,
                         ),
                         const SizedBox(height: 16),
                         Row(
                           children: [
                             Expanded(
                               child: _buildTextField(
                                 controller: _expiryController,
                                 label: 'Ngày hết hạn',
                                 icon: Icons.calendar_today,
                                 hint: 'MM/YY',
                                 inputFormatters: [
                                   FilteringTextInputFormatter.digitsOnly,
                                   LengthLimitingTextInputFormatter(4),
                                   DateFormatter(),
                                 ],
                                 keyboardType: TextInputType.number,
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: _buildTextField(
                                 controller: _cvvController,
                                 focusNode: _cvvFocusNode,
                                 label: 'CVV',
                                 icon: Icons.lock_outline,
                                 hint: '***',
                                 isObscure: true,
                                 inputFormatters: [
                                   FilteringTextInputFormatter.digitsOnly,
                                   LengthLimitingTextInputFormatter(3),
                                 ],
                                 keyboardType: TextInputType.number,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             onPressed: _validateAndSave,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF6C63FF),
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: const Text('Thêm thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                           ),
                         )
                       ],
                     ),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
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
            padding: const EdgeInsets.all(16.0), // Reduced padding
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
                    _cardNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Courier', letterSpacing: 2, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                  ),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Card Holder', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(_cardHolder, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expires', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(_expiryDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildCardBack() {
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
          const SizedBox(height: 24), // Reduced from 30
          Container(height: 40, width: double.infinity, color: Colors.black),
          const SizedBox(height: 16), // Reduced from 20
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36, // Reduced from 40
                    color: Colors.grey[300],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(_cvv, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    FocusNode? focusNode,
    bool isObscure = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isObscure,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var inputText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var bufferString = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      bufferString.write(inputText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != inputText.length) {
        bufferString.write(' ');
      }
    }
    var string = bufferString.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var inputText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var bufferString = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      bufferString.write(inputText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != inputText.length) {
        bufferString.write('/');
      }
    }
    var string = bufferString.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
