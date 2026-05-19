import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProductosView();
  }
}

class _ProductosView extends StatefulWidget {
  const _ProductosView();

  @override
  State<_ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<_ProductosView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _formCategoria = 'Parrilla';
  String _formUnidad = 'orden';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _abrirFormularioModal(ProductosProvider provider,
      {Producto? producto, int? index}) {
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
                        items: provider.categorias
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

                      // Usamos el provider en lugar de setState
                      if (index != null) {
                        provider.updateProducto(index, nuevo);
                      } else {
                        provider.addProducto(nuevo);
                      }
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

  void _solicitarBorrado(ProductosProvider provider, Producto producto) {
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
              provider.removeProducto(producto);
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
    // Conectamos la interfaz al Provider
    final provider = context.watch<ProductosProvider>();
    final filtrados = provider.productosFiltrados;

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
                  '${filtrados.length} de ${provider.productos.length} productos registrados',
              actionLabel: 'Agregar Producto',
              onAction: () => _abrirFormularioModal(provider),
            ),
            const SizedBox(height: 24),
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
                    ),
                    onChanged: provider.setSearchTerm,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    initialValue: provider.selectedCategory.isEmpty
                        ? 'Todas'
                        : provider.selectedCategory,
                    items: provider.categorias
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface))))
                        .toList(),
                    onChanged: (v) =>
                        provider.setCategory(v == 'Todas' ? '' : v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message:
                          'No hay productos que coincidan con tu búsqueda.\nIntenta con otros filtros.',
                      icon: Icons.fastfood_outlined,
                      actionLabel: 'Limpiar Filtros',
                      onAction: () {
                        provider.setSearchTerm('');
                        provider.setCategory('');
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
                                            provider,
                                            producto: producto,
                                            index: provider.productos
                                                .indexOf(producto)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _solicitarBorrado(
                                            provider, producto),
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
