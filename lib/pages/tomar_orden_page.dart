import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ==========================================================================
// 1. MODELOS DE DATOS (Equivalente a tomar-orden.models.ts)
// ==========================================================================

enum OrderType { dineIn, takeaway }

class ProductItem {
  final int id;
  final String name;
  final String description;
  final String category;
  final double price;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
  });
}

class CartItem {
  final ProductItem product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  double get total => product.price * qty;
}

// ==========================================================================
// 2. GESTOR DE ESTADO / SIGNALS (Equivalente a tomar-orden.component.ts)
// ==========================================================================

class TomarOrdenProvider extends ChangeNotifier {
  // Datos Semilla (Seeds de Angular)
  final Map<String, List<String>> tableAreas = {
    'A': ['A1', 'A2', 'A3', 'A4'],
    'B': ['B1', 'B2', 'B3']
  };
  
  final List<String> categories = [
    'Todos', 'Parrilla', 'Entradas', 'Ensaladas', 'Guarniciones', 'Bebidas', 'Postres', 'Extras'
  ];

  final List<ProductItem> _products = [
    ProductItem(id: 1, name: 'Arrachera 300g', description: 'Corte marinado a la brasa con chimichurri.', category: 'Parrilla', price: 285),
    ProductItem(id: 2, name: 'Brochetas Mixtas', description: 'Res y pollo a la parrilla con vegetales.', category: 'Parrilla', price: 175),
    ProductItem(id: 3, name: 'Costillas BBQ', description: 'Rack de costilla ahumada con salsa de la casa.', category: 'Parrilla', price: 320),
    ProductItem(id: 4, name: 'Elotes Asados', description: 'Con mayonesa, chile y limon.', category: 'Entradas', price: 65),
    ProductItem(id: 5, name: 'Guacamole Ahumado', description: 'Guacamole con chile ahumado y totopos.', category: 'Entradas', price: 95),
    ProductItem(id: 6, name: 'Ensalada Caesar', description: 'Lechuga romana, parmesano y crotones.', category: 'Ensaladas', price: 110),
    ProductItem(id: 7, name: 'Ensalada de la Casa', description: 'Mixta con vinagreta balsamica.', category: 'Ensaladas', price: 85),
    ProductItem(id: 8, name: 'Arroz a la Mexicana', description: 'Arroz tradicional con verduras.', category: 'Guarniciones', price: 45),
    ProductItem(id: 9, name: 'Frijoles Charros', description: 'Con tocino, chorizo y chile.', category: 'Guarniciones', price: 55),
    ProductItem(id: 10, name: 'Papas al Carbon', description: 'Papas asadas con hierbas.', category: 'Guarniciones', price: 75),
    ProductItem(id: 11, name: 'Agua de Jamaica', description: 'Agua fresca tradicional.', category: 'Bebidas', price: 40),
    ProductItem(id: 12, name: 'Cerveza Artesanal', description: 'IPA, Stout o Lager.', category: 'Bebidas', price: 85),
    ProductItem(id: 13, name: 'Limonada con Hierba Buena', description: 'Limonada natural refrescante.', category: 'Bebidas', price: 55),
    ProductItem(id: 14, name: 'Mezcal Oaxaqueno', description: 'Mezcal artesanal con sal de gusano.', category: 'Bebidas', price: 130),
    ProductItem(id: 15, name: 'Churros a la Brasa', description: 'Con chocolate caliente.', category: 'Postres', price: 75)
  ];

  // Propiedades privadas reactivas
  OrderType _orderType = OrderType.dineIn;
  String _selectedArea = 'A';
  String _selectedTable = 'A1';
  String _selectedCategory = 'Todos';
  String _searchTerm = '';
  String _notes = '';
  final List<CartItem> _cart = [];

  // Getters Públicos
  OrderType get orderType => _orderType;
  String get selectedArea => _selectedArea;
  String get selectedTable => _selectedTable;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get notes => _notes;
  List<CartItem> get cart => _cart;

  List<String> get areas => tableAreas.keys.toList();
  List<String> get currentTables => tableAreas[_selectedArea] ?? [];

  // Computed (fold): Cantidad total de productos en carrito y precio total
  int get itemsCount => _cart.fold(0, (sum, item) => sum + item.qty);
  double get total => _cart.fold(0.0, (sum, item) => sum + item.total);

  // Computed: visibleProducts (Equivalente al filterByCategoryAndSearch de Angular)
  List<ProductItem> get visibleProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                            product.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                            product.category.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Métodos mutadores de estado (Setters con reactividad)
  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  void setArea(String area) {
    if (_selectedArea == area) return;
    _selectedArea = area;
    _selectedTable = tableAreas[area]?.first ?? '';
    notifyListeners();
  }

  void setTable(String table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  // Operaciones del Carrito
  void addToCart(ProductItem product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _cart.add(CartItem(product: product));
    } else {
      _cart[index].qty++;
    }
    notifyListeners();
  }

  void increment(CartItem item) {
    item.qty++;
    notifyListeners();
  }

  void decrement(CartItem item) {
    if (item.qty <= 1) {
      _cart.removeWhere((entry) => entry.product.id == item.product.id);
    } else {
      item.qty--;
    }
    notifyListeners();
  }

