import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/ordenes_provider.dart';

// Modelos
import '../models/restaurant_order.dart';

// Servicios y UI
import '../services/printer_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart'; // Agregamos la importación para EmptyState

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  @override
  void initState() {
    super.initState();
    // Refrescamos las órdenes pendientes cuando entramos a la caja
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

    // FIX: Cambiamos .ordenes a .orders según tu OrdenesProvider
    final ordenesPendientes = ordenesProvider.orders.where((o) => 
      o.status != 'paid' && o.status != 'cancelled'
    ).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '💰 Módulo de Caja',
              subtitle: '${ordenesPendientes.length} cuentas pendientes de cobro',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ordenesPendientes.isEmpty
                  ? const EmptyState(
                      message: 'No hay cuentas pendientes por cobrar.',
                      icon: Icons.check_circle_outline,
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    orden.orderNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Por Cobrar',
                                      style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                orden.tableOrCustomer,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
                              ),
                              const Spacer(),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${orden.totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _abrirModalCobro(context, orden),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text('Cobrar', style: TextStyle(fontWeight: FontWeight.bold)),
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
    String metodoPago = 'cash'; // cash, card, transfer
    final TextEditingController montoRecibidoCtrl = TextEditingController(text: orden.totalAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double total = orden.totalAmount;
            final double recibido = double.tryParse(montoRecibidoCtrl.text) ?? 0.0;
            final double cambio = recibido >= total ? recibido - total : 0.0;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Procesar Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Orden: ${orden.orderNumber} - ${orden.tableOrCustomer}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('Total a pagar: \$${total.toStringAsFixed(2)}', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      const SizedBox(height: 24),
                      const Text('Método de pago:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Efectivo'),
                              selected: metodoPago == 'cash',
                              onSelected: (val) => setModalState(() => metodoPago = 'cash'),
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(color: metodoPago == 'cash' ? Colors.white : null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tarjeta'),
                              selected: metodoPago == 'card',
                              onSelected: (val) => setModalState(() => metodoPago = 'card'),
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(color: metodoPago == 'card' ? Colors.white : null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Transf.'),
                              selected: metodoPago == 'transfer',
                              onSelected: (val) => setModalState(() => metodoPago = 'transfer'),
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(color: metodoPago == 'transfer' ? Colors.white : null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (metodoPago == 'cash') ...[
                        TextField(
                          controller: montoRecibidoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Efectivo recibido',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => setModalState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3))
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cambio a devolver:', style: TextStyle(fontSize: 16)),
                              Text('\$${cambio.toStringAsFixed(2)}', 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600], 
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 45)
                  ),
                  onPressed: () async {
                    if (metodoPago == 'cash' && recibido < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: El monto recibido es menor al total de la cuenta.'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    showDialog(
                      context: context, 
                      barrierDismissible: false, 
                      builder: (_) => const Center(child: CircularProgressIndicator())
                    );

                    final ordenesProvider = context.read<OrdenesProvider>();

                    // FIX: Cambiamos a .cambiarEstadoOrden según tu OrdenesProvider
                    final bool exito = await ordenesProvider.cambiarEstadoOrden(orden.id, 'paid');

                    if (context.mounted) Navigator.pop(context); 

                    if (exito && context.mounted) {
                      
                      bool printSuccess = await PrinterService.imprimirTicketCaja(orden);

                      if (context.mounted) {
                        if (printSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cobro exitoso e imprimiendo ticket...'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cobro exitoso, pero revisa la impresora (Sin conexión).'), backgroundColor: Colors.orange),
                          );
                        }
                        
                        Navigator.pop(dialogContext);
                        ordenesProvider.cargarOrdenes();
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ordenesProvider.errorMessage ?? 'Hubo un error al guardar el pago.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Confirmar y Cobrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}