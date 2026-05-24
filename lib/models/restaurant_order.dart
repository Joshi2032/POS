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
    // Extraemos los items si la consulta de Supabase trae los order_items anidados
    List<OrderItem> parsedItems = [];
    if (json['order_items'] != null) {
      parsedItems = (json['order_items'] as List<dynamic>).map((i) => OrderItem(
        productName: i['product_name'] ?? '',
        quantity: i['quantity'] ?? 1,
        total: (i['total'] as num?)?.toDouble() ?? 0.0,
      )).toList();
    } else if (json['items'] != null) {
      parsedItems = (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return RestaurantOrder(
      id: json['id']?.toString() ?? '',
      // Si viene de Supabase usa table_number, si es local usa tableOrCustomer
      tableOrCustomer: json['table_number']?.toString() ?? json['tableOrCustomer']?.toString() ?? 'Sin mesa',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pendiente',
      serviceType: json['service_type']?.toString() ?? json['serviceType']?.toString() ?? 'comedor',
      items: parsedItems,
      totalAmount: (json['total'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_number': tableOrCustomer, // Mapeado hacia la columna de Supabase
      'time': time,
      'status': status,
      'service_type': serviceType,
      'total': totalAmount,
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