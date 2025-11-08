import 'wood_component.dart'; // Add this import

class Order {
  String orderId;
  String itemDescription;
  String? itemImagePath;
  List<WoodComponent> components;
  double labour;
  double hardware;
  double factory;
  List<Map<String, dynamic>> additionalCharges; // New field for other charges
  double profit;
  double total;
  DateTime date;

  Order({
    required this.orderId,
    required this.itemDescription,
    this.itemImagePath,
    required this.components,
    required this.labour,
    required this.hardware,
    required this.factory,
    this.additionalCharges = const [], // Optional with default empty list
    required this.profit,
    required this.total,
    required this.date,
  });

  double get woodTotal => components.fold<double>(0, (sum, item) => sum + item.totalCost);

  double get totalCft => components.fold<double>(0, (sum, item) => sum + item.cft);

  // Calculate total of additional charges
  double get additionalChargesTotal {
    return additionalCharges.fold<double>(0, (sum, charge) {
      return sum + (charge['amount'] as double? ?? 0.0);
    });
  }

  // Get subtotal before profit
  double get subtotalBeforeProfit {
    return woodTotal + labour + hardware + factory + additionalChargesTotal;
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'itemDescription': itemDescription,
    'itemImagePath': itemImagePath,
    'components': components.map((c) => c.toJson()).toList(),
    'labour': labour,
    'hardware': hardware,
    'factory': factory,
    'additionalCharges': additionalCharges, // Include additional charges in JSON
    'profit': profit,
    'total': total,
    'date': date.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      itemDescription: json['itemDescription'],
      itemImagePath: json['itemImagePath'],
      components: (json['components'] as List)
          .map((c) => WoodComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
      labour: (json['labour'] as num).toDouble(),
      hardware: (json['hardware'] as num).toDouble(),
      factory: (json['factory'] as num).toDouble(),
      additionalCharges: json['additionalCharges'] != null
          ? List<Map<String, dynamic>>.from(json['additionalCharges'])
          : [], // Handle backward compatibility
      profit: (json['profit'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}