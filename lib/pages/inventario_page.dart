import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Registramos el provider a nivel página
    return ChangeNotifierProvider(
      create: (_) => InventarioProvider(),
      child: const _InventarioView(),
    );
  }
}

class _InventarioView extends StatefulWidget {
  const _InventarioView();

  @override
  State<_InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<_InventarioView> {
  void openEditor(InventarioProvider provider, {Map<String, dynamic>? item}) {
    final idController = TextEditingController(text: item?['id'] ?? 'IT-${DateTime.now().millisecondsSinceEpoch}');
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final categoryController = TextEditingController(text: item?['category'] ?? '');
    final stockController = TextEditingController(text: item?['stock']?.toString() ?? '0');
    final costController = TextEditingController(text: item?['cost']?.toString() ?? '0');
    final providerController = TextEditingController(text: item?['provider'] ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(item == null ? 'Agregar Insumo' : 'Editar Insumo'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Categoría')),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                TextField(controller: costController, decoration: const InputDecoration(labelText: 'Costo'), keyboardType: TextInputType.number),
                TextField(controller: providerController, decoration: const InputDecoration(labelText: 'Proveedor')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final data = {
                  'id': idController.text,
                  'name': nameController.text,
                  'category': categoryController.text,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'cost': double.tryParse(costController.text) ?? 0.0,
                  'provider': providerController.text,
                };

                if (item == null) {
                  provider.addInventoryItem(data);
                } else {
                  provider.updateInventoryItem(item['id'], data);
                }

                Navigator.pop(context);
              },
              child: const Text('Guardar')
            )
          ],
        );
      }
    );
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
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar insumos'),
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
                          title: Text(it['name']),
                          subtitle: Text('Stock: ${it['stock']} · ${it['category']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => openEditor(provider, item: it),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => provider.removeInventoryItem(it['id'] as String),
                              ),
                            ]
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(provider),
        icon: const Icon(Icons.add),
        label: const Text('Agregar')
      ),
    );
  }
}