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
  /// UUID del usuario (auth.users.id) que tomó la orden. Se guarda en
  /// Supabase como orders.waiter_id y se usa para resolver waiterName.
  final String? waiterId;
  /// Nombre legible del mesero. Al crear la orden se pasa directamente
  /// desde AuthProvider.nombreUsuario. Al recargar desde Supabase se
  /// resuelve vía el join profiles(full_name) en OrdenRepository.
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
    this.waiterId,
    this.waiterName,
  });

  factory RestaurantOrder.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parsedItems = [];
    if (json['order_items'] != null) {
      parsedItems = (json['order_items'] as List<dynamic>)
          .map((i) => OrderItem(
                productName: i['product_name'] ?? '',
                quantity: i['quantity'] ?? 1,
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
    String typeUi =
    typeDb == 'takeout' ? 'llevar' : 'comedor';

    // Resolver el nombre legible de la mesa desde el embed restaurant_tables(name).
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

    final tableOrCustomerResuelto = (nombreMesa != null && nombreMesa.isNotEmpty)
        ? nombreMesa
        : json['tableOrCustomer']?.toString() ?? 'Sin mesa';

    // Resolver el nombre del mesero desde el embed profiles(full_name).
    // OrdenRepository pide: profiles!orders_waiter_id_fkey(full_name)
    // PostgREST devuelve el resultado bajo la clave 'profiles' como Map o List.
    String? waiterNameResuelto;
    final profilesEmbed = json['profiles'];
    if (profilesEmbed is Map<String, dynamic>) {
      waiterNameResuelto = profilesEmbed['full_name']?.toString().trim();
    } else if (profilesEmbed is List && profilesEmbed.isNotEmpty) {
      final primero = profilesEmbed.first;
      if (primero is Map<String, dynamic>) {
        waiterNameResuelto = primero['full_name']?.toString().trim();
      }
    }
    // Si el embed no llegó (orden sin mesero asignado), intentar el campo
    // waiterName que a veces se pasa directamente desde la UI al crear la orden.
    if (waiterNameResuelto == null || waiterNameResuelto.isEmpty) {
      waiterNameResuelto = json['waiterName']?.toString();
    }

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
      waiterId: json['waiter_id']?.toString(),
      waiterName: waiterNameResuelto,
    );
  }

  Map<String, dynamic> toJson() {
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
      // waiterId es el UUID del usuario logueado (auth.users.id).
      // Supabase lo guarda en orders.waiter_id y permite resolver el nombre
      // del mesero al releer la orden mediante join con profiles.
      'waiter_id': waiterId,
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
    String? waiterId,
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
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
    );
  }
}