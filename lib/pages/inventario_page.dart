import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';
import '../utils/ui_utils.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => InventarioProvider(), child: const _InventarioView());
  }
}

class _InventarioView extends StatelessWidget {
  const _InventarioView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🍎 ', style: TextStyle(fontSize: 26)),
                      Text('Inventario', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: Text('${provider.alertasStock} alertas de stock', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextField(decoration: InputDecoration(hintText: 'Buscar insumo...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: provider.onSearch),
                  ),
                  const SizedBox(width: 15),
                  FilterChip(
                    label: const Text('Ver bajo stock'),
                    selected: provider.showLowStock,
                    onSelected: provider.toggleLowStock,
                    selectedColor: Colors.orange.withAlpha(50),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                      columns: const [
                        DataColumn(label: Text('Insumo')),
                        DataColumn(label: Text('Unidad')),
                        DataColumn(label: Text('Stock Actual')),
                        DataColumn(label: Text('Stock Mínimo')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: provider.filteredInsumos.map((i) {
                        final bool isLow = i.currentStock <= i.minStock;
                        return DataRow(cells: [
                          DataCell(Text(i.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(i.unit, style: const TextStyle(color: Colors.grey))),
                          DataCell(Text(i.currentStock.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isLow ? Colors.red : Colors.green))),
                          DataCell(Text(i.minStock.toString())),
                          DataCell(isLow ? const Icon(Icons.warning, color: Colors.orange, size: 20) : const Icon(Icons.check_circle, color: Colors.green, size: 20)),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                String nuevoVal = i.currentStock.toString();
                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                  title: Text('Ajustar ${i.name}'),
                                  content: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nuevo Stock'), onChanged: (v) => nuevoVal = v),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                    ElevatedButton(onPressed: () {
                                      provider.ajustarStock(i.id, double.tryParse(nuevoVal) ?? i.currentStock);
                                      Navigator.pop(ctx);
                                      UiUtils.showToast(context, 'Stock actualizado');
                                    }, child: const Text('Guardar'))
                                  ],
                                ));
                              }, 
                              child: const Text('Ajustar')
                            )
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}