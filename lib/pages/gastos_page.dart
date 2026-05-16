import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  String search = '';
  String selectedCategory = 'Todos';
  int currentPage = 1;
  final pageSize = 10;
  final categorias = [
    'Todos',
    'Renta',
    'Servicios',
    'Insumos',
    'Mantenimiento',
    'Publicidad',
    'Impuestos',
    'General'
  ];

  void _openEditor({Map<String, dynamic>? gasto}) {
    final idController = TextEditingController(
        text: gasto?['id'] ?? 'G-${DateTime.now().millisecondsSinceEpoch}');
    final dateController = TextEditingController(
        text: gasto?['date'] ??
            DateTime.now().toIso8601String().split('T').first);
    final conceptController =
        TextEditingController(text: gasto?['concept'] ?? '');
    final amountController =
        TextEditingController(text: gasto?['amount']?.toString() ?? '0');
    final notesController = TextEditingController(text: gasto?['notes'] ?? '');
    String category = gasto?['category'] ?? 'General';
    String method = gasto?['method'] ?? 'Efectivo';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(gasto == null ? 'Agregar Gasto' : 'Editar Gasto'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'ID'),
                    readOnly: true),
                TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Fecha')),
                TextField(
                    controller: conceptController,
                    decoration: const InputDecoration(labelText: 'Concepto')),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: [
                    'General',
                    'Insumos',
                    'Servicios',
                    'Renta',
                    'Mantenimiento',
                    'Publicidad',
                    'Impuestos'
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? 'General'),
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  items: ['Efectivo', 'Tarjeta', 'Transferencia']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => method = value ?? 'Efectivo'),
                  decoration: const InputDecoration(labelText: 'Método'),
                ),
                TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notas')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final app = context.read<AppState>();
                final data = {
                  'id': idController.text,
                  'date': dateController.text,
                  'concept': conceptController.text.trim(),
                  'category': category,
                  'method': method,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'notes': notesController.text,
                };
                if (gasto == null) {
                  app.addGasto(data);
                } else {
                  app.updateGasto(gasto['id'], data);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gastos = app.gastos.where((g) {
      final matchSearch = search.isEmpty ||
          [g['concept'], g['category'], g['method']]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(search.toLowerCase()));
      final matchCat =
          selectedCategory == 'Todos' || g['category'] == selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    final totalPages = (gastos.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = gastos.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Buscar gasto...'),
              onChanged: (value) => setState(() {
                search = value;
                currentPage = 1;
              }),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categorias
                    .map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(cat),
                            selected: selectedCategory == cat,
                            onSelected: (selected) => setState(() {
                              selectedCategory = cat;
                              currentPage = 1;
                            }),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Este mes',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_money.format(app.totalGastosEstesMes),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Total',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                            _money.format(app.gastos.fold(0.0,
                                (sum, g) => sum + (g['amount'] as double))),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: paginated.isEmpty
                  ? const Center(child: Text('No hay gastos que coincidan.'))
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final gasto = paginated[index];
                        return ListTile(
                          title: Text(gasto['concept'] ?? ''),
                          subtitle:
                              Text('${gasto['category']} · ${gasto['date']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_money.format(gasto['amount'] ?? 0.0)),
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEditor(gasto: gasto)),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      app.removeGasto(gasto['id'])),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                        onPressed: currentPage > 1
                            ? () => setState(() => currentPage--)
                            : null,
                        child: const Text('Anterior')),
                    const SizedBox(width: 12),
                    Text('Página $currentPage de $totalPages'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                        onPressed: currentPage < totalPages
                            ? () => setState(() => currentPage++)
                            : null,
                        child: const Text('Siguiente')),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _openEditor,
          icon: const Icon(Icons.add),
          label: const Text('Agregar')),
    );
  }
}
