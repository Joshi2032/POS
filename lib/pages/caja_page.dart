import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/ordenes_provider.dart' hide RestaurantOrder, OrderStatus, ServiceType;
import '../providers/caja_provider.dart' hide RestaurantOrder;

// Modelos
import '../models/restaurant_order.dart';
import '../ui_models/cash_order.dart';

// Servicios y UI
import '../services/printer_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<OrdenesProvider>().cargarOrdenes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordenesProvider = context.watch<OrdenesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ordenesPendientes = ordenesProvider.orders
        .where((o) => o.status != 'paid' && o.status != 'cancelled')
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '💰 Módulo de Caja',
              subtitle:
                  '${ordenesPendientes.length} cuentas pendientes de cobro',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ordenesPendientes.isEmpty
                  ? const EmptyState(
                      message: 'No hay cuentas pendientes por cobrar.',
                      icon: Icons.check_circle_outline,
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: ordenesPendientes.length,
                      itemBuilder: (context, index) {
                        final orden = ordenesPendientes[index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      orden.orderNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Por Cobrar',
                                      style: TextStyle(
                                          color: Colors.orange[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                orden.tableOrCustomer,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[700]),
                              ),
                              const Spacer(),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '\$${orden.totalAmount.toStringAsFixed(2)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _abrirModalCobro(context, orden),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text('Cobrar',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalCobro(BuildContext context, RestaurantOrder orden) {
    final cajaProvider = context.read<CajaProvider>();
    
    final cashOrder = cajaProvider.pendingOrders.firstWhere(
      (co) => co.id == orden.id,
      orElse: () => CashOrder(
        id: orden.id,
        label: orden.orderNumber,
        time: orden.time,
        status: orden.status,
        itemsCount: orden.items.length,
        items: [],
        total: orden.totalAmount,
      ),
    );
    
    cajaProvider.selectOrder(cashOrder);
    
    String metodoPago = 'cash'; 
    cajaProvider.setPaymentMethod('Efectivo');
    
    final TextEditingController montoRecibidoCtrl =
        TextEditingController(text: orden.totalAmount.toStringAsFixed(2));
    cajaProvider.setReceivedAmount(montoRecibidoCtrl.text);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          final double total = orden.totalAmount;
          final double recibido =
              double.tryParse(montoRecibidoCtrl.text) ?? 0.0;
          final double cambio = recibido >= total ? recibido - total : 0.0;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Procesar Cobro',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Orden: ${orden.orderNumber} - ${orden.tableOrCustomer}',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Total a pagar: \$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 24),
                    const Text('Método de pago:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Efectivo'),
                            selected: metodoPago == 'cash',
                            onSelected: (val) {
                                setModalState(() => metodoPago = 'cash');
                                cajaProvider.setPaymentMethod('Efectivo');
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                                color:
                                    metodoPago == 'cash' ? Colors.white : null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Tarjeta'),
                            selected: metodoPago == 'card',
                            onSelected: (val) {
                                setModalState(() => metodoPago = 'card');
                                cajaProvider.setPaymentMethod('Tarjeta');
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                                color:
                                    metodoPago == 'card' ? Colors.white : null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Transf.'),
                            selected: metodoPago == 'transfer',
                            onSelected: (val) {
                                setModalState(() => metodoPago = 'transfer');
                                cajaProvider.setPaymentMethod('Transferencia');
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                                color: metodoPago == 'transfer'
                                    ? Colors.white
                                    : null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (metodoPago == 'cash') ...[
                      TextField(
                        controller: montoRecibidoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Efectivo recibido',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                            setModalState(() {});
                            cajaProvider.setReceivedAmount(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cambio a devolver:',
                                style: TextStyle(fontSize: 16)),
                            Text('\$${cambio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                    cajaProvider.closeSelectedOrderPanel();
                    Navigator.pop(dialogContext);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 45)),
                onPressed: () async {
                  if (metodoPago == 'cash' && recibido < total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Error: El monto recibido es menor al total de la cuenta.'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  // 1. CAPTURAR DEPENDENCIAS ANTES DEL ASYNC/AWAIT
                  final ordenesProvider = context.read<OrdenesProvider>();
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()));

                  // 2. EJECUTAR OPERACIONES ASÍNCRONAS
                  final bool exito = await cajaProvider.chargeSelectedOrder();
                  await ordenesProvider.cambiarEstadoOrden(orden.id, 'paid');

                  // 3. VERIFICAR SI LA VISTA SIGUE EN PANTALLA
                  if (!context.mounted) return; 

                  Navigator.pop(context); // Cierra loader

                  if (exito) {
                    bool printSuccess =
                        await PrinterService.imprimirTicketCaja(orden);

                    // 4. VERIFICAR DE NUEVO TRAS IMPRESIÓN ASÍNCRONA
                    if (!context.mounted) return; 

                    if (printSuccess) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content:
                                Text('Cobro exitoso e imprimiendo ticket...'),
                            backgroundColor: Colors.green),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cobro exitoso, pero revisa la impresora (Sin conexión).'),
                            backgroundColor: Colors.orange),
                      );
                    }

                    Navigator.pop(dialogContext); // Cierra modal
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                          content: Text(cajaProvider.cashError.isNotEmpty 
                              ? cajaProvider.cashError 
                              : 'Hubo un error al guardar el pago en la base de datos.'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Confirmar y Cobrar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }
}