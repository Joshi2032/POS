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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final horizontalPadding = isNarrow ? 12.0 : 16.0;

          return provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.hasError
                  ? Center(
                      child: Text(
                          provider.errorMessage ?? 'Error al cargar productos'))
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
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

                                final acciones = Row(
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
                                      visualDensity: VisualDensity.compact,
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
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar producto',
                                      onPressed: () =>
                                          _mostrarDialogoFormulario(
                                              context, producto),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar producto',
                                      onPressed: () => _confirmarEliminar(
                                          context, provider, producto),
                                    ),
                                  ],
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final esAngosta =
                                          constraints.maxWidth < 420;

                                      if (esAngosta) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 12, 8, 4),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${producto.category} | Stock: ${producto.stock} ${producto.unit}',
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: acciones,
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListTile(
                                        title: Text(producto.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                            '${producto.category} | Stock: ${producto.stock} ${producto.unit}'),
                                        trailing: acciones,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                        ),
                      );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoFormulario(context, null),
        label: const Text('Nuevo Producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _mostrarDialogoFormulario(
      BuildContext context, Producto? productoExistente) async {
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

    await showDialog(
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrowField = constraints.maxWidth < 520;
                        final fieldWidth = isNarrowField
                            ? double.infinity
                            : (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: fieldWidth,
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
                            SizedBox(
                              width: fieldWidth,
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
                        );
                      },
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
                                  // Antes esto hacía pop() del diálogo y
                                  // luego intentaba reabrirlo comprobando
                                  // dialogContext.mounted — pero como el pop
                                  // ya lo había cerrado, esa comprobación
                                  // casi siempre daba false y el diálogo
                                  // nunca se reabría. Ahora simplemente se
                                  // refresca en el mismo diálogo abierto.
                                  await provider.cargarDatosCompletos();
                                  if (!dialogContext.mounted) return;
                                  setState(() {});
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
                        if (nombreCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es obligatorio.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final precio =
                            double.tryParse(precioCtrl.text.trim());
                        if (precio == null || precio <= 0) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingresa un precio numérico mayor a 0.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final stock = int.tryParse(stockCtrl.text.trim());
                        if (stock == null || stock < 0) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingresa un stock numérico válido (0 o mayor).',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final uuidCategoria = provider
                            .getCategoryIdByName(categoriaSeleccionada!);
                        final uuidReceta =
                            provider.getRecipeIdByName(recetaSeleccionada!);

                        final nuevoProducto = Producto(
                          id: productoExistente?.id ?? '',
                          name: nombreCtrl.text.trim(),
                          description: descCtrl.text,
                          category: categoriaSeleccionada!,
                          categoryId: uuidCategoria,
                          price: precio,
                          stock: stock,
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

    nombreCtrl.dispose();
    descCtrl.dispose();
    precioCtrl.dispose();
    stockCtrl.dispose();
    unidadCtrl.dispose();
  }

  void _confirmarEliminar(
    BuildContext context,
    ProductosProvider provider,
    Producto producto,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Seguro que deseas eliminar "${producto.name}"? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);

                final exito = await provider.deleteProducto(producto.id);

                if (!exito) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'No se pudo eliminar el producto.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
