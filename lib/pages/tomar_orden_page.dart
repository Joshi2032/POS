
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
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF13131A)
        : Colors.grey[50];

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
                    color: isDark
                        ? const Color(0xFF2D2D44)
                        : Colors.grey[300],
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
                    color: isDark
                        ? const Color(0xFF2D2D44)
                        : Colors.grey[300],
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
          final width =
              MediaQuery.sizeOf(context).width;

          if (width >= _Breakpoints.tablet) {
            return const SizedBox.shrink();
          }

          final total =
              context.select<TomarOrdenProvider, double>(
            (provider) => provider.total,
          );

          final count =
              context.select<TomarOrdenProvider, int>(
            (provider) => provider.itemsCount,
          );

          return FloatingActionButton.extended(
            backgroundColor:
                Theme.of(context).primaryColor,
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
    final provider =
        context.read<TomarOrdenProvider>();

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? const Color(0xFF1E1E2D)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: SizedBox(
            height:
                MediaQuery.sizeOf(context).height * 0.80,
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

  bool get isCompact =>
      layout == _Layout.mobile;

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<TomarOrdenProvider>();

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark
        ? Colors.white60
        : Colors.grey[600];

    final searchFillColor = isDark
        ? const Color(0xFF1E1E2D)
        : Colors.grey[100];

    final cardColor = isDark
        ? const Color(0xFF1E1E2D)
        : Colors.white;

    return Padding(
      padding: EdgeInsets.all(
        isCompact ? 14 : 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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

          if (provider.orderType ==
              OrderType.dineIn) ...[
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
                  selected:
                      !provider.isExistingTable,
                  selectedColor:
                      Theme.of(context).primaryColor,
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(
                    color:
                        !provider.isExistingTable
                            ? Colors.white
                            : textColor,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context
                          .read<TomarOrdenProvider>()
                          .setIsExistingTable(false);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Existente'),
                  selected:
                      provider.isExistingTable,
                  selectedColor:
                      Theme.of(context).primaryColor,
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(
                    color:
                        provider.isExistingTable
                            ? Colors.white
                            : textColor,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context
                          .read<TomarOrdenProvider>()
                          .setIsExistingTable(true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            _ChipsRow(
              label: 'Área:',
              options:
                  provider.availableAreas,
              selected:
                  provider.selectedArea,
              onSelected: context
                  .read<TomarOrdenProvider>()
                  .setArea,
            ),
            const SizedBox(height: 12),

            _ChipsRow(
              label: 'Mesa:',
              options:
                  provider.currentTables,
              selected:
                  provider.selectedTableName,
              emptyMessage:
                  provider.isExistingTable
                      ? 'No hay mesas ocupadas'
                      : 'No hay mesas libres',
              onSelected: context
                  .read<TomarOrdenProvider>()
                  .setTable,
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
                color: isDark
                    ? Colors.white38
                    : Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark
                    ? Colors.white38
                    : Colors.grey,
              ),
              filled: true,
              fillColor: searchFillColor,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: context
                .read<TomarOrdenProvider>()
                .setSearchTerm,
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  provider.categories.map((category) {
                final selected =
                    provider.selectedCategory ==
                        category;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 8,
                    bottom: 4,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize:
                            isCompact ? 12 : 13,
                      ),
                    ),
                    selected: selected,
                    selectedColor:
                        Theme.of(context).primaryColor,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : textColor,
                    ),
                    onSelected: (_) {
                      context
                          .read<TomarOrdenProvider>()
                          .setCategory(category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child:
                provider.visibleProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No hay productos encontrados.',
                          style: TextStyle(
                            color:
                                secondaryTextColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider
                            .visibleProducts.length,
                        itemBuilder:
                            (context, index) {
                          final product =
                              provider
                                      .visibleProducts[
                                  index];

                          return Card(
                            color: cardColor,
                            margin: const EdgeInsets
                                .symmetric(
                              vertical: 6,
                            ),
                            child: InkWell(
                              onTap: () {
                                context
                                    .read<
                                        TomarOrdenProvider>()
                                    .addToCart(
                                      product,
                                    );
                              },
                              child: Padding(
                                padding:
                                    EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      isCompact
                                          ? 12
                                          : 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            product
                                                .name,
                                            style:
                                                TextStyle(
                                              color:
                                                  textColor,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              fontSize:
                                                  isCompact
                                                      ? 14
                                                      : 16,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                          Text(
                                            product
                                                .description,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                TextStyle(
                                              color:
                                                  secondaryTextColor,
                                              fontSize:
                                                  isCompact
                                                      ? 11
                                                      : 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .end,
                                      children: [
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style:
                                              TextStyle(
                                            color:
                                                Theme.of(
                                              context,
                                            )
                                                    .primaryColor,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize:
                                                isCompact
                                                    ? 13
                                                    : 14,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        ElevatedButton
                                            .icon(
                                          onPressed: () {
                                            context
                                                .read<
                                                    TomarOrdenProvider>()
                                                .addToCart(
                                                  product,
                                                );
                                          },
                                          style:
                                              ElevatedButton
                                                  .styleFrom(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal:
                                                  8,
                                              vertical:
                                                  6,
                                            ),
                                            elevation: 0,
                                          ),
                                          icon:
                                              const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                          label:
                                              const Text(
                                            'Agregar',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  12,
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

          if (isCompact)
            const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _CartSection extends StatelessWidget {
  const _CartSection({
    required this.layout,
  });

  final _Layout layout;

  bool get isMobile =>
      layout == _Layout.mobile;

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<TomarOrdenProvider>();

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final secondaryTextColor =
        isDark ? Colors.white60 : Colors.grey;

    final cardColor = isDark
        ? const Color(0xFF1E1E2D)
        : Colors.white;

    final countBackground = isDark
        ? const Color(0xFF232334)
        : Colors.grey[200];

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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderType ==
                              OrderType.dineIn
                          ? provider
                              .selectedTableName
                          : 'Para Llevar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      orderType ==
                              OrderType.dineIn
                          ? provider
                                  .isExistingTable
                              ? 'Agregar a orden existente'
                              : 'Nueva orden en mesa'
                          : 'Recoger en cocina',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: countBackground,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.itemsCount} Items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
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

        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text(
                    'Selecciona productos para la orden',
                    style: TextStyle(
                      color:
                          secondaryTextColor,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(10),
                  itemCount: cart.length,
                  itemBuilder:
                      (context, index) {
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
                  hintText:
                      'Notas, por ejemplo: sin cebolla',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : Colors.grey[400],
                    fontSize: 12,
                  ),
                  border:
                      const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                onChanged: context
                    .read<TomarOrdenProvider>()
                    .setNotes,
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _formatCurrency(
                      provider.total,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.isEmpty
                      ? null
                      : () {
                          _confirmarOrden(
                            context,
                            provider,
                          );
                        },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green[600],
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enviar a Cocina',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
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
    if (provider.orderType ==
            OrderType.dineIn &&
        provider.selectedTable.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            provider.isExistingTable
                ? 'No hay mesas ocupadas disponibles.'
                : 'No hay mesas libres disponibles.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Confirmar envío'),
          content: Text(
            provider.isExistingTable &&
                    provider.orderType ==
                        OrderType.dineIn
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
              child:
                  const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !context.mounted) {
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
    final orderType = provider.orderType;
    final selectedTable =
        provider.selectedTable;
    final selectedArea =
        provider.selectedArea;

    final cartSnapshot =
        List<CartItem>.from(
      provider.cart,
    );

    final total = provider.total;

    final idComanda =
        'CMD-${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now();

    final hora =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    final identificador =
        orderType == OrderType.dineIn
            ? '${provider.selectedTableName} '
                '(Área $selectedArea)'
            : 'Para Llevar';

    final cocinaItems =
        cartSnapshot.map((item) {
      return OrderItem(
        productName: item.product.name,
        productId: item.product.id,
        quantity: item.qty,
        unitPrice: item.product.price,
        total: item.total,
      );
    }).toList();

    final itemsMap =
        cartSnapshot.map((item) {
      return {
        'product_name':
            item.product.name,
        'product_id':
            item.product.id,
        'quantity': item.qty,
        'unit_price':
            item.product.price,
        'total': item.total,
      };
    }).toList();

    final authProvider =
        context.read<AuthProvider>();

    final nuevaOrden = RestaurantOrder(
      id: '',
      orderNumber: idComanda,
      tableId:
          orderType == OrderType.dineIn
              ? selectedTable
              : null,
      tableOrCustomer:
          identificador,
      time: hora,
      status: 'pending',
      serviceType:
          orderType == OrderType.dineIn
              ? 'dine_in'
              : 'takeout',
      items: cocinaItems,
      totalAmount: total,
      notes:
          provider.notes.trim().isEmpty
              ? null
              : provider.notes.trim(),
      waiterId: authProvider.userId,
      waiterName:
          authProvider.nombreUsuario,
    );

    final ordenesProvider =
        context.read<OrdenesProvider>();

    final messenger =
        ScaffoldMessenger.of(context);

    final router =
        GoRouter.of(context);

    String mensajeExito =
        'Orden creada exitosamente';

    if (orderType == OrderType.dineIn &&
        provider.isExistingTable) {
      final ordenExistente =
          await ordenesProvider
              .obtenerOrdenActivaPorMesa(
        selectedTable,
      );

      if (ordenExistente != null) {
        await ordenesProvider
            .agregarItemsAOrden(
          ordenExistente.id,
          itemsMap,
        );

        mensajeExito =
            'Productos agregados a ${provider.selectedTableName}';
      } else {
        await ordenesProvider
            .insertarNuevaComanda(
          nuevaOrden,
        );

        mensajeExito =
            'No había una orden activa; se creó una nueva';
      }
    } else {
      await ordenesProvider
          .insertarNuevaComanda(
        nuevaOrden,
      );
    }

    if (ordenesProvider.errorMessage !=
        null) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar la orden: '
            '${ordenesProvider.errorMessage}',
          ),
          backgroundColor:
              Colors.red,
          duration:
              const Duration(seconds: 5),
        ),
      );

      return;
    }

    if (orderType == OrderType.dineIn &&
        !provider.isExistingTable) {
      final mesasProvider =
          context.read<MesasProvider>();

      final actualizada =
          await mesasProvider
              .cambiarEstadoMesa(
        selectedTable,
        'ocupada',
      );

      if (!actualizada) {
        if (!context.mounted) {
          return;
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              mesasProvider.errorMessage ??
                  'La orden se creó, pero no se pudo marcar la mesa como ocupada.',
            ),
            backgroundColor:
                Colors.red,
            duration:
                const Duration(seconds: 5),
          ),
        );

        return;
      }
    }

    provider.sendOrder();

    if (!context.mounted) {
      return;
    }

    if (isMobile &&
        Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(mensajeExito),
        backgroundColor:
            Colors.green,
      ),
    );

    Future.delayed(
      const Duration(
        milliseconds: 150,
      ),
      () {
        router.go('/ordenes');
      },
    );
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
    final selected =
        context.select<
            TomarOrdenProvider,
            bool>(
      (provider) =>
          provider.orderType == type,
    );

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          context
              .read<TomarOrdenProvider>()
              .setOrderType(type);
        },
        style:
            ElevatedButton.styleFrom(
          elevation: 0,
          padding:
              EdgeInsets.symmetric(
            vertical:
                layout == _Layout.mobile
                    ? 10
                    : 12,
          ),
          backgroundColor: selected
              ? Theme.of(context)
                  .primaryColor
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
            fontWeight:
                FontWeight.bold,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 6,
            ),
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Expanded(
          child: options.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    top: 6,
                  ),
                  child: Text(
                    emptyMessage ??
                        'Sin opciones',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey[600],
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      options.map((option) {
                    return ChoiceChip(
                      label: Text(
                        option,
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      selected:
                          selected == option,
                      onSelected: (_) {
                        onSelected(option);
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CartItemTile
    extends StatelessWidget {
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
    final iconColor =
        isDark ? Colors.white60 : Colors.grey;

    return Card(
      elevation: 0,
      color: cardColor,
      margin:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF2D2D44)
              : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .primaryColor,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons
                            .remove_circle_outline,
                        color: iconColor,
                      ),
                      onPressed: () {
                        context
                            .read<
                                TomarOrdenProvider>()
                            .decrement(item);
                      },
                    ),
                    Text(
                      '${item.qty}',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons
                            .add_circle_outline,
                        color: iconColor,
                      ),
                      onPressed: () {
                        context
                            .read<
                                TomarOrdenProvider>()
                            .increment(item);
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context
                        .read<
                            TomarOrdenProvider>()
                        .remove(item);
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

