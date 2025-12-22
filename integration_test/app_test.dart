import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/signup_screen.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Product/user_product_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:do_an_quan_ao/firebase_options.dart';

// Test "Chạy thật" trên thiết bị thật/máy ảo
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase thật trước khi bắt đầu test
  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Kiểm thử tích hợp (Real Device) - Luồng ứng dụng', () {

     testWidgets('Màn hình đăng ký - Kiểm tra lỗi tên hợp lệ (Real)', (WidgetTester tester) async {
        // Chạy SignupScreen thật, không Mock AuthService
        // AuthService sẽ được khởi tạo trong SignupScreen -> gọi FirebaseAuth thật -> OK trên thiết bị
        await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

        // Sử dụng index để tìm TextField chính xác hơn
        final nameField = find.byType(TextField).at(0); // Trường đầu tiên là Tên
        expect(nameField, findsOneWidget);

        // Trường hợp 1: Nhập ký tự không hợp lệ (số) -> Formatter sẽ tự động xóa
        await tester.enterText(nameField, 'User123'); 
        // Thực tế trên UI: TextField chỉ hiển thị "User" (hợp lệ)
        // Nên nếu bấm Đăng ký lúc này sẽ KHÔNG báo lỗi Tên.
        
        // Trường hợp 2: Để trống trường Tên -> Báo lỗi
        await tester.enterText(nameField, '');
        await tester.pump();
        
        // Nhấn Đăng ký
        await tester.tap(find.byIcon(Icons.arrow_forward)); 
        await tester.pumpAndSettle();

        // Kiểm tra thông báo lỗi (Lỗi do để trống hoặc Regex không khớp chuỗi rỗng)
        expect(find.textContaining('Họ và tên không hợp lệ'), findsOneWidget);
     });

     testWidgets('Màn hình đăng ký - Kiểm tra lỗi số điện thoại (Real)', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

        final nameField = find.byType(TextField).at(0);
        final phoneField = find.byType(TextField).at(1); // Trường thứ 2 là SĐT

        await tester.enterText(nameField, "Nguyen Van A");
        await tester.enterText(phoneField, "09123"); // SĐT ngắn -> Lỗi
        
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();

        expect(find.textContaining('Số điện thoại không hợp lệ'), findsOneWidget);
     });

     testWidgets('Hiển thị màn hình chi tiết sản phẩm người dùng', (WidgetTester tester) async {
       final mockProduct = Product(
         id: '123_real_test',
         name: 'Áo Thun Real Test',
         category: 'Áo thun',
         price: 200000,
         imageUrl: 'https://via.placeholder.com/150',
         stock: 5,
         description: 'Áo thun test trên thiết bị thật',
       );

       await tester.pumpWidget(
         ProviderScope(
           child: MaterialApp(
             home: UserProductDetailScreen(product: mockProduct),
           ),
         ),
       );

       expect(find.text('Áo Thun Real Test'), findsOneWidget);
       expect(find.textContaining('200,000'), findsOneWidget);
       expect(find.text('Thêm vào giỏ'), findsOneWidget);
     });

  });
}
