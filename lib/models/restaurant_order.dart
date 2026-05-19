import 'order_item.dart';

typedef OrderStatus = String;
typedef ServiceType = String;

class RestaurantOrder {
  final String id;
  final String tableOrCustomer;
  final String time;
  final OrderStatus status;
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double totalAmount;
  final String? notes;

  RestaurantOrder({
    required this.id,
    required this.tableOrCustomer,
    required this.time,
    required this.status,
    required this.serviceType,
    required this.items,
    required this.totalAmount,
    this.notes,
  });

  factory RestaurantOrder.fromJson(Map<String, dynamic> json) {
    return RestaurantOrder(
      id: json['id'] as String,
      tableOrCustomer: json['tableOrCustomer'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      serviceType: json['serviceType'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableOrCustomer': tableOrCustomer,
      'time': time,
      'status': status,
      'serviceType': serviceType,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'notes': notes,
    };
  }

  RestaurantOrder copyWith({
    String? id,
    String? tableOrCustomer,
    String? time,
    OrderStatus? status,
    ServiceType? serviceType,
    List<OrderItem>? items,
    double? totalAmount,
    String? notes,
  }) {
    return RestaurantOrder(
      id: id ?? this.id,
      tableOrCustomer: tableOrCustomer ?? this.tableOrCustomer,
      time: time ?? this.time,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
    );
  }
}
