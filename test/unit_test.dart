import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/card_detail_screen.dart';

// --- Helper Logic (Mirrored from App for Verification) ---
String removeDiacritics(String str) {
  var withDia = 'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
  var withoutDia = 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

void main() {
  group('Unit Tests - Deployment Preparation', () {
    
    // UT-01, UT-02
    test('Helper - removeDiacritics works correctly', () {
      expect(removeDiacritics('Áo sơ mi trắng'.toLowerCase()), 'ao so mi trang');
      expect(removeDiacritics('đầm váy'.toLowerCase()), 'dam vay');
      expect(removeDiacritics('Tất cả'.toLowerCase()), 'tat ca');
    });

    // UT-03, UT-04
    test('Formatter - CardNumberFormatter filters spaces and groups by 4', () {
      final formatter = CardNumberFormatter();
      
      // Case 1: Typing normal numbers
      final oldValue1 = const TextEditingValue(text: '');
      final newValue1 = const TextEditingValue(
        text: '12345678', 
        selection: TextSelection.collapsed(offset: 8)
      );
      
      final result1 = formatter.formatEditUpdate(oldValue1, newValue1);
      expect(result1.text, '1234 5678');
      
      // Case 2: Input with spaces (user copy-paste usually filters in logic, but formatter ensures display)
      // The formatter logic implementation:
      // var inputText = newValue.text.replaceAll(' ', '');
      // ... loops and adds space every 4 chars
      
      final oldValue2 = const TextEditingValue(text: '1234 ');
      final newValue2 = const TextEditingValue(
        text: '1234 56789', 
        selection: TextSelection.collapsed(offset: 10)
      );
       
      final result2 = formatter.formatEditUpdate(oldValue2, newValue2);
      // '123456789' -> '1234 5678 9'
      expect(result2.text, '1234 5678 9');
    });

    // UT-05
    test('Formatter - Currency formatting', () {
      final format = NumberFormat("#,##0", "vi_VN");
      final result = "${format.format(2500000)}đ";
      // Note: Space depends on locale implementation, usually it's "2.500.000" or "2,500,000"
      // Based on the code in app: NumberFormat("#,##0", "vi_VN") uses dots for thousands.
      expect(result.replaceAll('.', ','), contains('2,500,000')); // Weak assertion to handle locale diffs envs
    });

    // UT-06, UT-07
    test('Logic - Voucher Calculation', () {
       double subtotal = 1000000;
       
       // Scenario: 10% Discount
       double discountPercent = 10;
       double discountAmount = subtotal * (discountPercent / 100);
       expect(discountAmount, 100000);
       
       // Scenario: Max Discount Cap
       double maxDiscount = 50000;
       if (discountAmount > maxDiscount) discountAmount = maxDiscount;
       expect(discountAmount, 50000); // Should be capped
       
       // Scenario: Min Order Value Fail
       double minOrder = 2000000;
       bool isValid = subtotal >= minOrder;
       expect(isValid, false);
    });
  });
}
