import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart'; // Importamos tu AppCard y SectionHeader
import '../widgets/layout_widgets.dart'; // Importamos tu EmptyState

class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String unidad;

  Producto({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.unidad,
  });
}

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final List<Producto> _productos = [
    Producto(
        nombre: 'Arrachera 300g',
        categoria: 'Parrilla',
        precio: 285,
        stock: 40,
        unidad: 'plato'),
    Producto(
        nombre: 'T-Bone 500g',
        categoria: 'Parrilla',
        precio: 450,
        stock: 15,
        unidad: 'plato'),
    Producto(
        nombre: 'Costillas BBQ',
        categoria: 'Parrilla',
        precio: 320,
        stock: 25,
        unidad: 'rack'),
    Producto(
        nombre: 'Cerveza Artesanal',
        categoria: 'Bebidas',
        precio: 85,
        stock: 100,
        unidad: 'tarro'),
  ];

  String _searchTerm = '';
  String _selectedCategory = '';

  final List<String> _categorias = [
    'Todas',
    'Parrilla',
    'Entradas',
    'Guarniciones',
    'Ensaladas',
    'Bebidas',
    'Postres'
  ];

  List<Producto> get _productosFiltrados {
    return _productos.where((p) {
      final matchesSearch =
          p.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              p.unidad.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory.isEmpty ||
          _selectedCategory == 'Todas' ||
          p.categoria.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _formCategoria = 'Parrilla';
  String _formUnidad = 'orden';

  void _abrirFormularioModal({Producto? producto, int? index}) {
    if (producto != null) {
      _nombreCtrl.text = producto.nombre;
      _precioCtrl.text = producto.precio.toString();
      _stockCtrl.text = producto.stock.toString();
      _formCategoria = producto.categoria;
      _formUnidad = producto.unidad;
    } else {
      _nombreCtrl.clear();
      _precioCtrl.clear();
      _stockCtrl.clear();
      _formCategoria = 'Parrilla';
      _formUnidad = 'orden';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                  producto != null ? 'Editar Producto' : 'Nuevo Producto',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nombre', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        initialValue: _formCategoria,
                        decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder()),
                        items: _categorias
                            .where((c) => c != 'Todas')
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => _formCategoria = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _precioCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Precio',
                            prefixText: '\$',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Theme.of(context).cardColor,
                              initialValue: _formUnidad,
                              decoration: const InputDecoration(
                                  labelText: 'Unidad',
                                  border: OutlineInputBorder()),
                              items: [
                                'orden',
                                'plato',
                                'pieza',
                                'botella',
                                'porción',
                                'vaso',
                                'jarra',
                                'cazuela',
                                'tarro',
                                'copa'
                              ]
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => _formUnidad = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Stock',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Req.' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final nuevo = Producto(
                        nombre: _nombreCtrl.text,
                        categoria: _formCategoria,
                        precio: double.tryParse(_precioCtrl.text) ?? 0,
                        stock: int.tryParse(_stockCtrl.text) ?? 0,
                        unidad: _formUnidad,
                      );
                      setState(() {
                        if (index != null) {
                          _productos[index] = nuevo;
                        } else {
                          _productos.add(nuevo);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(producto != null ? 'Guardar Cambios' : 'Agregar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _solicitarBorrado(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Se eliminará "${producto.nombre}". ¿Estás seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _productos.remove(producto));
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _productosFiltrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '🍔 Productos',
              subtitle:
                  '${filtrados.length} de ${_productos.length} productos registrados',
              actionLabel: 'Agregar Producto',
              onAction: () => _abrirFormularioModal(),
            ),
            const SizedBox(height: 24),

            // 2. MÓDULO CORREGIDO: Barra de Búsqueda y Filtros adaptativos
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre o unidad...',
                      // Quitamos fillColor y filled para delegar al InputDecorationTheme global
                    ),
                    onChanged: (v) => setState(() => _searchTerm = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context)
                        .cardColor, // Menú desplegable flotante adaptativo
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    initialValue:
                        _selectedCategory.isEmpty ? 'Todas' : _selectedCategory,
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface))))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _selectedCategory = v == 'Todas' ? '' : v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Contenido (Grilla o Estado Vacío)
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message:
                          'No hay productos que coincidan con tu búsqueda.\nIntenta con otros filtros.',
                      icon: Icons.fastfood_outlined,
                      actionLabel: 'Limpiar Filtros',
                      onAction: () {
                        setState(() {
                          _searchTerm = '';
                          _selectedCategory = '';
                        });
                      },
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, idx) {
                        final producto = filtrados[idx];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  // CORRECCIÓN: Usamos .withValues en vez de .withOpacity para evitar warnings
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(producto.categoria.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor)),
                              ),
                              const SizedBox(height: 8),
                              Text(producto.nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  'Stock disponible: ${producto.stock} ${producto.unidad}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '\$${producto.precio.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w800)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20, color: Colors.blueGrey),
                                        tooltip: 'Editar',
                                        onPressed: () => _abrirFormularioModal(
                                            producto: producto,
                                            index:
                                                _productos.indexOf(producto)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        tooltip: 'Eliminar',
                                        onPressed: () =>
                                            _solicitarBorrado(producto),
                                      ),
                                    ],
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
}
