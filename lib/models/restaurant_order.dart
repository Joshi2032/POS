import 'order_item.dart';

typedef OrderStatus = String;
typedef ServiceType = String;

class RestaurantOrder {
  final String id;
  final String orderNumber;
  final String? tableId; // UUID relacional de la mesa
  final String tableOrCustomer; // Nombre descriptivo para la UI
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
    List<OrderItem> parsedItems = [];
    if (json['order_items'] != null) {
      parsedItems = (json['order_items'] as List<dynamic>)
          .map((i) => OrderItem(
                productName: i['product_name'] ?? '',
                quantity: i['quantity'] ?? 1,
                // AQUÍ ESTÁ LA CORRECCIÓN: Agregamos unitPrice
                unitPrice: (i['unit_price'] as num?)?.toDouble() ?? 0.0,
                total: (i['total_price'] as num?)?.toDouble() ?? (i['total'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } else if (json['items'] != null) {
      parsedItems = (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Traducción de estados de la BD (Inglés) a la UI (Español)
    String statusDb = json['status']?.toString() ?? 'pending';
    String statusUi = 'pendiente';
    switch (statusDb.toLowerCase()) {
      case 'preparing': statusUi = 'preparando'; break;
      case 'ready': statusUi = 'lista'; break;
      case 'delivered': statusUi = 'entregada'; break;
      case 'paid': statusUi = 'pagada'; break;
      case 'cancelled': statusUi = 'cancelada'; break;
      default: statusUi = 'pendiente';
    }

    // Traducción del tipo de servicio
    String typeDb = json['order_type']?.toString() ?? 'dine_in';
    String typeUi = typeDb == 'takeout' ? 'para llevar' : 'comedor';

    return RestaurantOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['orderNumber']?.toString() ?? '',
      tableId: json['table_id']?.toString(),
      tableOrCustomer: json['table_id']?.toString() ?? json['tableOrCustomer']?.toString() ?? 'Sin mesa',
      time: json['created_at']?.toString() ?? json['time']?.toString() ?? '',
      status: statusUi,
      serviceType: typeUi,
      items: parsedItems,
      totalAmount: (json['total'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    // Traducción de la UI (Español) a la BD (Inglés) para aprobar las restricciones CHECK
    String statusDb = 'pending';
    switch (status.toLowerCase()) {
      case 'preparando': statusDb = 'preparing'; break;
      case 'lista': statusDb = 'ready'; break;
      case 'entregada': statusDb = 'delivered'; break;
      case 'pagada': statusDb = 'paid'; break;
      case 'cancelada': statusDb = 'cancelled'; break;
    }

    String typeDb = serviceType.toLowerCase().contains('llevar') ? 'takeout' : 'dine_in';

    return {
      'id': id.isEmpty ? null : id,
      'order_number': orderNumber,
      'order_type': typeDb,
      'status': statusDb,
      'subtotal': totalAmount,
      'total': totalAmount,
      'table_id': tableId,
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