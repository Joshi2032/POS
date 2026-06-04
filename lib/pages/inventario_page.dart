import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../providers/categorias_provider.dart';
import '../providers/inventario_provider.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InventarioView();
  }
}

class _InventarioView extends StatefulWidget {
  const _InventarioView();

  @override
  State<_InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<_InventarioView> {
  Future<void> openEditor(InventarioProvider provider,
      {InventoryItem? item}) async {
    final categoriasProvider = context.read<CategoriasProvider>();

    // Si no hay categorías cargadas, esperamos a que carguen
    if (categoriasProvider.categorias.isEmpty) {
      await categoriasProvider.cargarCategorias();
    }

    if (!mounted) return;

    final categorias = categoriasProvider.categorias
        .map((cat) => cat['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    if (item != null &&
        item.category.isNotEmpty &&
        !categorias.contains(item.category)) {
      categorias.insert(0, item.category);
    }

    final generatedId =
        item?.id ?? 'IT-${DateTime.now().millisecondsSinceEpoch}';
    final idController = TextEditingController(text: generatedId);
    final categoryController = TextEditingController(
        text:
            item?.category ?? (categorias.isNotEmpty ? categorias.first : ''));
    final nameController = TextEditingController(text: item?.name ?? '');
    final stockController =
        TextEditingController(text: item?.stock.toString() ?? '0');
    final costController =
        TextEditingController(text: item?.cost.toString() ?? '0');
    final providerController =
        TextEditingController(text: item?.provider ?? '');

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(item == null ? 'Agregar Insumo' : 'Editar Insumo'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item != null) ...[
                    TextField(
                      controller: idController,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'ID'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: categorias.contains(categoryController.text)
                        ? categoryController.text
                        : null,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categorias
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: categorias.isNotEmpty
                        ? (value) {
                            if (value != null) {
                              categoryController.text = value;
                            }
                          }
                        : null,
                    hint: const Text('Selecciona una categoría'),
                    disabledHint: const Text('No hay categorías disponibles'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(
                      controller: costController,
                      decoration: const InputDecoration(labelText: 'Costo'),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(
                      controller: providerController,
                      decoration:
                          const InputDecoration(labelText: 'Proveedor')),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () async {
                    final inventoryItem = InventoryItem(
                      id: generatedId,
                      name: nameController.text,
                      category: categoryController.text,
                      stock: double.tryParse(stockController.text) ?? 0.0,
                      cost: double.tryParse(costController.text) ?? 0.0,
                      provider: providerController.text,
                    );

                    bool success = false;
                    if (item == null) {
                      success = await provider.addInventoryItem(inventoryItem);
                    } else {
                      success = await provider.updateInventoryItem(
                          item.id, inventoryItem);
                    }

                    if (mounted && success) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Guardar'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el InventarioProvider
    final provider = context.watch<InventarioProvider>();
    final items = provider.filteredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Buscar insumos'),
              onChanged: provider.setSearch, // Conectado al Provider
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No hay insumos'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        return ListTile(
                          title: Text(it.name),
                          subtitle: Text('Stock: ${it.stock} · ${it.category}'),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await openEditor(provider, item: it);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  provider.removeInventoryItem(it.id),
                            ),
                          ]),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await openEditor(provider);
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar')),
    );
  }
}
