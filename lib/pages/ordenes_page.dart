import 'package:flutter/material.dart';

// ==========================================
// MODELOS DE DATOS (Mapeo de ordenes.models.ts)
// ==========================================
typedef OrderStatus
    = String; // 'pendiente' | 'preparando' | 'lista' | 'entregada' | 'cancelada'
typedef ServiceType = String; // 'comedor' | 'llevar' | 'domicilio'

class OrderDetail {
  final String productName;
  final int quantity;
  final double price;

  OrderDetail({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

class Order {
  final String id;
  final String tableOrCustomer;
  final ServiceType serviceType;
  final List<OrderDetail> items;
  OrderStatus status;
  final String time;
  final String? notes;

  Order({
    required this.id,
    required this.tableOrCustomer,
    required this.serviceType,
    required this.items,
    required this.status,
    required this.time,
    this.notes,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  Order copyWith({
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      tableOrCustomer: tableOrCustomer,
      serviceType: serviceType,
      items: items,
      status: status ?? this.status,
      time: time,
      notes: notes,
    );
  }
}

// ==========================================
// COMPONENTE PRINCIPAL (OrdenesComponent)
// ==========================================
class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  final int pageSize = 8;

  // SIGNALS de Angular mapeados a estados locales estructurados
  String searchTerm = '';
  int currentPage = 1;
  String selectedFilterStatus = 'Todos';
  String selectedFilterService = 'Todos';
  Order? selectedOrderForModal;
  bool showModal = false;

  List<Order> orders = [];

  @override
  void initState() {
    super.initState();

    // Semilla de datos simulada idéntica a tus componentes de control de cocina/caja
    orders = [
      Order(
          id: 'ORD-101',
          tableOrCustomer: 'Mesa 4',
          serviceType: 'comedor',
          status: 'pendiente',
          time: '14:25',
          items: [
            OrderDetail(
                productName: 'Tacos de Asada', quantity: 3, price: 35.0),
            OrderDetail(
                productName: 'Refresco Refill', quantity: 2, price: 30.0),
          ]),
      Order(
          id: 'ORD-102',
          tableOrCustomer: 'Carlos P.',
          serviceType: 'llevar',
          status: 'preparando',
          time: '14:30',
          items: [
            OrderDetail(
                productName: 'Hamburguesa Zapata', quantity: 1, price: 120.0),
            OrderDetail(productName: 'Papas Gajo', quantity: 1, price: 45.0),
          ],
          notes: 'Sin cebolla en la hamburguesa'),
      Order(
          id: 'ORD-103',
          tableOrCustomer: 'Calle Aldama #24',
          serviceType: 'domicilio',
          status: 'lista',
          time: '14:10',
          items: [
            OrderDetail(
                productName: 'Paquete Familiar Premium',
                quantity: 1,
                price: 389.0),
          ]),
      Order(
          id: 'ORD-104',
          tableOrCustomer: 'Mesa 1',
          serviceType: 'comedor',
          status: 'entregada',
          time: '13:15',
          items: [
            OrderDetail(
                productName: 'Combo Individual', quantity: 2, price: 149.0),
          ]),
      Order(
          id: 'ORD-105',
          tableOrCustomer: 'Mesa 7',
          serviceType: 'comedor',
          status: 'cancelada',
          time: '13:00',
          items: [
            OrderDetail(
                productName: 'Gringa de Pastor', quantity: 1, price: 65.0),
          ]),
    ];
  }

  // LOGICA COMPUTADA (computed) de Angular
  List<Order> get filteredOrders {
    final search = searchTerm.toLowerCase();
    return orders.where((order) {
      final matchesSearch = order.id.toLowerCase().contains(search) ||
          order.tableOrCustomer.toLowerCase().contains(search);
      final matchesStatus = selectedFilterStatus == 'Todos' ||
          order.status == selectedFilterStatus.toLowerCase();
      final matchesService = selectedFilterService == 'Todos' ||
          order.serviceType == selectedFilterService.toLowerCase();

      return matchesSearch && matchesStatus && matchesService;
    }).toList();
  }

  List<Order> get paginatedOrders {
    final filtered = filteredOrders;
    final start = (currentPage - 1) * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) > filtered.length
        ? filtered.length
        : (start + pageSize);
    return filtered.sublist(start, end);
  }

  int get totalPages => (filteredOrders.length / pageSize).ceil();
  int get activeOrdersCount => orders
      .where((o) =>
          o.status == 'pendiente' ||
          o.status == 'preparando' ||
          o.status == 'lista')
      .length;
  int get readyOrdersCount => orders.where((o) => o.status == 'lista').length;

  // METODOS DEL EVENT HANDLER (TS)
  void onSearchChange(String value) {
    setState(() {
      searchTerm = value;
      currentPage = 1;
    });
  }

  void onStatusFilterChange(String status) {
    setState(() {
      selectedFilterStatus = status;
      currentPage = 1;
    });
  }

  void onServiceFilterChange(String service) {
    setState(() {
      selectedFilterService = service;
      currentPage = 1;
    });
  }

  void cambiarEstadoOrden(String id, OrderStatus nuevoEstado) {
    setState(() {
      final index = orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        orders[index] = orders[index].copyWith(status: nuevoEstado);
        _showToast('Orden $id cambiada a ${_getStatusLabel(nuevoEstado)}',
            Colors.green);
        if (showModal && selectedOrderForModal?.id == id) {
          selectedOrderForModal = orders[index];
        }
      }
    });
  }

  void abrirDetalleModal(Order order) {
    setState(() {
      selectedOrderForModal = order;
      showModal = true;
    });
  }

  void cerrarModal() {
    setState(() {
      showModal = false;
      selectedOrderForModal = null;
    });
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  // AUXILIARES DE ESTILOS E IDIOMA (.html Helper Functions)
  String _getStatusLabel(OrderStatus status) {
    final Map<OrderStatus, String> labels = {
      'pendiente': 'Pendiente',
      'preparando': 'En Cocina',
      'lista': 'Lista para Entrega',
      'entregada': 'Entregada',
      'cancelada': 'Cancelada'
    };
    return labels[status] ?? status;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'lista':
        return Colors.green;
      case 'entregada':
        return Colors.grey;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _getServiceLabel(ServiceType type) {
    if (type == 'comedor') return '🍽️ Comedor';
    if (type == 'llevar') return '🛍️ Para Llevar';
    return '🛵 Domicilio';
  }

  // ==========================================
  // DISPOSICIÓN DE INTERFAZ DE USUARIO (HTML/CSS)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      body: Stack(
        children: [
          // CONTENIDO PRINCIPAL DEL MÓDULO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER DEL COMPONENTE (ordenes-header)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📋 ', style: TextStyle(fontSize: 26)),
                              Text('Módulo de Órdenes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text(
                              'Monitoreo en tiempo real de comandas y despachos',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      // Tarjetas rápidas de estado superior
                      Row(
                        children: [
                          _buildTopStatusIndicator(
                              'Activas', '$activeOrdersCount', Colors.blue),
                          const SizedBox(width: 12),
                          _buildTopStatusIndicator(
                              'Listas', '$readyOrdersCount', Colors.green),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // BARRA DE FILTROS Y BÚSQUEDA COMBINADA (Filtros superiores en HTML)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            flex: isDesktop ? 4 : 0,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText:
                                    'Buscar por ID de orden o cliente/mesa...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                              onChanged: onSearchChange,
                            ),
                          ),
                          if (!isDesktop) const Divider(),
                          if (isDesktop)
                            const VerticalDivider(width: 24, thickness: 1),
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedFilterStatus,
                              decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: InputBorder.none),
                              items: [
                                'Todos',
                                'Pendiente',
                                'Preparando',
                                'Lista',
                                'Entregada',
                                'Cancelada'
                              ]
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) =>
                                  onStatusFilterChange(val ?? 'Todos'),
                            ),
                          ),
                          if (isDesktop)
                            const VerticalDivider(width: 24, thickness: 1),
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedFilterService,
                              decoration: const InputDecoration(
                                  labelText: 'Servicio',
                                  border: InputBorder.none),
                              items: ['Todos', 'Comedor', 'Llevar', 'Domicilio']
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) =>
                                  onServiceFilterChange(val ?? 'Todos'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text('${filteredOrders.length} orden(es) encontrada(s)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ESTADO DE DATOS VACÍOS (empty-state)
                  if (filteredOrders.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      child: const Column(
                        children: [
                          Text('🍳', style: TextStyle(fontSize: 54)),
                          SizedBox(height: 12),
                          Text(
                              'No hay órdenes activas que coincidan con los filtros.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ),

                  // LISTADO GRID/LIST ADAPTATIVO DE COMANDAS
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 1.4 : 1.9,
                    ),
                    itemCount: paginatedOrders.length,
                    itemBuilder: (context, index) {
                      final order = paginatedOrders[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => abrirDetalleModal(order),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Renglón de ID y Hora
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(order.id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.grey)),
                                    Text('🕒 ${order.time}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Cliente / Mesa y Badge de Estado
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(order.tableOrCustomer,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(order.status),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(_getStatusLabel(order.status),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_getServiceLabel(order.serviceType),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.blueGrey)),
                                const Divider(),
                                // Lista resumida de productos del ticket
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: order.items.length > 2
                                        ? 2
                                        : order.items.length,
                                    itemBuilder: (ctx, idx) {
                                      final item = order.items[idx];
                                      return Text(
                                          '${item.quantity}x ${item.productName}',
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis);
                                    },
                                  ),
                                ),
                                if (order.items.length > 2)
                                  Text(
                                      '+ ${order.items.length - 2} productos más...',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 14, color: Colors.grey),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // CONTROLADORES DE PAGINACIÓN (*ngIf="totalPages() > 1")
                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage == 1
                              ? null
                              : () => goToPage(currentPage - 1),
                        ),
                        Text('Página $currentPage de $totalPages',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage == totalPages
                              ? null
                              : () => goToPage(currentPage + 1),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),

          // BACKDROP Y PANEL DE DETALLE MODAL INTERNO (*ngIf="showModal")
          if (showModal && selectedOrderForModal != null) ...[
            GestureDetector(
              onTap: cerrarModal,
              child: Container(color: Colors.black54),
            ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isDesktop ? 500 : double.infinity,
                margin: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Detalle de Comanda: ${selectedOrderForModal!.id}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: cerrarModal),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                            'Cliente/Mesa: ${selectedOrderForModal!.tableOrCustomer}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                            'Tipo de Servicio: ${_getServiceLabel(selectedOrderForModal!.serviceType)}',
                            style: const TextStyle(color: Colors.blueGrey)),
                        Text(
                            'Hora de Registro: ${selectedOrderForModal!.time} hrs'),
                        if (selectedOrderForModal!.notes != null &&
                            selectedOrderForModal!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange)),
                            child: Text(
                                '⚠️ Notas: ${selectedOrderForModal!.notes}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          )
                        ],
                        const SizedBox(height: 16),
                        const Text('Productos Solicitados:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        // Lista de desglose del ticket
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: selectedOrderForModal!.items.length,
                            itemBuilder: (ctx, index) {
                              final item = selectedOrderForModal!.items[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${item.quantity}x ${item.productName}',
                                        style: const TextStyle(fontSize: 14)),
                                    Text('\$${item.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Importe Total:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                                '\$${selectedOrderForModal!.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Flujo de Estados de Cocina:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey)),
                        const SizedBox(height: 10),
                        // Renglón de botones rápidos para mutar estado (Acciones directas)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (selectedOrderForModal!.status == 'pendiente')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.soup_kitchen),
                                label: const Text('Cocinar'),
                                onPressed: () => cambiarEstadoOrden(
                                    selectedOrderForModal!.id, 'preparando'),
                              ),
                            if (selectedOrderForModal!.status == 'preparando')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.check),
                                label: const Text('Listo'),
                                onPressed: () => cambiarEstadoOrden(
                                    selectedOrderForModal!.id, 'lista'),
                              ),
                            if (selectedOrderForModal!.status == 'lista')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white),
                                icon: const Icon(Icons.delivery_dining),
                                label: const Text('Entregar'),
                                onPressed: () => cambiarEstadoOrden(
                                    selectedOrderForModal!.id, 'entregada'),
                              ),
                            if (selectedOrderForModal!.status != 'entregada' &&
                                selectedOrderForModal!.status != 'cancelada')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancelar Orden'),
                                onPressed: () => cambiarEstadoOrden(
                                    selectedOrderForModal!.id, 'cancelada'),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTopStatusIndicator(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5)),
      child: Row(
        children: [
          Text('$title: ',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(count,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

// Extensiones compartidas de utilidad sintáctica para Strings
extension StringSlice on String {
  String slice(int start, int end) => substring(start, end);
}
