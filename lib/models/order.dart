import 'wood_component.dart';

class Order {
  String orderId;
  String itemDescription;
  String? itemImagePath;
  String? clientName; // NEW
  String? clientCompany; // NEW
  String status; // NEW
  String? notes; // NEW
  List<WoodComponent> components;
  double labour;
  double hardware;
  double factory;
  List<Map<String, dynamic>> additionalCharges;
  double profit;
  double total;
  DateTime date;

  Order({
    required this.orderId,
    required this.itemDescription,
    this.itemImagePath,
    this.clientName,
    this.clientCompany,
    this.status = 'Pending',
    this.notes,
    required this.components,
    required this.labour,
    required this.hardware,
    required this.factory,
    this.additionalCharges = const [],
    required this.profit,
    required this.total,
    required this.date,
  });

  double get woodTotal =>
      components.fold<double>(0, (sum, item) => sum + item.totalCost);

  double get totalCft =>
      components.fold<double>(0, (sum, item) => sum + item.cft);

  double get additionalChargesTotal {
    return additionalCharges.fold<double>(0, (sum, charge) {
      return sum + (charge['amount'] as double? ?? 0.0);
    });
  }

  double get subtotalBeforeProfit {
    return woodTotal + labour + hardware + factory + additionalChargesTotal;
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'itemDescription': itemDescription,
    'itemImagePath': itemImagePath,
    'clientName': clientName,
    'clientCompany': clientCompany,
    'status': status,
    'notes': notes,
    'components': components.map((c) => c.toJson()).toList(),
    'labour': labour,
    'hardware': hardware,
    'factory': factory,
    'additionalCharges': additionalCharges,
    'profit': profit,
    'total': total,
    'date': date.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      itemDescription: json['itemDescription'],
      itemImagePath: json['itemImagePath'],
      clientName: json['clientName'],
      clientCompany: json['clientCompany'],
      status: json['status'] ?? 'Pending',
      notes: json['notes'],
      components: (json['components'] as List)
          .map((c) => WoodComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
      labour: (json['labour'] as num).toDouble(),
      hardware: (json['hardware'] as num).toDouble(),
      factory: (json['factory'] as num).toDouble(),
      additionalCharges: json['additionalCharges'] != null
          ? List<Map<String, dynamic>>.from(json['additionalCharges'])
          : [],
      profit: (json['profit'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}