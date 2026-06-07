import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
import '../models/product.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProductosView();
  }
}

class _ProductosView extends StatelessWidget {
  const _ProductosView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar categorías',
            onPressed: provider.cargarDatosCompletos,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.hasError
              ? Center(
                  child: Text(
                      provider.errorMessage ?? 'Error al cargar productos'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Buscar producto...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
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
                          ? const Center(
                              child: Text('No hay productos para mostrar.'))
                          : ListView.builder(
                              itemCount: provider.productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto =
                                    provider.productosFiltrados[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: ListTile(
                                    title: Text(producto.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '${producto.category} | Stock: ${producto.stock} ${producto.unit}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                     children: [
  Text(
    '\$${producto.price.toStringAsFixed(2)}',
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),

  IconButton(
    icon: Icon(
      producto.active
          ? Icons.visibility
          : Icons.visibility_off,
      color: producto.active
          ? Colors.green
          : Colors.orange,
    ),
    tooltip: producto.active
        ? 'Desactivar'
        : 'Activar',
    onPressed: () async {
      await provider.toggleProducto(
        producto.id,
        !producto.active,
      );
    },
  ),

  IconButton(
    icon: const Icon(
      Icons.edit,
      color: Colors.blue,
    ),
    onPressed: () =>
        _mostrarDialogoFormulario(
            context, producto),
  ),

  IconButton(
    icon: const Icon(
      Icons.delete,
      color: Colors.red,
    ),
    onPressed: () =>
        provider.deleteProducto(producto.id),
  ),
],
                                  ),
                                  )
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
        TextEditingController(text: isEditing ? productoExistente.name : '');
    final descCtrl = TextEditingController(
        text: isEditing ? productoExistente.description : '');
    final precioCtrl = TextEditingController(
        text: isEditing ? productoExistente.price.toString() : '');
    final stockCtrl = TextEditingController(
        text: isEditing ? productoExistente.stock.toString() : '');
    final unidadCtrl =
        TextEditingController(text: isEditing ? productoExistente.unit : '');

    String? categoriaSeleccionada =
        isEditing ? productoExistente.category : null;

    // LÓGICA DE RECETAS PARA EL FORMULARIO
    String? recetaSeleccionada = 'Ninguna';
    if (isEditing && productoExistente.recipeId != null) {
      final match = provider.recetas.firstWhere(
          (name) =>
              provider.getRecipeIdByName(name) == productoExistente.recipeId,
          orElse: () => 'Ninguna');
      recetaSeleccionada = match;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          final categoriasDisponibles =
              provider.categorias.where((c) => c != 'Todos').toList();
          if (categoriaSeleccionada == null &&
              categoriasDisponibles.isNotEmpty) {
            categoriaSeleccionada = categoriasDisponibles.first;
          }

          return AlertDialog(
            title: Text(isEditing ? 'Editar Producto' : 'Añadir Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: precioCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Precio (\$)',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: unidadCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unidad (pz, kg, etc.)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: categoriasDisponibles.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aún no hay categorías. Crea las categorías en la página "Categorías" y luego actualiza esta lista.',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar categorías'),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await provider.cargarDatosCompletos();
                                  if (!dialogContext.mounted) return;
                                  _mostrarDialogoFormulario(
                                      context, productoExistente);
                                },
                              ),
                            ],
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: categoriasDisponibles
                                    .contains(categoriaSeleccionada)
                                ? categoriaSeleccionada
                                : categoriasDisponibles.first,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                            ),
                            items: categoriasDisponibles
                                .map((cat) => DropdownMenuItem(
                                    value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => categoriaSeleccionada = val);
                              }
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          provider.recetas.contains(recetaSeleccionada)
                              ? recetaSeleccionada
                              : 'Ninguna',
                      decoration: const InputDecoration(
                        labelText: 'Receta a descontar (Opcional)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                      items: provider.recetas
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => recetaSeleccionada = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: categoriasDisponibles.isEmpty
                    ? null
                    : () async {
                        final uuidCategoria = provider
                            .getCategoryIdByName(categoriaSeleccionada!);
                        final uuidReceta =
                            provider.getRecipeIdByName(recetaSeleccionada!);

                        final nuevoProducto = Producto(
                          id: productoExistente?.id ?? '',
                          name: nombreCtrl.text,
                          description: descCtrl.text,
                          category: categoriaSeleccionada!,
                          categoryId: uuidCategoria,
                          price: double.tryParse(precioCtrl.text) ?? 0.0,
                          stock: int.tryParse(stockCtrl.text) ?? 0,
                          active: productoExistente?.active ?? true,
                          unit: unidadCtrl.text,
                          recipeId: uuidReceta, // Vinculamos la receta
                        );

                        bool exito;
                        if (isEditing) {
                          exito = await provider.updateProducto(
                              productoExistente.id, nuevoProducto);
                        } else {
                          exito = await provider.addProducto(nuevoProducto);
                        }

                        if (!dialogContext.mounted) return;

                        if (exito) {
                          Navigator.pop(dialogContext);
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                                content: Text(provider.errorMessage ??
                                    'Error al guardar en Supabase'),
                                backgroundColor: Colors.red),
                          );
                        }
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
