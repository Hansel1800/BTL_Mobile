import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  Stream<List<Product>> getProducts() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
    });
  }

  Future<void> addProduct(Product product) async {
    try {
      print('Adding product: ${product.name}');
      final docRef = _firestore.collection(_collection).doc();
      final newProduct = Product(
        id: docRef.id,
        name: product.name,
        category: product.category,
        price: product.price,
        imageUrl: product.imageUrl,
        stock: product.stock,
      );
      await docRef.set(newProduct.toJson());
      print('Product added to Firestore: ${docRef.id}');
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).update({
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'stock': product.stock,
      });
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}
