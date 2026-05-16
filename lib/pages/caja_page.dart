import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  void openMovimientoDialog({Map<String, dynamic>? movimiento}) {
    final idController = TextEditingController(
        text:
            movimiento?['id'] ?? 'C-${DateTime.now().millisecondsSinceEpoch}');
    final conceptoController =
        TextEditingController(text: movimiento?['concepto'] ?? '');
    final montoController =
        TextEditingController(text: movimiento?['monto']?.toString() ?? '0');
    final fechaController =
        TextEditingController(text: movimiento?['fecha'] ?? '');
    String tipo = movimiento?['tipo'] ?? 'Ingreso';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(movimiento == null
                  ? 'Agregar Movimiento'
                  : 'Editar Movimiento'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID')),
                    TextField(
                        controller: conceptoController,
                        decoration:
                            const InputDecoration(labelText: 'Concepto')),
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Ingreso', child: Text('Ingreso')),
                        DropdownMenuItem(
                            value: 'Egreso', child: Text('Egreso')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => tipo = value ?? 'Ingreso'),
                    ),
                    TextField(
                        controller: montoController,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: fechaController,
                        decoration: const InputDecoration(labelText: 'Fecha')),
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
                      'concepto': conceptoController.text,
                      'tipo': tipo,
                      'monto': double.tryParse(montoController.text) ?? 0.0,
                      'fecha': fechaController.text,
                    };

                    if (movimiento == null) {
                      app.addMovimientoCaja(data);
                    } else {
                      app.updateMovimientoCaja(movimiento['id'], data);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                )
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

    return Scaffold(
      appBar: AppBar(title: const Text('Caja')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    label: 'Ingresos',
                    value: '\$${app.ingresosCaja.toStringAsFixed(2)}',
                    color: Colors.green),
                _StatCard(
                    label: 'Egresos',
                    value: '\$${app.egresosCaja.toStringAsFixed(2)}',
                    color: Colors.red),
                _StatCard(
                    label: 'Saldo',
                    value: '\$${app.saldoCaja.toStringAsFixed(2)}',
                    color: Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: app.movimientosCaja.isEmpty
                  ? const Center(child: Text('No hay movimientos'))
                  : ListView.separated(
                      itemCount: app.movimientosCaja.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final item = app.movimientosCaja[index];
                        final isIncome = item['tipo'] == 'Ingreso';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isIncome ? Colors.green : Colors.red,
                            child: Icon(
                                isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white),
                          ),
                          title: Text(item['concepto'] ?? ''),
                          subtitle: Text('${item['tipo']} · ${item['fecha']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  '\$${(item['monto'] as double).toStringAsFixed(2)}'),
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      openMovimientoDialog(movimiento: item)),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => app.removeMovimientoCaja(
                                      item['id'] as String)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openMovimientoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .18))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
