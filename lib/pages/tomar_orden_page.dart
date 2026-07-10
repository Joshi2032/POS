import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/order_item.dart';
import '../models/restaurant_order.dart';

import '../providers/auth_provider.dart';
import '../providers/mesas_provider.dart';
import '../providers/ordenes_provider.dart';
import '../providers/tomar_orden_provider.dart';

class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

enum _Layout {
  mobile,
  tablet,
  desktop,
}

class TomarOrdenPage extends StatelessWidget {
  const TomarOrdenPage({super.key});

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF13131A) : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width >= _Breakpoints.desktop) {
              return Row(
                children: [
                  const Expanded(
                    flex: 7,
                    child: _MenuSection(
                      layout: _Layout.desktop,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300],
                  ),
                  const SizedBox(
                    width: 380,
                    child: _CartSection(
                      layout: _Layout.desktop,
                    ),
                  ),
                ],
              );
            }

            if (width >= _Breakpoints.tablet) {
              return Row(
                children: [
                  const Expanded(
                    flex: 6,
                    child: _MenuSection(
                      layout: _Layout.tablet,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300],
                  ),
                  const Expanded(
                    flex: 4,
                    child: _CartSection(
                      layout: _Layout.tablet,
                    ),
                  ),
                ],
              );
            }

            return const _MenuSection(
              layout: _Layout.mobile,
            );
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final width = MediaQuery.sizeOf(context).width;

          if (width >= _Breakpoints.tablet) {
            return const SizedBox.shrink();
          }

          final total = context.select<TomarOrdenProvider, double>(
            (provider) => provider.totalConOrdenExistente,
          );

          final count = context.select<TomarOrdenProvider, int>(
            (provider) => provider.itemsCountConOrdenExistente,
          );

          return FloatingActionButton.extended(
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () {
              _openMobileCart(context);
            },
            icon: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
            ),
            label: Text(
              '${_formatCurrency(total)} ($count)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMobileCart(BuildContext context) {
    final provider = context.read<TomarOrdenProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.80,
            child: const _CartSection(
              layout: _Layout.mobile,
            ),
          ),
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.layout,
  });

  final _Layout layout;

  bool get isCompact => layout == _Layout.mobile;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey[600];

    final searchFillColor = isDark ? const Color(0xFF1E1E2D) : Colors.grey[100];

    final cardColor = isDark ? const Color(0xFF1E1E2D) : Colors.white;

    return Padding(
      padding: EdgeInsets.all(
        isCompact ? 14 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tomar Orden',
            style: TextStyle(
              fontSize: isCompact ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Registra los productos del cliente',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TypeButton(
                label: 'Comer Aquí',
                type: OrderType.dineIn,
                layout: layout,
              ),
              const SizedBox(width: 8),
              _TypeButton(
                label: 'Para Llevar',
                type: OrderType.takeaway,
                layout: layout,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.orderType == OrderType.dineIn) ...[
            Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(
                    'Orden:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),

                ChoiceChip(
                  label: const Text('Nueva'),
                  selected: !provider.isExistingTable,
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(
                    color: !provider.isExistingTable ? Colors.white : textColor,
                  ),
                  onSelected: (selected) async {
                    if (!selected) return;

                    await context
                        .read<TomarOrdenProvider>()
                        .setIsExistingTable(false);
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Existente'),
                  selected: provider.isExistingTable,
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(
                    color: provider.isExistingTable ? Colors.white : textColor,
                  ),
                  onSelected: (selected) async {
                    if (!selected) return;

                    await _mostrarOrdenesExistentes(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ChipsRow(
              label: 'Área:',
              options: provider.availableAreas,
              selected: provider.selectedArea,
              onSelected: context.read<TomarOrdenProvider>().setArea,
            ),
            const SizedBox(height: 12),
            _ChipsRow(
              label: 'Mesa:',
              options: provider.currentTables,
              selected: provider.selectedTableName,
              emptyMessage: provider.isExistingTable
                  ? 'No hay mesas ocupadas'
                  : 'No hay mesas libres',
              onSelected: context.read<TomarOrdenProvider>().setTable,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            style: TextStyle(
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              filled: true,
              fillColor: searchFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: context.read<TomarOrdenProvider>().setSearchTerm,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.categories.map((category) {
                final selected = provider.selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                    bottom: 4,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                      ),
                    ),
                    selected: selected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textColor,
                    ),
                    onSelected: (_) {
                      context.read<TomarOrdenProvider>().setCategory(category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: provider.visibleProducts.isEmpty
                ? Center(
                    child: Text(
                      'No hay productos encontrados.',
                      style: TextStyle(
                        color: secondaryTextColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = provider.visibleProducts[index];

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            context.read<TomarOrdenProvider>().addToCart(
                                  product,
                                );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 12 : 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isCompact ? 14 : 16,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 6,
                                      ),
                                      Text(
                                        product.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: isCompact ? 11 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isCompact ? 13 : 14,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context
                                            .read<TomarOrdenProvider>()
                                            .addToCart(
                                              product,
                                            );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.add,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Agregar',
                                        style: TextStyle(
                                          fontSize: 12,
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
                    },
                  ),
          ),
          if (isCompact) const SizedBox(height: 72),
        ],
      ),
    );
  }
}

Future<void> _mostrarOrdenesExistentes(
  BuildContext context,
) async {
  final ordenesProvider = context.read<OrdenesProvider>();

  final tomarOrdenProvider = context.read<TomarOrdenProvider>();

  await ordenesProvider.cargarOrdenes();

  if (!context.mounted) return;

  final ordenesExistentes = ordenesProvider.orders.where((order) {
    final status = order.status.toLowerCase().trim();

    final serviceType = order.serviceType.toLowerCase().trim();

    final esActiva = status == 'pendiente' ||
        status == 'preparando' ||
        status == 'pending' ||
        status == 'preparing';

    final esComedor = serviceType == 'comedor' || serviceType == 'dine_in';

    final tieneMesa = order.tableId != null && order.tableId!.trim().isNotEmpty;

    return esActiva && esComedor && tieneMesa;
  }).toList();

  if (ordenesExistentes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No hay órdenes existentes en mesas ocupadas.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  String? ordenExpandidaId;
  RestaurantOrder? ordenSeleccionada;

  final resultado = await showDialog<RestaurantOrder>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {
          final tamanoPantalla = MediaQuery.sizeOf(dialogContext);

          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: tamanoPantalla.width < 600 ? 16 : 40,
              vertical: 24,
            ),
            title: const Text(
              'Seleccionar orden existente',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: tamanoPantalla.width < 600
                  ? double.infinity
                  : 560,
              height: tamanoPantalla.height < 600
                  ? tamanoPantalla.height * 0.7
                  : 500,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selecciona una orden para revisar lo que ya pidió el cliente.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: ordenesExistentes.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: 10,
                      ),
                      itemBuilder: (context, index) {
                        final order = ordenesExistentes[index];

                        final expandida = ordenExpandidaId == order.id;

                        final seleccionada = ordenSeleccionada?.id == order.id;

                        final totalMostrado = order.calculatedTotal > 0
                            ? order.calculatedTotal
                            : order.totalAmount;

                        return Card(
                          elevation: seleccionada ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                            side: BorderSide(
                              color: seleccionada
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              width: seleccionada ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    if (expandida) {
                                      ordenExpandidaId = null;

                                      if (seleccionada) {
                                        ordenSeleccionada = null;
                                      }
                                    } else {
                                      ordenExpandidaId = order.id;

                                      ordenSeleccionada = order;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.table_restaurant_outlined,
                                        color: Theme.of(
                                          context,
                                        ).primaryColor,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.tableOrCustomer,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 3,
                                            ),
                                            Text(
                                              '${order.orderNumber} • ${order.time}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${totalMostrado.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Icon(
                                        expandida
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (expandida) ...[
                                const Divider(
                                  height: 1,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Productos solicitados',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      if (order.items.isEmpty)
                                        const Text(
                                          'Esta orden no tiene productos registrados.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        )
                                      else
                                        ...order.items.map(
                                          (item) {
                                            final itemTotal = item.total > 0
                                                ? item.total
                                                : item.unitPrice *
                                                    item.quantity;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 34,
                                                    alignment: Alignment.center,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor.withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '${item.quantity}x',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      item.productName,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${itemTotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      if (order.notes != null &&
                                          order.notes!.trim().isNotEmpty) ...[
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Notas: ${order.notes}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Divider(
                                        height: 20,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total actual:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '\$${totalMostrado.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (ordenExpandidaId != null)
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      ordenExpandidaId = null;
                      ordenSeleccionada = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Regresar'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Cancelar',
                ),
              ),
              ElevatedButton.icon(
                onPressed: ordenSeleccionada == null
                    ? null
                    : () {
                        Navigator.pop(
                          dialogContext,
                          ordenSeleccionada,
                        );
                      },
                icon: const Icon(
                  Icons.check,
                ),
                label: const Text(
                  'Confirmar orden',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (resultado == null || resultado.tableId == null || !context.mounted) {
    return;
  }

  final totalResultado = resultado.calculatedTotal > 0
      ? resultado.calculatedTotal
      : resultado.totalAmount;

  final itemsCountResultado = resultado.items.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );

  await tomarOrdenProvider.seleccionarOrdenExistente(
    orderId: resultado.id,
    orderNumber: resultado.orderNumber,
    tableId: resultado.tableId!,
    totalAmount: totalResultado,
    itemsCount: itemsCountResultado,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Orden ${resultado.orderNumber} seleccionada para ${resultado.tableOrCustomer}.',
      ),
      backgroundColor: Colors.green,
    ),
  );
}

class _CartSection extends StatelessWidget {
  const _CartSection({
    required this.layout,
  });

  final _Layout layout;

  bool get isMobile => layout == _Layout.mobile;

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark ? Colors.white60 : Colors.grey;

    final cardColor = isDark ? const Color(0xFF1E1E2D) : Colors.white;

    final countBackground = isDark ? const Color(0xFF232334) : Colors.grey[200];

    final orderType = provider.orderType;
    final cart = provider.cart;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            10,
            14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderType == OrderType.dineIn
                          ? provider.selectedTableName
                          : 'Para Llevar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      orderType == OrderType.dineIn
                          ? provider.isExistingTable
                              ? provider.hasSelectedExistingOrder
                                  ? 'Agregar a orden ${provider.selectedExistingOrderNumber}'
                                  : 'Agregar a orden existente'
                              : 'Nueva orden en mesa'
                          : 'Recoger en cocina',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: countBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.itemsCountConOrdenExistente} Items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (isMobile)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: textColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (provider.isExistingTable && provider.hasSelectedExistingOrder)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Orden actual: ${_formatCurrency(provider.selectedExistingOrderTotal)}. '
                'Aquí solo se muestran productos nuevos por agregar.',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text(
                    provider.isExistingTable && provider.hasSelectedExistingOrder
                        ? 'Agrega productos nuevos a esta orden'
                        : 'Selecciona productos para la orden',
                    style: TextStyle(
                      color: secondaryTextColor,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    return _CartItemTile(
                      item: cart[index],
                      isDark: isDark,
                      textColor: textColor,
                      cardColor: cardColor,
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Notas, por ejemplo: sin cebolla',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 12,
                  ),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                onChanged: context.read<TomarOrdenProvider>().setNotes,
              ),
              const SizedBox(height: 12),
              if (provider.isExistingTable && provider.hasSelectedExistingOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nuevo agregado:',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        _formatCurrency(provider.total),
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.isExistingTable && provider.hasSelectedExistingOrder
                        ? 'Total actualizado:'
                        : 'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _formatCurrency(
                      provider.totalConOrdenExistente,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.isEmpty || provider.isSendingOrder
                      ? null
                      : () {
                          _confirmarOrden(
                            context,
                            provider,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: provider.isSendingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          provider.isExistingTable &&
                                  provider.hasSelectedExistingOrder
                              ? 'Agregar a Cocina'
                              : 'Enviar a Cocina',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarOrden(
    BuildContext context,
    TomarOrdenProvider provider,
  ) async {
    if (provider.orderType == OrderType.dineIn &&
        provider.selectedTable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isExistingTable
                ? 'No hay mesas ocupadas disponibles.'
                : 'No hay mesas libres disponibles.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar envío'),
          content: Text(
            provider.isExistingTable && provider.orderType == OrderType.dineIn
                ? '¿Agregar estos productos a la orden de ${provider.selectedTableName}?'
                : '¿Enviar la orden a cocina?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await _enviarOrden(
      context: context,
      provider: provider,
    );
  }

  Future<void> _enviarOrden({
    required BuildContext context,
    required TomarOrdenProvider provider,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final ordenesProvider = context.read<OrdenesProvider>();
    final mesasProvider = context.read<MesasProvider>();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);

    final orderType = provider.orderType;
    final selectedTable = provider.selectedTable;
    final selectedTableName = provider.selectedTableName;
    final selectedArea = provider.selectedArea;
    final isExistingTable = provider.isExistingTable;
    final notes = provider.notes.trim();

    final cartSnapshot = List<CartItem>.from(provider.cart);
    final total = provider.total;

    if (provider.isSendingOrder) {
      return;
    }

    if (cartSnapshot.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Agrega al menos un producto a la orden.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (orderType == OrderType.dineIn && selectedTable.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una mesa antes de continuar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final idComanda = 'CMD-${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now();

    final hora = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    final identificador = orderType == OrderType.dineIn
        ? '$selectedTableName (Área $selectedArea)'
        : 'Para Llevar';

    final cocinaItems = cartSnapshot.map((item) {
      return OrderItem(
        productName: item.product.name,
        productId: item.product.id,
        quantity: item.qty,
        unitPrice: item.product.price,
        total: item.total,
      );
    }).toList();

    final itemsMap = cartSnapshot.map((item) {
      return {
        'product_name': item.product.name,
        'product_id': item.product.id,
        'quantity': item.qty,
        'unit_price': item.product.price,
        'total': item.total,
      };
    }).toList();

    final nuevaOrden = RestaurantOrder(
      id: '',
      orderNumber: idComanda,
      tableId: orderType == OrderType.dineIn ? selectedTable : null,
      tableOrCustomer: identificador,
      time: hora,
      status: 'pending',
      serviceType: orderType == OrderType.dineIn ? 'comedor' : 'llevar',
      items: cocinaItems,
      totalAmount: total,
      notes: notes.isEmpty ? null : notes,
      waiterId: authProvider.userId,
      waiterName: authProvider.nombreUsuario,
    );

    String mensajeExito = 'Orden creada exitosamente';

    provider.setSendingOrder(true);

    try {
      if (orderType == OrderType.dineIn && isExistingTable) {
        if (provider.selectedExistingOrderId.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Selecciona una orden existente antes de agregar productos.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        await ordenesProvider.agregarItemsAOrden(
          provider.selectedExistingOrderId,
          itemsMap,
        );

        mensajeExito = 'Productos agregados a $selectedTableName';
      } else {
        await ordenesProvider.insertarNuevaComanda(
          nuevaOrden,
        );

        mensajeExito = orderType == OrderType.dineIn
            ? 'Orden creada para $selectedTableName'
            : 'Orden para llevar creada correctamente';
      }

      if (ordenesProvider.errorMessage != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar la orden: '
              '${ordenesProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      if (orderType == OrderType.dineIn && !isExistingTable) {
        final actualizada = await mesasProvider.cambiarEstadoMesa(
          selectedTable,
          'ocupada',
        );

        if (!actualizada) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                mesasProvider.errorMessage ??
                    'La orden se creó, pero no se pudo marcar la mesa como ocupada.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      provider.sendOrder();

      if (!context.mounted) return;

      if (isMobile && navigator.canPop()) {
        navigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(mensajeExito),
          backgroundColor: Colors.green,
        ),
      );

      router.go('/ordenes');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo procesar la orden: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      provider.setSendingOrder(false);
    }
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.type,
    required this.layout,
  });

  final String label;
  final OrderType type;
  final _Layout layout;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<TomarOrdenProvider, bool>(
      (provider) => provider.orderType == type,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          context.read<TomarOrdenProvider>().setOrderType(type);
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(
            vertical: layout == _Layout.mobile ? 10 : 12,
          ),
          backgroundColor: selected
              ? Theme.of(context).primaryColor
              : isDark
                  ? const Color(
                      0xFF2D2D44,
                    )
                  : Colors.grey[200],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.emptyMessage,
  });

  final String label;
  final List<String> options;
  final String selected;
  final String? emptyMessage;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 6,
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Expanded(
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(
                    top: 6,
                  ),
                  child: Text(
                    emptyMessage ?? 'Sin opciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: options.map((option) {
                    return ChoiceChip(
                      label: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      selected: selected == option,
                      onSelected: (_) {
                        onSelected(option);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  final CartItem item;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white60 : Colors.grey;

    return Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: iconColor,
                      ),
                      onPressed: () {
                        context.read<TomarOrdenProvider>().decrement(item);
                      },
                    ),
                    Text(
                      '${item.qty}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: iconColor,
                      ),
                      onPressed: () {
                        context.read<TomarOrdenProvider>().increment(item);
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.read<TomarOrdenProvider>().remove(item);
                  },
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}