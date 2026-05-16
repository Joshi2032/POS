import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final int pageSize = 10;
  String searchTerm = '';
  int currentPage = 1;

  void _setSearch(String value) {
    setState(() {
      searchTerm = value;
      currentPage = 1;
    });
  }

  void _goToPage(int page, int totalPages) {
    setState(() {
      currentPage = page.clamp(1, totalPages);
    });
  }

  void _openEditor({Map<String, dynamic>? payment}) {
    final todayIso = DateTime.now().toIso8601String().split('T').first;
    final idController = TextEditingController(
      text: payment?['id'] ?? 'PAG-${DateTime.now().millisecondsSinceEpoch}',
    );
    final providerController =
        TextEditingController(text: payment?['provider'] ?? '');
    final categoryController =
        TextEditingController(text: payment?['category'] ?? '');
    final amountController =
        TextEditingController(text: payment?['amount']?.toString() ?? '0');
    final dateController =
        TextEditingController(text: payment?['date'] ?? todayIso);
    final timeController =
        TextEditingController(text: payment?['time'] ?? '09:00 a.m.');
    final cashierController =
        TextEditingController(text: payment?['cashier'] ?? 'Laura S.');
    String method = payment?['method'] ?? 'Transferencia';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(payment == null ? 'Nuevo Pago' : 'Editar Pago'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID')),
                    TextField(
                        controller: providerController,
                        decoration:
                            const InputDecoration(labelText: 'Proveedor')),
                    TextField(
                        controller: categoryController,
                        decoration:
                            const InputDecoration(labelText: 'Concepto')),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      items: const [
                        DropdownMenuItem(
                            value: 'Transferencia',
                            child: Text('Transferencia')),
                        DropdownMenuItem(
                            value: 'Efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(
                            value: 'Tarjeta', child: Text('Tarjeta')),
                      ],
                      onChanged: (value) => setDialogState(
                          () => method = value ?? 'Transferencia'),
                      decoration: const InputDecoration(labelText: 'Método'),
                    ),
                    TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Fecha')),
                    TextField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: 'Hora')),
                    TextField(
                        controller: cashierController,
                        decoration: const InputDecoration(labelText: 'Cajero')),
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
                      'provider': providerController.text.trim(),
                      'category': categoryController.text.trim(),
                      'method': method,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'date': dateController.text,
                      'time': timeController.text,
                      'cashier': cashierController.text,
                    };

                    if (data['provider'] is String &&
                        (data['provider'] as String).isNotEmpty &&
                        data['category'] is String &&
                        (data['category'] as String).isNotEmpty &&
                        (data['amount'] as double) > 0) {
                      if (payment == null) {
                        app.addProviderPayment(data);
                      } else {
                        app.updateProviderPayment(payment['id'], data);
                      }
                      Navigator.pop(context);
                    }
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
    final payments = app.providerPayments.where((payment) {
      if (searchTerm.isEmpty) return true;
      final q = searchTerm.toLowerCase();
      return [
        payment['provider'],
        payment['category'],
        payment['method'],
        payment['cashier']
      ].whereType<String>().any((v) => v.toLowerCase().contains(q));
    }).toList();

    final totalPages = (payments.length / pageSize).ceil().clamp(1, 999999);
    final start = (currentPage - 1) * pageSize;
    final paginated = payments.skip(start).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar proveedor...'),
                    onChanged: _setSearch,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Pago'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    label: 'Pagos hoy',
                    value: _money.format(app.providerPaymentsTodayTotal),
                    note:
                        '${app.providerPayments.where((p) => p['date'] == DateTime.now().toIso8601String().split('T').first).length} pagos',
                    tone: Colors.deepOrange),
                _StatCard(
                    label: 'Total semana',
                    value: _money.format(app.providerPaymentsWeekTotal),
                    note: 'última semana',
                    tone: Colors.red),
                _StatCard(
                    label: 'Total mes',
                    value: _money.format(app.providerPaymentsMonthTotal),
                    note: 'mes actual',
                    tone: Colors.green),
                _StatCard(
                    label: 'Proveedores',
                    value: app.providerPayments
                        .map((e) => e['provider'])
                        .whereType<String>()
                        .toSet()
                        .length
                        .toString(),
                    note: 'distintos',
                    tone: Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Text('${payments.length} registro(s)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: paginated.isEmpty
                  ? const Center(
                      child:
                          Text('No hay pagos que coincidan con tu búsqueda.'))
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final payment = paginated[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                  (payment['provider'] as String).isNotEmpty
                                      ? (payment['provider'] as String)[0]
                                          .toUpperCase()
                                      : '?'),
                            ),
                            title: Text(payment['provider'] ?? ''),
                            subtitle: Text(
                                '${payment['category']} · ${payment['method']} · ${payment['date']} ${payment['time']}\nCajero: ${payment['cashier']}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_money.format(payment['amount'] ?? 0.0),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _openEditor(payment: payment)),
                                IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => app.removeProviderPayment(
                                        payment['id'] as String)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: currentPage > 1
                          ? () => _goToPage(currentPage - 1, totalPages)
                          : null,
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 12),
                    Text('Página $currentPage de $totalPages'),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: currentPage < totalPages
                          ? () => _goToPage(currentPage + 1, totalPages)
                          : null,
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final Color tone;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.note,
      required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: tone, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
