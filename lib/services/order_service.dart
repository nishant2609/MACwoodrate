import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_models;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save order to Firestore
  Future<void> saveOrder(app_models.Order order, String companyId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .doc(order.orderId)
          .set(order.toJson());
    } catch (e) {
      print('Error saving order: $e');
      rethrow;
    }
  }

  // Get all orders for a company
  Future<List<app_models.Order>> getOrders(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => app_models.Order.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  // Delete order
  Future<void> deleteOrder(String orderId, String companyId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .doc(orderId)
          .delete();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<app_models.Order?> getOrderById(
      String orderId, String companyId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) return null;
      return app_models.Order.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Update order
  Future<void> updateOrder(app_models.Order order, String companyId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .doc(order.orderId)
          .update(order.toJson());
    } catch (e) {
      print('Error updating order: $e');
      rethrow;
    }
  }

  // Get orders stream (real-time)
  Stream<List<app_models.Order>> getOrdersStream(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('orders')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => app_models.Order.fromJson(doc.data()))
        .toList());
  }

  // Get order stats
  Future<Map<String, dynamic>> getOrderStats(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('orders')
          .get();

      double totalRevenue = 0;
      double totalCft = 0;
      int totalOrders = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final order = app_models.Order.fromJson(doc.data());
        totalRevenue += order.total;
        totalCft += order.totalCft;
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'totalCft': totalCft,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'totalCft': 0.0,
      };
    }
  }
}