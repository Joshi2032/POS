import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/ordenes_provider.dart';
import '../providers/mesas_provider.dart';
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
  final Set<String> _ordenesExpandidas = {};

  void _alternarExpansion(String orderId) {
    setState(() {
      if (_ordenesExpandidas.contains(orderId)) {
        _ordenesExpandidas.remove(orderId);
      } else {
        _ordenesExpandidas.add(orderId);
      }
    });
  }

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
          status == 'preparando' ||
          status == 'ready' ||
          status == 'lista' ||
          status == 'delivered' ||
          status == 'entregada';
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
              child: RefreshIndicator(
                onRefresh: () => context.read<OrdenesProvider>().cargarOrdenes(),
                child: ordenesPendientes.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: const EmptyState(
                              message: 'No hay cuentas pendientes por cobrar.',
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                        );
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 16.0;
                        const cardWidth = 340.0;

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: ordenesPendientes.map((orden) {
                              final serviceType =
                                  orden.serviceType.toLowerCase().trim();

                              final esParaLlevar = serviceType == 'llevar' ||
                                  serviceType == 'takeout';

                              final identificador = esParaLlevar
                                  ? 'Para llevar'
                                  : orden.tableOrCustomer.trim();

                              final tituloOrden = identificador.isEmpty ||
                                      identificador.toLowerCase() == 'sin mesa'
                                  ? esParaLlevar
                                      ? 'Para llevar'
                                      : 'Mesa sin identificar'
                                  : identificador;

                              final iconoOrden = esParaLlevar
                                  ? Icons.shopping_bag_outlined
                                  : Icons.table_restaurant_outlined;

                              final expandida =
                                  _ordenesExpandidas.contains(orden.id);

                              final anchoDisponible =
                                  constraints.maxWidth < cardWidth
                                      ? constraints.maxWidth
                                      : cardWidth;

                              return SizedBox(
                                width: anchoDisponible,
                                child: AppCard(
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () =>
                                              _alternarExpansion(orden.id),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      iconoOrden,
                                                      size: 22,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            tituloOrden,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 19,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            orden.orderNumber,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isDark
                                                                  ? Colors
                                                                      .white54
                                                                  : Colors.grey[
                                                                      600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange
                                                            .withValues(
                                                          alpha: 0.2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          8,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Por cobrar',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .orange[800],
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${orden.items.length} producto(s)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? Colors.white60
                                                            : Colors.grey[700],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Icon(
                                                      expandida
                                                          ? Icons
                                                              .keyboard_arrow_up
                                                          : Icons
                                                              .keyboard_arrow_down,
                                                      color: Colors.grey,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (expandida) ...[
                                          const Divider(height: 20),
                                          const Text(
                                            'Productos de la orden',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (orden.items.isEmpty)
                                            const Text(
                                              'No hay productos registrados.',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            )
                                          else
                                            ...orden.items.map((item) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 5,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 30,
                                                      height: 30,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          7,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '${item.quantity}x',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.productName,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          Text(
                                                            '\$${item.total.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: isDark
                                                                  ? Colors
                                                                      .white60
                                                                  : Colors.grey[
                                                                      600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        _repetirProducto(
                                                          context,
                                                          orden,
                                                          item,
                                                        );
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.replay,
                                                        size: 15,
                                                      ),
                                                      label: const Text(
                                                        'Repetir',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          if (orden.notes != null &&
                                              orden.notes!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Notas: ${orden.notes}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '\$${orden.calculatedTotal.toStringAsFixed(2)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                _abrirModalCobro(
                                                  context,
                                                  orden,
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green[600],
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Cobrar',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _repetirProducto(
    BuildContext context,
    RestaurantOrder orden,
    dynamic item,
  ) async {
    final ordenesProvider = context.read<OrdenesProvider>();

    final messenger = ScaffoldMessenger.of(context);

    final productId = item.productId?.toString().trim() ?? '';

    if (productId.isEmpty || productId == 'null') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Este producto no tiene un identificador válido.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ordenesProvider.agregarItemsAOrden(
        orden.id,
        [
          {
            'product_name': item.productName,
            'product_id': productId,
            'quantity': 1,
            'unit_price': item.unitPrice,
            'total': item.unitPrice,
          },
        ],
      );

      if (ordenesProvider.errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ordenesProvider.errorMessage ?? 'No se pudo repetir el producto.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await ordenesProvider.cargarOrdenes();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Se agregó otro ${item.productName} a la orden.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo repetir el producto: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirModalCobro(
    BuildContext context,
    RestaurantOrder orden,
  ) {
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
        total: orden.calculatedTotal > 0
            ? orden.calculatedTotal
            : orden.totalAmount,
      ),
    );

    cajaProvider.selectOrder(cashOrder);

    String metodoPago = 'cash';

    cajaProvider.setPaymentMethod('Efectivo');

    final montoRecibidoCtrl = TextEditingController(
      text: (orden.calculatedTotal > 0
              ? orden.calculatedTotal
              : orden.totalAmount)
          .toStringAsFixed(2),
    );

    cajaProvider.setReceivedAmount(
      montoRecibidoCtrl.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final total = orden.calculatedTotal > 0
                ? orden.calculatedTotal
                : orden.totalAmount;

            final recibido = double.tryParse(
                  montoRecibidoCtrl.text,
                ) ??
                0.0;

            final cambio = recibido >= total ? recibido - total : 0.0;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            final serviceType = orden.serviceType.toLowerCase().trim();

            final esParaLlevar =
                serviceType == 'llevar' || serviceType == 'takeout';

            final nombreOrden = esParaLlevar
                ? 'Para llevar'
                : orden.tableOrCustomer.trim().isEmpty ||
                        orden.tableOrCustomer.trim().toLowerCase() == 'sin mesa'
                    ? 'Mesa sin identificar'
                    : orden.tableOrCustomer;

            final anchoPantalla = MediaQuery.sizeOf(dialogContext).width;

            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: anchoPantalla < 480 ? 16 : 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Procesar Cobro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: anchoPantalla < 440 ? double.infinity : 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            esParaLlevar
                                ? Icons.shopping_bag_outlined
                                : Icons.table_restaurant_outlined,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nombreOrden,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Orden: ${orden.orderNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text(
                                'Efectivo',
                              ),
                              selected: metodoPago == 'cash',
                              onSelected: (_) {
                                setModalState(() {
                                  metodoPago = 'cash';
                                });

                                cajaProvider.setPaymentMethod(
                                  'Efectivo',
                                );
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
                              label: const Text(
                                'Tarjeta',
                              ),
                              selected: metodoPago == 'card',
                              onSelected: (_) {
                                setModalState(() {
                                  metodoPago = 'card';
                                });

                                cajaProvider.setPaymentMethod(
                                  'Tarjeta',
                                );
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
                              label: const Text(
                                'Transf.',
                              ),
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
                              borderRadius: BorderRadius.circular(
                                8,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {});

                            cajaProvider.setReceivedAmount(
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(
                            12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.withValues(
                                    alpha: 0.1,
                                  )
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                            border: Border.all(
                              color: Colors.green.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cambio a devolver:',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
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

                    Navigator.pop(
                      dialogContext,
                    );
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

                    final scaffoldMessenger = ScaffoldMessenger.of(
                      context,
                    );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final exito = await cajaProvider.chargeSelectedOrder();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop();

                    if (exito) {
                      final mesasProvider = context.read<MesasProvider>();
                      final ordenesProvider = context.read<OrdenesProvider>();

                      await mesasProvider.cargarMesas();
                      await ordenesProvider.cargarOrdenes();

                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pop(
                        dialogContext,
                      );

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Orden ${orden.orderNumber} cobrada correctamente.',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(
                            seconds: 2,
                          ),
                        ),
                      );

                      if (cajaProvider.cashWarning != null) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(cajaProvider.cashWarning!),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }

                      final printSuccess =
                          await PrinterService.imprimirTicketCaja(
                        orden,
                      );

                      if (!context.mounted) {
                        return;
                      }

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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
