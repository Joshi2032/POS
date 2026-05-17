import 'package:flutter/material.dart';

// ==========================================
// MODELOS DE DATOS (Mapeo exacto de caja.component.ts)
// ==========================================
typedef PaymentMethod = String; // 'Efectivo' | 'Tarjeta' | 'Transferencia'

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class CashOrder {
  final String id;
  final String label;
  final String status; // 'Pendiente' | 'Preparando' | 'Pagada'
  final int itemsCount;
  final String time;
  final double total;
  final List<OrderItem> items;

  CashOrder({
    required this.id,
    required this.label,
    required this.status,
    required this.itemsCount,
    required this.time,
    required this.total,
    required this.items,
  });

  CashOrder copyWith({
    String? status,
  }) {
    return CashOrder(
      id: id,
      label: label,
      status: status ?? this.status,
      itemsCount: itemsCount,
      time: time,
      total: total,
      items: items,
    );
  }
}

// ==========================================
// COMPONENTE PRINCIPAL (CajaComponent)
// ==========================================
class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  final List<PaymentMethod> paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  // SIGNALS de Angular mapeados a estados locales estructurados
  List<CashOrder> pendingOrders = [];
  List<CashOrder> paidToday = [];

  String? selectedOrderId;
  PaymentMethod selectedMethod = 'Efectivo';
  double? receivedAmount;
  String cashError = '';

  final _receivedAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Semilla de datos exacta de pendingOrders de tu TS
    pendingOrders = [
      CashOrder(
        id: 'ORD-120',
        label: 'Mesa A1',
        status: 'Pendiente',
        itemsCount: 2,
        time: '07:05 p.m.',
        total: 475.0,
        items: [
          OrderItem(name: 'Arrachera 300g', qty: 1, price: 285.0),
          OrderItem(name: 'Agua de Jamaica', qty: 1, price: 40.0),
          OrderItem(name: 'Papas al Carbon', qty: 1, price: 75.0),
          OrderItem(name: 'Mezcal Oaxaqueno', qty: 1, price: 75.0)
        ]
      ),
      CashOrder(
        id: 'ORD-121',
        label: 'Llevar',
        status: 'Preparando',
        itemsCount: 1,
        time: '06:50 p.m.',
        total: 320.0,
        items: [
          OrderItem(name: 'Costillas BBQ', qty: 1, price: 320.0)
        ]
      )
    ];

    // Semilla de datos exacta de paidToday de tu TS
    paidToday = [
      CashOrder(id: 'ORD-100', label: 'Mesa B2', status: 'Pagada', itemsCount: 3, time: '04:20 p.m.', total: 570.0, items: []),
      CashOrder(id: 'ORD-101', label: 'Mesa A3', status: 'Pagada', itemsCount: 2, time: '04:44 p.m.', total: 450.0, items: []),
      CashOrder(id: 'ORD-102', label: 'Llevar', status: 'Pagada', itemsCount: 1, time: '05:05 p.m.', total: 320.0, items: []),
      CashOrder(id: 'ORD-103', label: 'Mesa C1', status: 'Pagada', itemsCount: 4, time: '05:32 p.m.', total: 835.0, items: []),
      CashOrder(id: 'ORD-104', label: 'Mesa A2', status: 'Pagada', itemsCount: 1, time: '05:58 p.m.', total: 195.0, items: [])
    ];
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    super.dispose();
  }

  // LÓGICA COMPUTADA (computed) de Angular
  CashOrder? get selectedOrder {
    if (selectedOrderId == null) return null;
    return pendingOrders.firstWhere((order) => order.id == selectedOrderId, orElse: () => pendingOrders.last);
  }

  int get paidTodayCount => paidToday.length;

  double get totalInCash => paidToday.fold(0.0, (sum, order) => sum + order.total);

  double get orderSubtotal {
    final order = selectedOrder;
    if (order == null) return 0.0;
    return order.items.fold(0.0, (sum, item) => sum + (item.qty * item.price));
  }

  double get changeDue {
    final order = selectedOrder;
    final received = receivedAmount;
    if (order == null || received == null || selectedMethod != 'Efectivo') {
      return 0.0;
    }
    final diff = received - order.total;
    return diff > 0 ? diff : 0.0;
  }

  // MÉTODOS REACTIVOS DEL CONTROLADOR (TS)
  void selectOrder(CashOrder order) {
    setState(() {
      selectedOrderId = order.id;
      cashError = '';
      if (selectedMethod == 'Efectivo') {
        receivedAmount = order.total;
        _receivedAmountController.text = order.total.toStringAsFixed(2);
      }
    });
  }

  void setPaymentMethod(PaymentMethod method) {
    setState(() {
      selectedMethod = method;
      cashError = '';

      if (method != 'Efectivo') {
        final order = selectedOrder;
        receivedAmount = order?.total;
        return;
      }

      if (receivedAmount == null) {
        final order = selectedOrder;
        receivedAmount = order?.total;
        if (receivedAmount != null) {
          _receivedAmountController.text = receivedAmount!.toStringAsFixed(2);
        }
      }
    });
  }

  void setReceivedAmount(String value) {
    final parsed = double.tryParse(value);
    setState(() {
      if (parsed == null || parsed.isNaN || parsed.isInfinite) {
        receivedAmount = null;
        return;
      }
      receivedAmount = parsed > 0 ? parsed : 0.0;
    });
  }

  void closeSelectedOrderPanel() {
    setState(() {
      selectedOrderId = null;
      cashError = '';
      receivedAmount = null;
      _receivedAmountController.clear();
    });
  }

  void chargeSelectedOrder() {
    final order = selectedOrder;
    if (order == null) return;

    if (selectedMethod == 'Efectivo') {
      final received = receivedAmount ?? 0.0;
      if (received < order.total) {
        setState(() {
          cashError = 'El monto recibido no cubre el total de la orden.';
        });
        return;
      }
    }

    setState(() {
      cashError = '';
      pendingOrders.removeWhere((entry) => entry.id == order.id);
      paidToday.insert(0, order.copyWith(status: 'Pagada'));
      selectedOrderId = null;
      receivedAmount = null;
      _receivedAmountController.clear();
      _showToast('Orden ${order.id} cobrada exitosamente', Colors.green);
    });
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // ==========================================
  // DISPOSICIÓN DE INTERFAZ DE USUARIO (HTML/CSS)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;
    final order = selectedOrder;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // SECCIÓN IZQUIERDA PRINCIPAL (caja-main)
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER DE CAJA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Caja', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const Text('Cobra órdenes y registra pagos', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        // Tarjeta de Total en Caja (cash-total-card)
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total en Caja', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                Text(_formatMoney(totalInCash), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // LISTADO DE COLUMNAS DE ÓRDENES
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BLOQUE: Órdenes por cobrar
                            Text('Órdenes por cobrar (${pendingOrders.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (pendingOrders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No hay órdenes pendientes por cobrar.', style: TextStyle(color: Colors.grey)),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingOrders.length,
                              itemBuilder: (context, index) {
                                final pOrder = pendingOrders[index];
                                final isSelected = selectedOrderId == pOrder.id;
                                return Card(
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(25) : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 1.5)
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => selectOrder(pOrder),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(pOrder.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                                  const SizedBox(width: 8),
                                                  Text(pOrder.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: pOrder.status == 'Pendiente' ? Colors.orange.withAlpha(40) : Colors.blue.withAlpha(40),
                                                      borderRadius: BorderRadius.circular(4)
                                                    ),
                                                    child: Text(pOrder.status, style: TextStyle(color: pOrder.status == 'Pendiente' ? Colors.orange : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  )
                                                ],
                                              ),
                                              Text(_formatMoney(pOrder.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${pOrder.itemsCount} platillos', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              Text(pOrder.time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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

                            // BLOQUE: Cobradas hoy
                            Text('Cobradas hoy ($paidTodayCount)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paidToday.length,
                              itemBuilder: (context, index) {
                                final pToday = paidToday[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(pToday.id, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            const Text('✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Text(_formatMoney(pToday.total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // SECCIÓN DERECHA: ASIDE PANEL DE COBRO (payment-panel)
            if (isDesktop)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1))
                ),
                child: order != null ? _buildPaymentPanel(order) : _buildEmptyPanel(),
              )
          ],
        ),
      ),
      // Respaldo flotante o modal inferior para móviles si hay una orden abierta
      bottomSheet: (!isDesktop && order != null)
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: _buildPaymentPanel(order),
              ),
            )
          : null,
    );
  }

  // PANEL DE DETALLE DE PAGO ACTIVO
  Widget _buildPaymentPanel(CashOrder order) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.id, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${order.label} · ${order.time}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Pendiente', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: closeSelectedOrderPanel)
                ],
              )
            ],
          ),
          const Divider(height: 24),
          
          // desglose de productos (payment-items)
          Expanded(
            child: ListView.builder(
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('${item.qty} x ${_formatMoney(item.price)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Text(_formatMoney(item.qty * item.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),

          // SELECTOR DE MÉTODOS DE PAGO (payment-methods)
          ToggleButtons(
            isSelected: paymentMethods.map((m) => selectedMethod == m).toList(),
            onPressed: (index) => setPaymentMethod(paymentMethods[index]),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 115),
            children: paymentMethods.map((m) => Text(m)).toList(),
          ),
          const SizedBox(height: 16),

          // CAMPO DINÁMICO SI ES EFECTIVO (payment-field)
          if (selectedMethod == 'Efectivo') ...[
            const Text('Monto recibido', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _receivedAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '0.00'),
              onChanged: setReceivedAmount,
            ),
            const SizedBox(height: 16),
          ],

          // RESUMEN FINANCIERO (payment-summary)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(_formatMoney(orderSubtotal)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_formatMoney(order.total, ), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (selectedMethod == 'Efectivo') ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cambio', style: TextStyle(color: Colors.blueGrey)),
                      Text(_formatMoney(changeDue), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ],
                  ),
                ]
              ],
            ),
          ),
          
          if (cashError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(cashError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: chargeSelectedOrder,
              child: const Text('Confirmar cobro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // PANEL VACÍO DE ESPERA (emptyPanel)
  Widget _buildEmptyPanel() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💳', style: TextStyle(fontSize: 48)),
            SizedBox(height: 10),
            Text('Selecciona una orden para cobrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Cuando elijas una orden, aquí aparecerá el detalle de cobro.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// Extensiones de utilidad añadidas para la consistencia del slicing en Dart
extension StringSlice on String {
  String slice(int start, int end) => substring(start, end);
}