import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
import '../models/product.dart'; // Importación crucial

class ProductosPage extends StatelessWidget {
  // CORRECCIÓN: super.key
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: provider.setSearchTerm,
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: provider.categorias.length,
              itemBuilder: (context, index) {
                final cat = provider.categorias[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: cat == provider.selectedCategory,
                    onSelected: (selected) {
                      if (selected) provider.setCategory(cat);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: provider.productosFiltrados.isEmpty
                ? const Center(child: Text('No hay productos para mostrar.'))
                : ListView.builder(
                    itemCount: provider.productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = provider.productosFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text(producto.nombre,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${producto.categoria} | Stock: ${producto.stock} ${producto.unidad}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('\$${producto.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _mostrarDialogoFormulario(
                                    context, producto),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  if (producto.id != null) {
                                    provider.deleteProducto(producto.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoFormulario(context, null),
        label: const Text('Nuevo Producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoFormulario(
      BuildContext context, Producto? productoExistente) {
    final provider = context.read<ProductosProvider>();
    final isEditing = productoExistente != null;

    final nombreCtrl =
        TextEditingController(text: isEditing ? productoExistente.nombre : '');
    final precioCtrl = TextEditingController(
        text: isEditing ? productoExistente.precio.toString() : '');
    final stockCtrl = TextEditingController(
        text: isEditing ? productoExistente.stock.toString() : '');

    String categoriaSeleccionada = isEditing
        ? productoExistente.categoria
        : provider.categorias.firstWhere((c) => c != 'Todas');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Producto' : 'Añadir Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del producto'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: precioCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Precio (\$)', prefixText: '\$'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Stock actual'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    // CORRECCIÓN: initialValue en lugar de value
                    initialValue:
                        provider.categorias.contains(categoriaSeleccionada)
                            ? categoriaSeleccionada
                            : null,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: provider.categorias
                        .where((c) => c != 'Todas')
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => categoriaSeleccionada = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nuevoProducto = Producto(
                    id: productoExistente?.id,
                    nombre: nombreCtrl.text,
                    precio: double.tryParse(precioCtrl.text) ?? 0.0,
                    stock: int.tryParse(stockCtrl.text) ?? 0,
                    categoria: categoriaSeleccionada,
                    unidad: productoExistente?.unidad ?? 'unidad',
                  );

                  if (isEditing) {
                    provider.updateProducto(productoExistente.id ?? '', nuevoProducto);
                  } else {
                    provider.addProducto(nuevoProducto);
                  }
                  Navigator.pop(dialogContext);
                },
                child: Text(isEditing ? 'Guardar Cambios' : 'Añadir'),
              ),
            ],
          );
        });
      },
    );
  }
}
