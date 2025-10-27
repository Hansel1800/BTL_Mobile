import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Firebase auth
  final FirebaseAuth _authService = FirebaseAuth.instance;

  // firebase database instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ham de nguoi dung sign up
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // tao nguoi dung moi tren firebase Auth
      UserCredential userCredential = await _authService
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'createAt': FieldValue.serverTimestamp(),
      });
      return null; // thanh cong: khong co loi
    } catch (e) {
      return e.toString(); // loi: return exception
    }
  }

  // ham de nguoi dung login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // dang nhap nguoi dung tren firebase Auth
      UserCredential userCredential = await _authService
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // kiem tra vai tro tren firestore de phan quyen
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();
      return userDoc["role"]; // tra ve user or admin
    } catch (e) {
      return e.toString(); // loi: return exception
    }
  }

  // Kiểm tra kết nối tới Firestore bằng ghi và đọc 1 document tạm
  Future<String> checkFirestoreConnection() async {
    try {
      final docRef = _firestore.collection('health_check').doc('ping');
      final now = DateTime.now().toIso8601String();

      // ghi thử
      await docRef.set({'ping': now});

      // đọc lại
      final snap = await docRef.get();
      if (snap.exists && snap.data()?['ping'] == now) {
        return 'OK: Firestore reachable, ping=$now';
      } else {
        return 'WARN: Document not found or mismatch';
      }
    } catch (e) {
      return 'ERROR: ${e.toString()}';
    }
  }

  signOut() async {
    _authService.signOut();
  }
}
