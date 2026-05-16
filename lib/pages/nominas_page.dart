import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class NominasPage extends StatefulWidget {
  const NominasPage({super.key});

  @override
  State<NominasPage> createState() => _NominasPageState();
}

class _NominasPageState extends State<NominasPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  String search = '';
  String selectedType = 'Todos';
  int currentPage = 1;
  final pageSize = 10;
  final tipos = ['Todos', 'Salario', 'Adelanto', 'Bono', 'Deducción'];

  void _openEditor({Map<String, dynamic>? nomina}) {
    final idController = TextEditingController(
        text: nomina?['id'] ?? 'NOM-${DateTime.now().millisecondsSinceEpoch}');
    final fechaController = TextEditingController(
        text: nomina?['fecha'] ??
            DateTime.now().toIso8601String().split('T').first);
    final empleadoController =
        TextEditingController(text: nomina?['empleado'] ?? '');
    final montoController =
        TextEditingController(text: nomina?['monto']?.toString() ?? '0');
    final notasController = TextEditingController(text: nomina?['notas'] ?? '');
    String tipo = nomina?['tipo'] ?? 'Salario';
    String periodo = nomina?['periodo'] ?? 'Quincenal';
    String metodo = nomina?['metodo'] ?? 'Transferencia';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(nomina == null ? 'Agregar Pago' : 'Editar Pago'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'ID'),
                    readOnly: true),
                TextField(
                    controller: fechaController,
                    decoration: const InputDecoration(labelText: 'Fecha')),
                TextField(
                    controller: empleadoController,
                    decoration: const InputDecoration(labelText: 'Empleado')),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  items: ['Salario', 'Adelanto', 'Bono', 'Deducción']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => tipo = value ?? 'Salario'),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: periodo,
                  items: ['Semanal', 'Quincenal', 'Mensual']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => periodo = value ?? 'Quincenal'),
                  decoration: const InputDecoration(labelText: 'Período'),
                ),
                TextField(
                    controller: montoController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  initialValue: metodo,
                  items: ['Transferencia', 'Efectivo', 'Depósito']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => metodo = value ?? 'Transferencia'),
                  decoration: const InputDecoration(labelText: 'Método'),
                ),
                TextField(
                    controller: notasController,
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
                  'fecha': fechaController.text,
                  'empleado': empleadoController.text.trim(),
                  'tipo': tipo,
                  'periodo': periodo,
                  'monto': double.tryParse(montoController.text) ?? 0.0,
                  'metodo': metodo,
                  'notas': notasController.text,
                };
                if (nomina == null) {
                  app.addNomina(data);
                } else {
                  app.updateNomina(nomina['id'], data);
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
    final nominas = app.nominas.where((n) {
      final matchSearch = search.isEmpty ||
          [n['empleado'], n['tipo'], n['metodo']]
              .whereType<String>()
              .any((v) => v.toLowerCase().contains(search.toLowerCase()));
      final matchType = selectedType == 'Todos' || n['tipo'] == selectedType;
      return matchSearch && matchType;
    }).toList();

    final totalPages = (nominas.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = nominas.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nóminas')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Buscar pago...'),
              onChanged: (value) => setState(() {
                search = value;
                currentPage = 1;
              }),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tipos
                    .map((t) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(t),
                            selected: selectedType == t,
                            onSelected: (selected) => setState(() {
                              selectedType = t;
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
                child: Column(
                  children: [
                    Text('Total pagado este mes',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(_money.format(app.totalNominasEstesMes),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: paginated.isEmpty
                  ? const Center(child: Text('No hay nóminas que coincidan.'))
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final nomina = paginated[index];
                        return ListTile(
                          title: Text(nomina['empleado'] ?? ''),
                          subtitle: Text(
                              '${nomina['tipo']} · ${nomina['periodo']} · ${nomina['fecha']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_money.format(nomina['monto'] ?? 0.0),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEditor(nomina: nomina)),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      app.removeNomina(nomina['id'])),
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
