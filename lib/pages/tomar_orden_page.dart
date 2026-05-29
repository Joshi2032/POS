import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones del motor de rutas e interconexión
import '../providers/ordenes_provider.dart';
import '../providers/caja_provider.dart';
import '../providers/tomar_orden_provider.dart';

// Importación de los modelos de datos centralizados
import '../models/order_item.dart';
import '../models/restaurant_order.dart';
import '../models/cart_item.dart';
import '../ui_models/cash_item.dart';
import '../ui_models/cash_order.dart';
import '../models/product.dart';

// ==========================================================================
// INTERFAZ DE USUARIO ADAPTATIVA (Tu diseño original intacto al 100%)
// ==========================================================================

class TomarOrdenPage extends StatelessWidget {
  const TomarOrdenPage({super.key});

  String formatCurrency(double value) => '\$${value.toStringAsFixed(2)} MXN';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF13131A) : Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 1200;

            if (isMobile) {
              return const _MenuSection(isMobile: true);
            } else {
              return Row(
                children: [
                  const Expanded(flex: 7, child: _MenuSection(isMobile: false)),
                  VerticalDivider(
                      width: 1,
                      color:
                          isDark ? const Color(0xFF2D2D44) : Colors.grey[300]),
                  const SizedBox(
                      width: 380, child: _CartSection(isMobile: false)),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final isMobile = MediaQuery.of(context).size.width <= 1200;
          if (!isMobile) return const SizedBox.shrink();

          final total =
              context.select<TomarOrdenProvider, double>((p) => p.total);
          final itemsCount =
              context.select<TomarOrdenProvider, int>((p) => p.itemsCount);
          return FloatingActionButton.extended(
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => _openMobileCart(context),
            label: Text(
              '${formatCurrency(total)} ($itemsCount)',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
          );
        },
      ),
    );
  }

  void _openMobileCart(BuildContext context) {
    final provider = context.read<TomarOrdenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.76,
            child: const _CartSection(isMobile: true),
          ),
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  final bool isMobile;
  const _MenuSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    // Escuchamos la lista de Producto (modelo unificado)
    final visibleProducts = context
        .select<TomarOrdenProvider, List<Producto>>((p) => p.visibleProducts);

    final orderType =
        context.select<TomarOrdenProvider, OrderType>((p) => p.orderType);
    final areas =
        context.select<TomarOrdenProvider, List<String>>((p) => p.areas);
    final selectedArea =
        context.select<TomarOrdenProvider, String>((p) => p.selectedArea);
    final currentTables = context
        .select<TomarOrdenProvider, List<String>>((p) => p.currentTables);
    final selectedTable =
        context.select<TomarOrdenProvider, String>((p) => p.selectedTable);
    final categories =
        context.select<TomarOrdenProvider, List<String>>((p) => p.categories);
    final selectedCategory =
        context.select<TomarOrdenProvider, String>((p) => p.selectedCategory);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey[600];
    final searchFillColor = isDark ? const Color(0xFF1E1E2D) : Colors.grey[100];
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tomar Orden',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          Text('Registra los productos del cliente',
              style: TextStyle(color: textSubColor, fontSize: 14)),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTypeButton(context, 'Comer Aquí', OrderType.dineIn),
              const SizedBox(width: 8),
              _buildTypeButton(context, 'Para Llevar', OrderType.takeaway),
            ],
          ),
          const SizedBox(height: 14),
          if (orderType == OrderType.dineIn) ...[
            _buildChipsRow(context, 'Área:', areas, selectedArea,
                (v) => context.read<TomarOrdenProvider>().setArea(v)),
            const SizedBox(height: 8),
            _buildChipsRow(context, 'Mesa:', currentTables, selectedTable,
                (v) => context.read<TomarOrdenProvider>().setTable(v)),
            const SizedBox(height: 14),
          ],
          TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, desc...',
              hintStyle:
                  TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search,
                  color: isDark ? Colors.white38 : Colors.grey),
              filled: true,
              fillColor: searchFillColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) =>
                context.read<TomarOrdenProvider>().setSearchTerm(v),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: cardBg,
                    labelStyle:
                        TextStyle(color: isSelected ? Colors.white : textColor),
                    onSelected: (_) =>
                        context.read<TomarOrdenProvider>().setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: visibleProducts.isEmpty
                ? Center(
                    child: Text('No hay productos encontrados.',
                        style: TextStyle(color: textSubColor)))
                : ListView.builder(
                    itemCount: visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product =
                          visibleProducts[index]; // Ahora es Producto
                      return Card(
                        color: cardBg,
                        child: ListTile(
                          title: Text(product.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(product.description,
                              style: TextStyle(color: textSubColor)),
                          trailing: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                          onTap: () => context
                              .read<TomarOrdenProvider>()
                              .addToCart(product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, String text, OrderType type) {
    final isSelected =
        context.select<TomarOrdenProvider, bool>((p) => p.orderType == type);
    return Expanded(
      child: ElevatedButton(
        onPressed: () => context.read<TomarOrdenProvider>().setOrderType(type),
        style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[200]),
        child: Text(text),
      ),
    );
  }

  Widget _buildChipsRow(
      BuildContext context,
      String label,
      List<String> options,
      String selectedValue,
      ValueChanged<String> onSelected) {
    return Row(
      children: [
        SWidth(
            width: 50,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            child: Wrap(
                children: options
                    .map((opt) => ChoiceChip(
                        label: Text(opt),
                        selected: selectedValue == opt,
                        onSelected: (_) => onSelected(opt)))
                    .toList()))
      ],
    );
  }
}

class _CartSection extends StatelessWidget {
  final bool isMobile;
  const _CartSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey;
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final countBg = isDark ? const Color(0xFF232334) : Colors.grey[200];

    final orderType =
        context.select<TomarOrdenProvider, OrderType>((p) => p.orderType);
    final selectedTable =
        context.select<TomarOrdenProvider, String>((p) => p.selectedTable);
    final selectedArea =
        context.select<TomarOrdenProvider, String>((p) => p.selectedArea);
    final itemsCount =
        context.select<TomarOrdenProvider, int>((p) => p.itemsCount);
    final cart =
        context.select<TomarOrdenProvider, List<CartItem>>((p) => p.cart);
    final notes = context.select<TomarOrdenProvider, String>((p) => p.notes);
    final total = context.select<TomarOrdenProvider, double>((p) => p.total);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      orderType == OrderType.dineIn
                          ? 'Mesa $selectedTable'
                          : 'Para Llevar',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text(
                      orderType == OrderType.dineIn
                          ? 'Servicio en Mesa'
                          : 'Recoger en Cocina',
                      style: TextStyle(fontSize: 12, color: textSubColor)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: countBg, borderRadius: BorderRadius.circular(12)),
                child: Text('$itemsCount Items',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
              ),
              if (isMobile)
                IconButton(
                    icon: Icon(Icons.close, size: 22, color: textColor),
                    onPressed: () => Navigator.pop(context))
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('Elige productos a la izquierda',
                      style: TextStyle(color: textSubColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Card(
                      elevation: 0,
                      color: cardBg,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2D2D44)
                                  : Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(item.product.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor),
                                        overflow: TextOverflow.ellipsis)),
                                Text('\$${item.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                        icon: Icon(Icons.remove_circle_outline,
                                            size: 22,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey),
                                        onPressed: () => context
                                            .read<TomarOrdenProvider>()
                                            .decrement(item)),
                                    Text('${item.qty}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor)),
                                    IconButton(
                                        icon: Icon(Icons.add_circle_outline,
                                            size: 22,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey),
                                        onPressed: () => context
                                            .read<TomarOrdenProvider>()
                                            .increment(item)),
                                  ],
                                ),
                                TextButton(
                                    onPressed: () => context
                                        .read<TomarOrdenProvider>()
                                        .remove(item),
                                    child: const Text('Eliminar',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500)))
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Notas de la orden (ej: sin cebolla)...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[400],
                      fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              isDark ? const Color(0xFF2D2D44) : Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) =>
                    context.read<TomarOrdenProvider>().setNotes(v),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cuenta:',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  Text('\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ],
              ),
              const SizedBox(height: 14),
              SWidth(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor:
                        isDark ? const Color(0xFF232334) : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: cart.isEmpty
                      ? null
                      : () {
                          final ordenesProvider = Provider.of<OrdenesProvider>(
                              context,
                              listen: false);
                          final cajaProvider =
                              Provider.of<CajaProvider>(context, listen: false);

                          final String idComanda =
                              'CMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          final String horaActual =
                              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

                          final String identificador =
                              orderType == OrderType.dineIn
                                  ? 'Mesa $selectedTable (Área $selectedArea)'
                                  : 'Para Llevar';

                          final String tipoDeServicio =
                              orderType == OrderType.dineIn
                                  ? 'comedor'
                                  : 'llevar';

                          final cocinaItems = cart
                              .map((c) => OrderItem(
                                    productName: c.product.name,
                                    quantity: c.qty,
                                    total: c.total,
                                  ))
                              .toList();

                          final cajaItems = cart
                              .map((c) => CashItem(
                                    name: c.product.name,
                                    qty: c.qty,
                                    price: c.product.price,
                                  ))
                              .toList();

                          ordenesProvider.insertarNuevaComanda(RestaurantOrder(
                            id: idComanda,
                            tableOrCustomer: identificador,
                            time: horaActual,
                            status: 'pendiente',
                            serviceType: tipoDeServicio,
                            items: cocinaItems,
                            totalAmount: total,
                            notes: notes.isNotEmpty ? notes : null,
                          ));

                          cajaProvider.agregarCuentaPorCobrar(CashOrder(
                            id: idComanda,
                            label: identificador,
                            time: horaActual,
                            status: 'Pendiente',
                            itemsCount: itemsCount,
                            items: cajaItems,
                            total: total,
                          ));

                          context.read<TomarOrdenProvider>().sendOrder();
                          if (isMobile) Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Orden $idComanda enviada a cocina y caja'),
                                backgroundColor: Colors.green),
                          );
                        },
                  child: const Text('Confirmar y Enviar Orden',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SWidth extends StatelessWidget {
  final double width;
  final Widget child;
  const SWidth({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