  void updateQty(CartItem item, int qty) {
    if (qty < 1) return;
    item.qty = qty;
    notifyListeners();
  }

  void remove(CartItem item) {
    _cart.removeWhere((entry) => entry.product.id == item.product.id);
    notifyListeners();
  }

  void sendOrder() {
    if (_cart.isEmpty) return;
    _cart.clear();
    _notes = '';
    notifyListeners();
  }
}

// ==========================================================================
// 3. INTERFAZ DE USUARIO ADAPTATIVA (Equivalente al HTML / SCSS de Angular)
// ==========================================================================

class TomarOrdenPage extends StatelessWidget {
  const TomarOrdenPage({super.key});

  // Helper local para formato de moneda mexicana (currency:'MXN')
  String formatCurrency(double value) => '\$${value.toStringAsFixed(2)} MXN';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TomarOrdenProvider(),
      child: Scaffold(
        backgroundColor: Colors.grey[50], // var(--bg-primary)
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Breakpoint adaptado de la directiva CSS @media (max-width: 1200px)
              final isMobile = constraints.maxWidth <= 1200;
              
              if (isMobile) {
                return const _MenuSection(isMobile: true);
              } else {
                // Modo Desktop: Split Screen (Menu extendido + Barra lateral de carrito fija)
                return Row(
                  children: [
                    const Expanded(flex: 7, child: _MenuSection(isMobile: false)),
                    VerticalDivider(width: 1, color: Colors.grey[300]),
                    const SizedBox(width: 380, child: _CartSection(isMobile: false)),
                  ],
                );
              }
            },
          ),
        ),
        // FAB flotante únicamente activo en pantallas móviles o tablets
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
      ),
    );
  }

  // Abre el carrito en la parte inferior como un Drawer en móviles (max-height: 76vh;)
  void _openMobileCart(BuildContext context) {
    final provider = context.read<TomarOrdenProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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

// --- VISTA IZQUIERDA: BUSCADOR, CATEGORÍAS Y PRODUCTOS ---
class _MenuSection extends StatelessWidget {
  final bool isMobile;
  const _MenuSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Principal
          const Text('Tomar Orden', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text('Registra los productos del cliente', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 14),

          // Selector de Tipo de Orden: Dine-in / Takeaway
          Row(
            children: [
              _buildTypeButton(context, 'Comer Aquí', OrderType.dineIn, provider),
              const SizedBox(width: 8),
              _buildTypeButton(context, 'Para Llevar', OrderType.takeaway, provider),
            ],
          ),
          const SizedBox(height: 14),

          // Selectores de Área y Mesas Dinámicos (*ngIf="orderType() === 'dine-in'")
          if (provider.orderType == OrderType.dineIn) ...[
            _buildChipsRow(context, 'Área:', provider.areas, provider.selectedArea, (v) => provider.setArea(v)),
            const SizedBox(height: 8),
            _buildChipsRow(context, 'Mesa:', provider.currentTables, provider.selectedTable, (v) => provider.setTable(v)),
            const SizedBox(height: 14),
          ],

          // Input de Búsqueda (app-search-input)
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, desc...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => provider.setSearchTerm(v),
          ),
          const SizedBox(height: 14),

          // Chips horizontales de Categoría
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
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => provider.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Grid Principal de productos con Empty State integrado
          Expanded(
            child: provider.visibleProducts.isEmpty
                ? const Center(child: Text('No hay productos que coincidan con la búsqueda.', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : (isMobile ? 2 : 3),
                      childAspectRatio: isMobile ? 1.25 : 1.35,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: provider.visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = provider.visibleProducts[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => provider.addToCart(product),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.category.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Expanded(child: Text(product.description, style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
    return Expanded(
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
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
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
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
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
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

// --- VISTA DERECHA/BOTTOM SHEET: DETALLE DEL CARRITO ---
class _CartSection extends StatelessWidget {
  final bool isMobile;
  const _CartSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomarOrdenProvider>();

    return Column(
      children: [
        // Header del Carrito (Mesa X o Para Llevar)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.orderType == OrderType.dineIn ? 'Mesa ${provider.selectedTable}' : 'Para Llevar',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(provider.orderType == OrderType.dineIn ? 'Servicio en Mesa' : 'Recoger en Cocina', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Text('${provider.itemsCount} Items', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              if (isMobile)
                IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context))
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista de Productos en el carrito
        Expanded(
          child: provider.cart.isEmpty
              ? const Center(child: Text('El carrito está vacío', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final item = provider.cart[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Controles incrementales/decrementales
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.grey),
                                      onPressed: () => provider.decrement(item),
                                    ),
                                    Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.grey),
                                      onPressed: () => provider.increment(item),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => provider.remove(item),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Footer del Carrito (Notas, Totalizadores y Botón de Envío)
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Notas de la orden (ej: sin cebolla)...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) => provider.setNotes(v),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total General', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(
                    '\$${provider.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: provider.cart.isEmpty
                      ? null
                      : () {
                          provider.sendOrder();
                          if (isMobile) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Orden mandada a la cocina exitosamente')),
                          );
                        },
                  child: const Text('Enviar a Cocina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}