import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/caja_provider.dart';

// ==========================================
// COMPONENTE PRINCIPAL DE INTERFAZ (UI)
// ==========================================
class CajaPage extends StatelessWidget {
  const CajaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el cerebro para el módulo de cobro
    return ChangeNotifierProvider(
      create: (_) => CajaProvider(),
      child: const _CajaView(),
    );
  }
}

// Al separar la lógica, esta vista ya no necesita manejar "Estado" propio
class _CajaView extends StatelessWidget {
  const _CajaView();

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showToast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 950;
    
    // Conectamos la interfaz al Provider
    final provider = context.watch<CajaProvider>();
    final order = provider.selectedOrder;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // SECCIÓN IZQUIERDA PRINCIPAL
            Expanded(
              flex: 6,
              child: Padding(
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
                            Text('Caja', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const Text('Cobra órdenes y registra pagos', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total en Caja', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                Text(_formatMoney(provider.totalInCash), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // LISTADO DE ÓRDENES
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Órdenes por cobrar (${provider.pendingOrders.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (provider.pendingOrders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No hay órdenes pendientes por cobrar.', style: TextStyle(color: Colors.grey)),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.pendingOrders.length,
                              itemBuilder: (context, index) {
                                final pOrder = provider.pendingOrders[index];
                                final isSelected = provider.selectedOrderId == pOrder.id;
                                return Card(
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(25) : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 1.5)
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => provider.selectOrder(pOrder),
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

                            Text('Cobradas hoy (${provider.paidTodayCount})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.paidToday.length,
                              itemBuilder: (context, index) {
                                final pToday = provider.paidToday[index];
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

            // SECCIÓN DERECHA: ASIDE PANEL DE COBRO (Escritorio)
            if (isDesktop)
              Container(
                width: 400,
                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1))),
                child: order != null ? _buildPaymentPanel(context, provider, order) : _buildEmptyPanel(),
              )
          ],
        ),
      ),
      // Respaldo flotante modal para móviles si hay una orden abierta
      bottomSheet: (!isDesktop && order != null)
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: _buildPaymentPanel(context, provider, order),
              ),
            )
          : null,
    );
  }

  // WIDGET EXTRAÍDO: PANEL DE DETALLE DE PAGO
  Widget _buildPaymentPanel(BuildContext context, CajaProvider provider, CashOrder order) {
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
                  IconButton(icon: const Icon(Icons.close), onPressed: provider.closeSelectedOrderPanel)
                ],
              )
            ],
          ),
          const Divider(height: 24),
          
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

          ToggleButtons(
            isSelected: provider.paymentMethods.map((m) => provider.selectedMethod == m).toList(),
            onPressed: (index) => provider.setPaymentMethod(provider.paymentMethods[index]),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 115),
            children: provider.paymentMethods.map((m) => Text(m)).toList(),
          ),
          const SizedBox(height: 16),

          if (provider.selectedMethod == 'Efectivo') ...[
            const Text('Monto recibido', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: provider.receivedAmountController, // Usando el controlador del cerebro
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '0.00'),
              onChanged: provider.setReceivedAmount,
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(_formatMoney(provider.orderSubtotal)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_formatMoney(order.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (provider.selectedMethod == 'Efectivo') ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cambio', style: TextStyle(color: Colors.blueGrey)),
                      Text(_formatMoney(provider.changeDue), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ],
                  ),
                ]
              ],
            ),
          ),
          
          if (provider.cashError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(provider.cashError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                final success = provider.chargeSelectedOrder();
                if (success) {
                  _showToast(context, 'Orden cobrada exitosamente', Colors.green);
                }
              },
              child: const Text('Confirmar cobro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

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