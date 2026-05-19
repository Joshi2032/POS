import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones del motor de rutas e interconexión
import '../providers/ordenes_provider.dart';
import '../providers/caja_provider.dart';
import '../providers/tomar_orden_provider.dart';

// Importación de los nuevos modelos de datos centralizados
import '../models/order_item.dart';
import '../models/restaurant_order.dart';

// ==========================================================================
// INTERFAZ DE USUARIO ADAPTATIVA (Tu diseño original intacto)
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
                  VerticalDivider(width: 1, color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300]),
                  const SizedBox(width: 380, child: _CartSection(isMobile: false)),
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

          final provider = context.watch<TomarOrdenProvider>();
          return FloatingActionButton.extended(
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => _openMobileCart(context),
            label: Text(
              '${formatCurrency(provider.total)} (${provider.itemsCount})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    final provider = context.watch<TomarOrdenProvider>();
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
          Text('Tomar Orden', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          Text('Registra los productos del cliente', style: TextStyle(color: textSubColor, fontSize: 14)),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildTypeButton(context, 'Comer Aquí', OrderType.dineIn, provider),
              const SizedBox(width: 8),
              _buildTypeButton(context, 'Para Llevar', OrderType.takeaway, provider),
            ],
          ),
          const SizedBox(height: 14),
          if (provider.orderType == OrderType.dineIn) ...[
            _buildChipsRow(context, 'Área:', provider.areas, provider.selectedArea, (v) => provider.setArea(v)),
            const SizedBox(height: 8),
            _buildChipsRow(context, 'Mesa:', provider.currentTables, provider.selectedTable, (v) => provider.setTable(v)),
            const SizedBox(height: 14),
          ],
          TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, desc...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey),
              filled: true,
              fillColor: searchFillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => provider.setSearchTerm(v),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.categories.map((cat) {
                final isSelected = provider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    onSelected: (_) => provider.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: provider.visibleProducts.isEmpty
                ? Center(child: Text('No hay productos que coincidan con la búsqueda.', style: TextStyle(color: textSubColor)))
                : isMobile
                    ? ListView.separated(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: provider.visibleProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = provider.visibleProducts[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(side: BorderSide(color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
                            color: cardBg,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => provider.addToCart(product),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(product.category.toUpperCase(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          const SizedBox(height: 4),
                                          Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(product.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[500], height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.add_shopping_cart_outlined, color: Theme.of(context).primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                        itemCount: provider.visibleProducts.length,
                        itemBuilder: (context, index) {
                          final product = provider.visibleProducts[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(side: BorderSide(color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
                            color: cardBg,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => provider.addToCart(product),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.category.toUpperCase(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(product.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[500], height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, String text, OrderType type, TomarOrdenProvider provider) {
    final isSelected = provider.orderType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : (isDark ? const Color(0xFF1E1E2D) : Colors.grey[100]),
            foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => provider.setOrderType(type),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildChipsRow(BuildContext context, String label, List<String> options, String selectedValue, ValueChanged<String> onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SWidth(width: 50, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.grey))),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isSelected = selectedValue == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                    onSelected: (_) => onSelected(opt),
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }
}

class _CartSection extends StatelessWidget {
  final bool isMobile;
  const _CartSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white60 : Colors.grey;
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final countBg = isDark ? const Color(0xFF232334) : Colors.grey[200];

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
                  Text(provider.orderType == OrderType.dineIn ? 'Mesa ${provider.selectedTable}' : 'Para Llevar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  Text(provider.orderType == OrderType.dineIn ? 'Servicio en Mesa' : 'Recoger en Cocina', style: TextStyle(fontSize: 12, color: textSubColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: countBg, borderRadius: BorderRadius.circular(12)),
                child: Text('${provider.itemsCount} Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
              ),
              if (isMobile) IconButton(icon: Icon(Icons.close, size: 22, color: textColor), onPressed: () => Navigator.pop(context))
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: provider.cart.isEmpty
              ? Center(child: Text('Elige productos a la izquierda', style: TextStyle(color: textSubColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final item = provider.cart[index];
                    return Card(
                      elevation: 0,
                      color: cardBg,
                      shape: RoundedRectangleBorder(side: BorderSide(color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), overflow: TextOverflow.ellipsis)),
                                Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(icon: Icon(Icons.remove_circle_outline, size: 22, color: isDark ? Colors.white60 : Colors.grey), onPressed: () => provider.decrement(item)),
                                    Text('${item.qty}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                    IconButton(icon: Icon(Icons.add_circle_outline, size: 22, color: isDark ? Colors.white60 : Colors.grey), onPressed: () => provider.increment(item)),
                                  ],
                                ),
                                TextButton(onPressed: () => provider.remove(item), child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)))
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
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 13),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xFF2D2D44) : Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) => provider.setNotes(v),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cuenta:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  Text('\$${provider.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 14),
              SWidth(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: isDark ? const Color(0xFF232334) : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: provider.cart.isEmpty
                      ? null
                      : () {
                          final ordenesProvider = Provider.of<OrdenesProvider>(context, listen: false);
                          final cajaProvider = Provider.of<CajaProvider>(context, listen: false);

                          final String idComanda = 'CMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                          final String horaActual = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
                          
                          final String identificador = provider.orderType == OrderType.dineIn 
                              ? 'Mesa ${provider.selectedTable} (Área ${provider.selectedArea})'
                              : 'Para Llevar';
                          
                          final String tipoDeServicio = provider.orderType == OrderType.dineIn ? 'comedor' : 'llevar';

                          final cocinaItems = provider.cart.map((c) => OrderItem(
                            productName: c.product.name,
                            quantity: c.qty,
                            total: c.total,
                          )).toList();

                          final cajaItems = provider.cart.map((c) => CashItem(
                            name: c.product.name,
                            qty: c.qty,
                            price: c.product.price,
                          )).toList();

                          ordenesProvider.insertarNuevaComanda(
                            RestaurantOrder(
                              id: idComanda,
                              tableOrCustomer: identificador,
                              time: horaActual,
                              status: 'pendiente',
                              serviceType: tipoDeServicio,
                              items: cocinaItems,
                              totalAmount: provider.total,
                              notes: provider.notes.isNotEmpty ? provider.notes : null,
                            )
                          );

                          cajaProvider.agregarCuentaPorCobrar(
                            CashOrder(
                              id: idComanda,
                              label: identificador,
                              time: horaActual,
                              status: 'Pendiente',
                              itemsCount: provider.itemsCount,
                              items: cajaItems,
                              total: provider.total,
                            )
                          );

                          provider.sendOrder();
                          if (isMobile) Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Orden $idComanda enviada a cocina y caja'), backgroundColor: Colors.green),
                          );
                        },
                  child: const Text('Confirmar y Enviar Orden', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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