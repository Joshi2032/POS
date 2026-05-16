import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CombosPage extends StatefulWidget {
  const CombosPage({super.key});

  @override
  State<CombosPage> createState() => _CombosPageState();
}

class _ComboEditorData {
  String id;
  String title;
  String subtitle;
  List<String> tags;
  double price;
  double oldPrice;
  String ahorro;

  _ComboEditorData(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.tags,
      required this.price,
      required this.oldPrice,
      required this.ahorro});
}

class _CombosPageState extends State<CombosPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final List<Map<String, dynamic>> products = const [
    {'nombre': 'Agua de Jamaica', 'precio': 40},
    {'nombre': 'Arroz a la Mexicana', 'precio': 45},
    {'nombre': 'Cerveza Artesanal', 'precio': 85},
    {'nombre': 'Churros a la Brasa', 'precio': 75},
    {'nombre': 'Arracera 300g', 'precio': 285},
    {'nombre': 'Brochetas Mixtas', 'precio': 175},
    {'nombre': 'Chorizo Argentino', 'precio': 145},
    {'nombre': 'Costillas BBQ', 'precio': 320},
  ];

  String searchTerm = '';

  void _openEditor({Map<String, dynamic>? combo}) {
    final editor = _ComboEditorData(
      id: combo?['id'] ?? 'CMB-${DateTime.now().millisecondsSinceEpoch}',
      title: combo?['title'] ?? '',
      subtitle: combo?['subtitle'] ?? '',
      tags: List<String>.from(combo?['tags'] ?? const []),
      price: (combo?['price'] ?? 0).toDouble(),
      oldPrice: (combo?['oldPrice'] ?? 0).toDouble(),
      ahorro: combo?['ahorro'] ?? '',
    );
    final selected = <String, bool>{
      for (final p in products)
        p['nombre'] as String: editor.tags.contains(p['nombre'])
    };

    final titleController = TextEditingController(text: editor.title);
    final subtitleController = TextEditingController(text: editor.subtitle);
    final priceController = TextEditingController(
        text: editor.price == 0 ? '' : editor.price.toStringAsFixed(2));
    final oldPriceController = TextEditingController(
        text: editor.oldPrice == 0 ? '' : editor.oldPrice.toStringAsFixed(2));
    final ahorroController = TextEditingController(text: editor.ahorro);

    void recalcAhorro() {
      final oldPrice = double.tryParse(oldPriceController.text) ?? 0;
      final price = double.tryParse(priceController.text) ?? 0;
      if (oldPrice > price && price > 0) {
        ahorroController.text =
            'Ahorras \$${(oldPrice - price).toStringAsFixed(2)}';
      } else {
        ahorroController.text = '';
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(combo == null ? 'Nuevo Combo' : 'Editar Combo'),
              content: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                          controller: titleController,
                          decoration:
                              const InputDecoration(labelText: 'Nombre')),
                      TextField(
                          controller: subtitleController,
                          decoration:
                              const InputDecoration(labelText: 'Descripción')),
                      const SizedBox(height: 8),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Productos incluidos',
                              style: Theme.of(context).textTheme.titleSmall)),
                      const SizedBox(height: 4),
                      ...products.map((product) {
                        final name = product['nombre'] as String;
                        return CheckboxListTile(
                          value: selected[name] ?? false,
                          title: Text(name),
                          secondary: Text(_money.format(product['precio'])),
                          onChanged: (value) {
                            setDialogState(() {
                              selected[name] = value ?? false;
                              editor.tags = selected.entries
                                  .where((entry) => entry.value)
                                  .map((entry) => entry.key)
                                  .toList();
                            });
                          },
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: oldPriceController,
                                  decoration: const InputDecoration(
                                      labelText: 'Precio original'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) =>
                                      setDialogState(recalcAhorro))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: TextField(
                                  controller: priceController,
                                  decoration: const InputDecoration(
                                      labelText: 'Precio actual'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) =>
                                      setDialogState(recalcAhorro))),
                        ],
                      ),
                      TextField(
                          controller: ahorroController,
                          decoration:
                              const InputDecoration(labelText: 'Ahorro'),
                          readOnly: true),
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
                    final app = context.read<AppState>();
                    final selectedTags = selected.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();
                    final oldPrice =
                        double.tryParse(oldPriceController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final ahorro = oldPrice > price && price > 0
                        ? 'Ahorras \$${(oldPrice - price).toStringAsFixed(2)}'
                        : '';
                    final data = {
                      'id': editor.id,
                      'title': titleController.text.trim(),
                      'subtitle': subtitleController.text.trim(),
                      'tags': selectedTags,
                      'price': price,
                      'oldPrice': oldPrice,
                      'ahorro': ahorro,
                    };
                    if (combo == null) {
                      app.addCombo(data);
                    } else {
                      app.updateCombo(combo['id'], data);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final combos = app.combos.where((combo) {
      if (searchTerm.isEmpty) return true;
      final q = searchTerm.toLowerCase();
      return [
        combo['title'],
        combo['subtitle'],
        ...(combo['tags'] as List).cast<String>()
      ].whereType<String>().any((value) => value.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Combos y Paquetes')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar combo...'),
                    onChanged: (value) => setState(() => searchTerm = value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Combo')),
              ],
            ),
            const SizedBox(height: 16),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    '${combos.length} de ${app.combos.length} combos registrados',
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 12),
            Expanded(
              child: combos.isEmpty
                  ? const Center(
                      child:
                          Text('No hay combos que coincidan con tu búsqueda.'))
                  : ListView.separated(
                      itemCount: combos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final combo = combos[index];
                        final tags = (combo['tags'] as List).cast<String>();
                        final oldPrice =
                            (combo['oldPrice'] as num?)?.toDouble() ?? 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(combo['title'] ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          const SizedBox(height: 4),
                                          Text(combo['subtitle'] ?? ''),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _openEditor(combo: combo)),
                                        IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => app.removeCombo(
                                                combo['id'] as String)),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags
                                      .map((tag) => Chip(label: Text(tag)))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(_money.format(combo['price'] ?? 0.0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18)),
                                    const SizedBox(width: 12),
                                    if (oldPrice > 0)
                                      Text(_money.format(oldPrice),
                                          style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough)),
                                    const SizedBox(width: 12),
                                    if ((combo['ahorro'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(combo['ahorro'],
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w700)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
