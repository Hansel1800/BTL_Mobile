import 'dart:math';
import 'package:do_an_quan_ao/Model/payment_method_model.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
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
    final cardHolder = details['cardHolder'] ?? 'Unknown';
    final expiryDate = details['expiryDate'] ?? 'MM/YY';
    final cvv = details['cvv'] ?? '***';


    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thẻ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F2027),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
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
            const Text(
              'Chạm vào thẻ để lật',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
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
                    cardNumber,
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
                          Text(cardHolder, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expires', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(expiryDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                    child: Text(cvv, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}
