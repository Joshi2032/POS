import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/ordenes_provider.dart';
import '../providers/caja_provider.dart';

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

    final ordenesPendientes = ordenesProvider.orders.where((o) {
      final status = o.status.toLowerCase().trim();

      return status == 'pending' ||
          status == 'pendiente' ||
          status == 'preparing' ||
          status == 'preparando';
    }).toList();

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

                        final esParaLlevar = orden.serviceType == 'llevar' ||
                            orden.serviceType == 'takeout';

                        final identificador = esParaLlevar
                            ? 'Para llevar'
                            : orden.tableOrCustomer.trim();

                        final tituloOrden = identificador.isEmpty
                            ? 'Mesa sin identificar'
                            : identificador;

                        final iconoOrden = esParaLlevar
                            ? Icons.shopping_bag_outlined
                            : Icons.table_restaurant_outlined;

                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              iconoOrden,
                                              size: 22,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                tituloOrden,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          orden.orderNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Por cobrar',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                    child: const Text(
                                      'Cobrar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double total = orden.totalAmount;
            final double recibido =
                double.tryParse(montoRecibidoCtrl.text) ?? 0.0;
            final double cambio = recibido >= total ? recibido - total : 0.0;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Procesar Cobro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden: ${orden.orderNumber} - ${orden.tableOrCustomer}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total a pagar: \$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Método de pago:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Efectivo'),
                              selected: metodoPago == 'cash',
                              onSelected: (_) {
                                setModalState(() {
                                  metodoPago = 'cash';
                                });
                                cajaProvider.setPaymentMethod('Efectivo');
                              },
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(
                                color:
                                    metodoPago == 'cash' ? Colors.white : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tarjeta'),
                              selected: metodoPago == 'card',
                              onSelected: (_) {
                                setModalState(() {
                                  metodoPago = 'card';
                                });
                                cajaProvider.setPaymentMethod('Tarjeta');
                              },
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(
                                color:
                                    metodoPago == 'card' ? Colors.white : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Transf.'),
                              selected: metodoPago == 'transfer',
                              onSelected: (_) {
                                setModalState(() {
                                  metodoPago = 'transfer';
                                });
                                cajaProvider.setPaymentMethod(
                                  'Transferencia',
                                );
                              },
                              selectedColor: Theme.of(context).primaryColor,
                              labelStyle: TextStyle(
                                color: metodoPago == 'transfer'
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (metodoPago == 'cash') ...[
                        TextField(
                          controller: montoRecibidoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Efectivo recibido',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cambio a devolver:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '\$${cambio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    minimumSize: const Size(120, 45),
                  ),
                  onPressed: () async {
                    if (metodoPago == 'cash' && recibido < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Error: El monto recibido es menor al total de la cuenta.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final bool exito = await cajaProvider.chargeSelectedOrder();

                    if (!context.mounted) return;

                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop();

                    if (exito) {
                      Navigator.pop(dialogContext);

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Orden ${orden.orderNumber} cobrada correctamente.',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      final bool printSuccess =
                          await PrinterService.imprimirTicketCaja(
                        orden,
                      );

                      if (!context.mounted) return;

                      if (!printSuccess) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El cobro fue exitoso, pero revisa la conexión de la impresora.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            cajaProvider.cashError.isNotEmpty
                                ? cajaProvider.cashError
                                : 'No se pudo guardar el pago.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Confirmar y Cobrar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      montoRecibidoCtrl.dispose();
    });
  }
}
