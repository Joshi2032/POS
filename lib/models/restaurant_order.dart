import 'order_item.dart';

typedef OrderStatus = String;
typedef ServiceType = String;

class RestaurantOrder {
  final String id;
  final String orderNumber;
  final String? tableId;
  final String tableOrCustomer;
  final String time;
  final OrderStatus status;
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double totalAmount;
  final String? notes;
  /// Nombre del mesero/empleado que tomó la orden.
  /// Se guarda en memoria al crear la orden desde tomar_orden_page y se
  /// imprime en el ticket. No viene de la BD al recargar (waiter_id FK no
  /// hace join automático al nombre), pero sí se pasa al crearlo.
  final String? waiterName;

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
    this.waiterName,
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

    // Resolver el nombre legible de la mesa (ej. "A4") a partir del embed
    // restaurant_tables(name) que ahora pide OrdenRepository. Supabase/
    // PostgREST puede devolver este embed como un Map (relación 1:1) o
    // como una List de un elemento (relación 1:N), según cómo esté
    // declarada la foreign key, así que contemplamos ambos casos.
    String? nombreMesa;
    final tablaEmbed = json['restaurant_tables'];
    if (tablaEmbed is Map<String, dynamic>) {
      nombreMesa = tablaEmbed['name']?.toString();
    } else if (tablaEmbed is List && tablaEmbed.isNotEmpty) {
      final primero = tablaEmbed.first;
      if (primero is Map<String, dynamic>) {
        nombreMesa = primero['name']?.toString();
      }
    }

    // Prioridad para tableOrCustomer:
    // 1. Nombre real de la mesa resuelto vía join (ej. "A4")
    // 2. Un tableOrCustomer ya armado explícitamente (ej. al crear la orden
    //    desde tomar_orden_page.dart, que ya arma "Mesa A4 (Área Salón)")
    // 3. 'Sin mesa' como respaldo final si no hay mesa asociada
    // OJO: ya NO usamos table_id (UUID) como texto a mostrar, porque eso
    // es lo que causaba que el ticket impreso mostrara un UUID o "Sin mesa"
    // en vez del nombre real de la mesa.
    final tableOrCustomerResuelto = (nombreMesa != null && nombreMesa.isNotEmpty)
        ? nombreMesa
        : json['tableOrCustomer']?.toString() ?? 'Sin mesa';

    return RestaurantOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['orderNumber']?.toString() ?? '',
      tableId: json['table_id']?.toString(),
      tableOrCustomer: tableOrCustomerResuelto,
      time: json['created_at']?.toString() ?? json['time']?.toString() ?? '',
      status: statusUi,
      serviceType: typeUi,
      items: parsedItems,
      totalAmount: (json['total'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      // waiterName no viene en el JSON de Supabase (requeriría join con profiles),
      // pero se puede pasar directamente al crear la orden desde la UI.
      waiterName: json['waiterName']?.toString(),
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
    String? waiterName,
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
      waiterName: waiterName ?? this.waiterName,
    );
  }
}