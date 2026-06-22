import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/ordenes_provider.dart';
import '../providers/tomar_orden_provider.dart';
import '../providers/auth_provider.dart';

import '../models/order_item.dart';
import '../models/restaurant_order.dart';
import '../models/cart_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoints centralizados
// ─────────────────────────────────────────────────────────────────────────────
class _BP {
  // < tablet: layout de una columna + FAB para ver carrito
  static const double tablet = 700;
  // >= desktop: layout de dos columnas fijas (menú | carrito)
  static const double desktop = 1100;
}

// =============================================================================
// PAGE
// =============================================================================
class TomarOrdenPage extends StatelessWidget {
  const TomarOrdenPage({super.key});

  String _fmt(double v) => '\$${v.toStringAsFixed(2)} MXN';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF13131A) : Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // ── Desktop: dos columnas fijas ──────────────────────────────
            if (w >= _BP.desktop) {
              return Row(
                children: [
                  const Expanded(
                      flex: 7,
                      child: _MenuSection(layout: _Layout.desktop)),
                  VerticalDivider(
                    width: 1,
                    color: isDark
                        ? const Color(0xFF2D2D44)
                        : Colors.grey[300],
                  ),
                  const SizedBox(
                      width: 380,
                      child: _CartSection(layout: _Layout.desktop)),
                ],
              );
            }

            // ── Tablet: dos columnas más compactas ───────────────────────
            if (w >= _BP.tablet) {
              return Row(
                children: [
                  const Expanded(
                      flex: 6,
                      child: _MenuSection(layout: _Layout.tablet)),
                  VerticalDivider(
                    width: 1,
                    color: isDark
                        ? const Color(0xFF2D2D44)
                        : Colors.grey[300],
                  ),
                  const Expanded(
                      flex: 4,
                      child: _CartSection(layout: _Layout.tablet)),
                ],
              );
            }

            // ── Móvil: una columna + FAB ─────────────────────────────────
            return const _MenuSection(layout: _Layout.mobile);
          },
        ),
      ),

      // FAB solo en móvil
      floatingActionButton: Builder(builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        if (w >= _BP.tablet) return const SizedBox.shrink();

        final total =
            ctx.select<TomarOrdenProvider, double>((p) => p.total);
        final count =
            ctx.select<TomarOrdenProvider, int>((p) => p.itemsCount);

        return FloatingActionButton.extended(
          backgroundColor: Theme.of(ctx).primaryColor,
          onPressed: () => _openMobileCart(ctx),
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Text(
            '${_fmt(total)} ($count)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }

  void _openMobileCart(BuildContext context) {
    final provider = context.read<TomarOrdenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? const Color(0xFF1E1E2D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.80,
          child: const _CartSection(layout: _Layout.mobile),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enum de layout para comunicar contexto a los widgets hijos
// ─────────────────────────────────────────────────────────────────────────────
enum _Layout { mobile, tablet, desktop }

// =============================================================================
// SECCIÓN MENÚ
// =============================================================================
class _MenuSection extends StatelessWidget {
  final _Layout layout;
  const _MenuSection({required this.layout});

  bool get _isCompact => layout == _Layout.mobile;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor =
        isDark ? Colors.white60 : Colors.grey[600];
    final searchFill =
        isDark ? const Color(0xFF1E1E2D) : Colors.grey[100];
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;

    final hPad = _isCompact ? 14.0 : 18.0;

    return Padding(
      padding: EdgeInsets.all(hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Título ───────────────────────────────────────────────────
          Text(
            'Tomar Orden',
            style: TextStyle(
              fontSize: _isCompact ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Registra los productos del cliente',
            style: TextStyle(color: textSubColor, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // ── Tipo de orden ─────────────────────────────────────────────
          Row(
            children: [
              _TypeButton(
                  label: 'Comer Aquí',
                  type: OrderType.dineIn,
                  layout: layout),
              const SizedBox(width: 8),
              _TypeButton(
                  label: 'Para Llevar',
                  type: OrderType.takeaway,
                  layout: layout),
            ],
          ),
          const SizedBox(height: 12),

          // ── Área + Mesa (solo Comer Aquí) ─────────────────────────────
          if (provider.orderType == OrderType.dineIn) ...[
            _ChipsRow(
              label: 'Área:',
              options: provider.areas,
              selected: provider.selectedArea,
              onSelected: (v) =>
                  context.read<TomarOrdenProvider>().setArea(v),
            ),
            const SizedBox(height: 12),
            _ChipsRow(
              label: 'Mesa:',
              options: provider.currentTables,
              selected: provider.selectedTableName,
              onSelected: (v) =>
                  context.read<TomarOrdenProvider>().setTable(v),
            ),
            const SizedBox(height: 12),
          ],

          // ── Buscador ──────────────────────────────────────────────────
          TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search,
                  color: isDark ? Colors.white38 : Colors.grey),
              filled: true,
              fillColor: searchFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) =>
                context.read<TomarOrdenProvider>().setSearchTerm(v),
          ),
          const SizedBox(height: 12),

          // ── Chips de categoría ────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.categories.map((cat) {
                final sel = provider.selectedCategory == cat;
                return Padding(
                  padding:
                      const EdgeInsets.only(right: 8, bottom: 4),
                  child: ChoiceChip(
                    label: Text(cat,
                        style: TextStyle(fontSize: _isCompact ? 12 : 13)),
                    selected: sel,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : textColor),
                    onSelected: (_) => context
                        .read<TomarOrdenProvider>()
                        .setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // ── Lista de productos ────────────────────────────────────────
          Expanded(
            child: provider.visibleProducts.isEmpty
                ? Center(
                    child: Text('No hay productos encontrados.',
                        style: TextStyle(color: textSubColor)))
                : ListView.builder(
                    itemCount: provider.visibleProducts.length,
                    itemBuilder: (ctx, i) {
                      final p = provider.visibleProducts[i];
                      return Card(
                        color: cardBg,
                        margin: const EdgeInsets.symmetric(
                            vertical: 4),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(
                                  horizontal: _isCompact ? 12 : 16,
                                  vertical: 4),
                          title: Text(p.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _isCompact ? 13 : 14)),
                          subtitle: Text(p.description,
                              style: TextStyle(
                                  color: textSubColor,
                                  fontSize: _isCompact ? 11 : 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color:
                                  Theme.of(ctx).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: _isCompact ? 13 : 14,
                            ),
                          ),
                          onTap: () => context
                              .read<TomarOrdenProvider>()
                              .addToCart(p),
                        ),
                      );
                    },
                  ),
          ),

          // Espacio para el FAB en móvil
          if (_isCompact) const SizedBox(height: 72),
        ],
      ),
    );
  }
}

// =============================================================================
// SECCIÓN CARRITO
// =============================================================================
class _CartSection extends StatelessWidget {
  final _Layout layout;
  const _CartSection({required this.layout});

  bool get _isMobile => layout == _Layout.mobile;

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey;
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final countBg =
        isDark ? const Color(0xFF232334) : Colors.grey[200];

    final provider = context.watch<TomarOrdenProvider>();
    final orderType = provider.orderType;
    final cart = provider.cart;
    final total = provider.total;
    final itemsCount = provider.itemsCount;
    final selectedArea = provider.selectedArea;
    final selectedTable = provider.selectedTable;

    return Column(
      children: [
        // ── Cabecera del carrito ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderType == OrderType.dineIn
                          ? 'Mesa ${provider.selectedTableName}'
                          : 'Para Llevar',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    Text(
                      orderType == OrderType.dineIn
                          ? 'Servicio en Mesa'
                          : 'Recoger en Cocina',
                      style:
                          TextStyle(fontSize: 11, color: textSubColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: countBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$itemsCount Items',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
              ),
              // Botón cerrar solo en el bottom-sheet móvil
              if (_isMobile)
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: textColor),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Items del carrito ─────────────────────────────────────────
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('Elige productos a la izquierda',
                      style: TextStyle(color: textSubColor),
                      textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: cart.length,
                  itemBuilder: (ctx, i) {
                    final item = cart[i];
                    return _CartItemTile(
                      item: item,
                      isDark: isDark,
                      textColor: textColor,
                      cardBg: cardBg,
                    );
                  },
                ),
        ),
        const Divider(height: 1),

        // ── Footer: notas + total + botón ─────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Notas
              TextField(
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Notas (ej: sin cebolla)...',
                  hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : Colors.grey[400],
                      fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2D2D44)
                              : Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                ),
                onChanged: (v) =>
                    context.read<TomarOrdenProvider>().setNotes(v),
              ),
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cuenta:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  Text(_fmt(total),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ],
              ),
              const SizedBox(height: 12),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF232334)
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: cart.isEmpty
                      ? null
                      : () => _enviarOrden(
                            context: context,
                            provider: provider,
                            orderType: orderType,
                            selectedTable: selectedTable,
                            selectedArea: selectedArea,
                            cart: cart,
                            total: total,
                            itemsCount: itemsCount,
                            isDark: isDark,
                          ),
                  child: const Text('Enviar a Cocina',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _enviarOrden({
    required BuildContext context,
    required TomarOrdenProvider provider,
    required OrderType orderType,
    required String selectedTable,
    required String selectedArea,
    required List<CartItem> cart,
    required double total,
    required int itemsCount,
    required bool isDark,
  }) async {
    final idComanda =
        'CMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final hora =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final identificador = orderType == OrderType.dineIn
        ? 'Mesa ${provider.selectedTableName} (Área $selectedArea)'
        : 'Para Llevar';

    final tipoServicio =
        orderType == OrderType.dineIn ? 'dine_in' : 'takeout';

    final cocinaItems = cart
        .map((c) => OrderItem(
              productName: c.product.name,
              quantity: c.qty,
              total: c.total,
              productId: c.product.id,
              unitPrice: c.product.price,
            ))
        .toList();

    final nuevaOrden = RestaurantOrder(
      id: '',
      orderNumber: idComanda,
      tableId: orderType == OrderType.dineIn ? selectedTable : null,
      tableOrCustomer: identificador,
      time: hora,
      status: 'pending',
      serviceType: tipoServicio,
      items: cocinaItems,
      totalAmount: total,
      notes: provider.notes.isNotEmpty ? provider.notes : null,
      // Nombre del mesero tomado del perfil del usuario logueado.
      waiterName: context.read<AuthProvider>().nombreUsuario,
    );

    final ordenesProvider =
        Provider.of<OrdenesProvider>(context, listen: false);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await ordenesProvider.insertarNuevaComanda(nuevaOrden);

    if (!context.mounted) return;

    if (ordenesProvider.errorMessage != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            'Error al guardar orden: ${ordenesProvider.errorMessage}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    // NOTA: ya no se llama a CajaProvider.agregarCuentaPorCobrar() aquí.
    // insertarNuevaComanda() arriba ya hace cargarOrdenes() internamente,
    // y CajaProvider.pendingOrders lee directamente de OrdenesProvider, así
    // que la orden recién creada ya aparece en caja sin necesidad de este
    // paso extra (que además insertaba en una lista que nadie llegaba a leer).

    provider.sendOrder();

    if (_isMobile && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    messenger.showSnackBar(SnackBar(
      content: Text('Orden $idComanda creada exitosamente'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ));

    Future.delayed(const Duration(milliseconds: 150), () {
      router.go('/ordenes');
    });
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

/// Botón de tipo de orden (Comer Aquí / Para Llevar)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = context
        .select<TomarOrdenProvider, bool>((p) => p.orderType == type);
    final isCompact = layout == _Layout.mobile;

    return Expanded(
      child: ElevatedButton(
        onPressed: () =>
            context.read<TomarOrdenProvider>().setOrderType(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? const Color(0xFF2D2D44) : Colors.grey[200]),
          padding: EdgeInsets.symmetric(
              vertical: isCompact ? 10 : 12),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Fila de chips con label a la izquierda
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options
                .map((opt) => ChoiceChip(
                      label: Text(opt,
                          style: const TextStyle(fontSize: 12)),
                      selected: selected == opt,
                      onSelected: (_) => onSelected(opt),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Tile de un ítem en el carrito
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.cardBg,
  });
  final CartItem item;
  final bool isDark;
  final Color textColor;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white60 : Colors.grey;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark
                ? const Color(0xFF2D2D44)
                : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Nombre + precio total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Controles cantidad + eliminar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          size: 20, color: iconColor),
                      onPressed: () => context
                          .read<TomarOrdenProvider>()
                          .decrement(item),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.qty}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor)),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          size: 20, color: iconColor),
                      onPressed: () => context
                          .read<TomarOrdenProvider>()
                          .increment(item),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context
                      .read<TomarOrdenProvider>()
                      .remove(item),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Eliminar',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Utilidad interna (mantiene compatibilidad con el código existente)
class SWidth extends StatelessWidget {
  final double width;
  final Widget child;
  const SWidth({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: width, child: child);
}