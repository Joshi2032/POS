import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

// Modelos internos para la gestión de la comanda
class ProductoOrden {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;

  ProductoOrden({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
  });
}

class ItemCarrito {
  final ProductoOrden producto;
  int cantidad;
  String notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.notas = '', // <-- CORREGIDO: Cambiado de this.notes a this.notas
  });

  double get total => producto.precio * cantidad;
}

class TomarOrdenPage extends StatefulWidget {
  const TomarOrdenPage({super.key});

  @override
  State<TomarOrdenPage> createState() => _TomarOrdenPageState();
}

class _TomarOrdenPageState extends State<TomarOrdenPage> {
  // Catálogo de productos simulado de La Brasa
  final List<ProductoOrden> _catalogo = [
    ProductoOrden(id: '1', nombre: 'Arrachera 300g', categoria: 'Parrilla', precio: 285.00),
    ProductoOrden(id: '2', nombre: 'T-Bone 500g', categoria: 'Parrilla', precio: 450.00),
    ProductoOrden(id: '3', nombre: 'Costillas BBQ', categoria: 'Parrilla', precio: 320.00),
    ProductoOrden(id: '4', nombre: 'Chorizo Argentino', categoria: 'Entradas', precio: 110.00),
    ProductoOrden(id: '5', nombre: 'Papas al Horno', categoria: 'Guarniciones', precio: 65.00),
    ProductoOrden(id: '6', nombre: 'Ensalada César', categoria: 'Ensaladas', precio: 125.00),
    ProductoOrden(id: '7', nombre: 'Cerveza Artesanal', categoria: 'Bebidas', precio: 85.00),
    ProductoOrden(id: '8', nombre: 'Refresco Familiar', categoria: 'Bebidas', precio: 45.00),
    ProductoOrden(id: '9', nombre: 'Flan Napolitano', categoria: 'Postres', precio: 75.00),
  ];

  final List<ItemCarrito> _carrito = [];
  String _selectedCategory = 'Todas';
  String _searchTerm = '';
  String _selectedMesa = 'Mesa 1';

  final List<String> _categorias = ['Todas', 'Parrilla', 'Entradas', 'Guarniciones', 'Bebidas', 'Postres'];
  final List<String> _mesas = ['Mesa 1', 'Mesa 2', 'Mesa 3', 'Mesa 4', 'Mesa 5', 'Barra 1', 'Para Llevar'];

  List<ProductoOrden> get _productosFiltrados {
    return _catalogo.where((p) {
      final matchesSearch = p.nombre.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todas' || p.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  double get _subtotal => _carrito.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal;

  void _agregarAlCarrito(ProductoOrden producto) {
    setState(() {
      final existe = _carrito.indexWhere((item) => item.producto.id == producto.id);
      if (existe >= 0) {
        _carrito[existe].cantidad++;
      } else {
        _carrito.add(ItemCarrito(producto: producto));
      }
    });
  }

  void _cambiarCantidad(int index, int cambio) {
    setState(() {
      _carrito[index].cantidad += cambio;
      if (_carrito[index].cantidad <= 0) {
        _carrito.removeAt(index);
      }
    });
  }

  void _limpiarComanda() {
    setState(() {
      _carrito.clear();
    });
  }

  void _enviarACocina() {
    if (_carrito.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Comanda enviada a Cocina con éxito para $_selectedMesa'),
      ),
    );
    _limpiarComanda();
  }

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final esPantallaAncha = constraints.maxWidth > 1100;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // SECCIÓN IZQUIERDA: CATÁLOGO DE PRODUCTOS
                // ==========================================
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Tomar Orden',
                        subtitle: 'Selecciona los productos de la comanda',
                      ),
                      const SizedBox(height: 20),
                      
                      TextField(
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar producto por nombre...',
                        ),
                        onChanged: (v) => setState(() => _searchTerm = v),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categorias.length,
                          itemBuilder: (context, idx) {
                            final cat = _categorias[idx];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: Theme.of(context).primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected 
                                      ? Colors.white 
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                ),
                                backgroundColor: Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Theme.of(context).dividerColor)
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedCategory = cat);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: productos.length,
                          itemBuilder: (context, idx) {
                            final prod = productos[idx];
                            return InkWell(
                              onTap: () => _agregarAlCarrito(prod),
                              borderRadius: BorderRadius.circular(8),
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.categoria.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Text(
                                        prod.nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${prod.precio.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Theme.of(context).primaryColor,
                                          size: 20,
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
                    ],
                  ),
                ),
                
                if (esPantallaAncha) ...[
                  const SizedBox(width: 24),
                  
                  // ==========================================
                  // SECCIÓN DERECHA: PANEL DE LA COMANDA (CARRITO)
                  // ==========================================
                  SizedBox(
                    width: 380,
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Comanda Actual', style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                tooltip: 'Limpiar Todo',
                                onPressed: _carrito.isEmpty ? null : _limpiarComanda,
                              )
                            ],
                          ),
                          const Divider(),
                          
                          DropdownButtonFormField<String>(
                            dropdownColor: Theme.of(context).cardColor,
                            initialValue: _selectedMesa,
                            decoration: const InputDecoration(
                              labelText: 'Asignar Mesa / Servicio',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _mesas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (v) => setState(() => _selectedMesa = v!),
                          ),
                          const SizedBox(height: 16),
                          
                          Expanded(
                            child: _carrito.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                                        const SizedBox(height: 8),
                                        Text('La comanda está vacía', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _carrito.length,
                                    separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                                    itemBuilder: (context, idx) {
                                      final item = _carrito[idx];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(height: 2),
                                                Text('\$${item.producto.precio.toStringAsFixed(2)} c/u', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                                              ],
                                            ),
                                          ),
                                          
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                                onPressed: () => _cambiarCantidad(idx, -1),
                                              ),
                                              Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                                onPressed: () => _cambiarCantidad(idx, 1),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              '\$${item.total.toStringAsFixed(2)}',
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          
                          const Divider(),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Cuenta:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                                Text(
                                  '\$${_total.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: _carrito.isEmpty ? null : _enviarACocina,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department),
                                  SizedBox(width: 8),
                                  Text('Enviar a Cocina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}