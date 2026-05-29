import 'order_item.dart';

typedef OrderStatus = String;
typedef ServiceType = String;

class RestaurantOrder {
  final String id;
  final String orderNumber;
  final String? tableId; // UUID de la mesa (Supabase table_id)
  final String tableOrCustomer; // Nombre/descripción para display
  final String time;
  final OrderStatus status;
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double totalAmount;
  final String? notes;

  RestaurantOrder({
    required this.id,
    required this.orderNumber,
    this.tableId,
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
      parsedItems = (json['order_items'] as List<dynamic>)
          .map((i) => OrderItem(
                productName: i['product_name'] ?? '',
                quantity: i['quantity'] ?? 1,
                total: (i['total'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } else if (json['items'] != null) {
      parsedItems = (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return RestaurantOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ??
          json['orderNumber']?.toString() ??
          '',
      tableId: json['table_id']?.toString(),
      tableOrCustomer: json['table_id']?.toString() ??
          json['tableOrCustomer']?.toString() ??
          'Sin mesa',
      time: json['created_at']?.toString() ?? json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pendiente',
      serviceType: json['order_type']?.toString() ??
          json['serviceType']?.toString() ??
          'comedor',
      items: parsedItems,
      totalAmount: (json['total'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Si el id está vacío, lo enviamos como cadena vacía para que 
      // el repositorio lo detecte y lo elimine antes del insert.
      'id': id.isEmpty ? null : id, 
      'order_number': orderNumber,
      'order_type': serviceType,
      'status': status,
      'subtotal': totalAmount,
      'total': totalAmount,
      'table_id': tableId, // Asegúrate de que esto coincide con la columna en Supabase
      'notes': notes,
      'waiter_id': null,
      'payment_method': null,
      'paid_at': null,
      'discount_id': null,
      'discount_amount': 0,
      'tip': 0,
    };
  }

  RestaurantOrder copyWith({
    String? id,
    String? orderNumber,
    String? tableId,
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
      orderNumber: orderNumber ?? this.orderNumber,
      tableId: tableId ?? this.tableId,
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
