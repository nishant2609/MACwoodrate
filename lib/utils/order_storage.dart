import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class OrderStorage {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/orders.json');
  }

  static Future<List<Order>> readOrders() async {
    try {
      final file = await _localFile;
      if (!(await file.exists())) return <Order>[];
      String contents = await file.readAsString();
      List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return <Order>[];
    }
  }

  static Future<void> saveOrder(Order order) async {
    List<Order> orders = await readOrders();
    orders.add(order);
    final file = await _localFile;
    await file.writeAsString(jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  static Future<void> deleteOrder(String orderId) async {
    List<Order> orders = await readOrders();
    orders.removeWhere((order) => order.orderId == orderId);
    final file = await _localFile;
    await file.writeAsString(jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  static Future<Order?> getOrderById(String orderId) async {
    List<Order> orders = await readOrders();
    try {
      return orders.firstWhere((order) => order.orderId == orderId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateOrder(Order updatedOrder) async {
    List<Order> orders = await readOrders();
    int index = orders.indexWhere((order) => order.orderId == updatedOrder.orderId);
    if (index != -1) {
      orders[index] = updatedOrder;
      final file = await _localFile;
      await file.writeAsString(jsonEncode(orders.map((o) => o.toJson()).toList()));
    }
  }

  static Future<void> clearAllOrders() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(<Map<String, dynamic>>[]));
  }
}