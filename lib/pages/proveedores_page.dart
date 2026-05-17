import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart'; // Para consumir AppCard y SectionHeader

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(payment == null ? 'Nuevo Pago' : 'Editar Pago',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID', border: OutlineInputBorder()),
                        readOnly: true),
                    const SizedBox(height: 12),
                    TextField(
                        controller: providerController,
                        decoration: const InputDecoration(labelText: 'Proveedor', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor, // Mantiene el menú contextual oscuro
                      initialValue: method, // Adaptado a los estándares de Flutter 3.33+
                      items: const [
                        DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                      ],
                      onChanged: (value) => setDialogState(() => method = value ?? 'Transferencia'),
                      decoration: const InputDecoration(labelText: 'Método', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ ', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: cashierController,
                        decoration: const InputDecoration(labelText: 'Cajero', border: OutlineInputBorder())),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
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

    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent, // Hereda el lienzo limpio de fondo de tu MainLayout
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado Oficial tipo Dashboard/Web
            SectionHeader(
              title: '📦 Control de Proveedores',
              subtitle: 'Historial de pagos y liquidación de insumos',
              actionLabel: 'Nuevo Pago',
              onAction: () => _openEditor(),
            ),
            const SizedBox(height: 24),

            // 2. Buscador adaptativo global
            TextField(
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por proveedor, concepto, método...',
              ),
              onChanged: _setSearch,
            ),
            const SizedBox(height: 24),

            // 3. Grid de Tarjetas de Estadísticas unificadas con tu AppCard
            GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context,
                  label: 'Pagos hoy',
                  value: _money.format(app.providerPaymentsTodayTotal),
                  note: '${app.providerPayments.where((p) => p['date'] == DateTime.now().toIso8601String().split('T').first).length} operaciones',
                  tone: Colors.deepOrange,
                ),
                _buildStatCard(
                  context,
                  label: 'Total semana',
                  value: _money.format(app.providerPaymentsWeekTotal),
                  note: 'Últimos 7 días',
                  tone: Colors.red,
                ),
                _buildStatCard(
                  context,
                  label: 'Total mes',
                  value: _money.format(app.providerPaymentsMonthTotal),
                  note: 'Mes en curso',
                  tone: Colors.green,
                ),
                _buildStatCard(
                  context,
                  label: 'Proveedores',
                  value: app.providerPayments
                      .map((e) => e['provider'])
                      .whereType<String>()
                      .toSet()
                      .length
                      .toString(),
                  note: 'Rastreados distintos',
                  tone: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('${payments.length} registro(s) encontrado(s)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // 4. Lista de Historial integrada con el AppCard adaptativo
            Expanded(
              child: paginated.isEmpty
                  ? Center(
                      child: Text(
                        'No hay pagos que coincidan con tu búsqueda.',
                        style: TextStyle(color: mutedTextColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      itemBuilder: (_, index) {
                        final payment = paginated[index];
                        final providerName = payment['provider'] ?? '';
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                providerName.isNotEmpty ? providerName[0].toUpperCase() : '?',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(providerName,
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                  '${payment['category']} · ${payment['method']} · ${payment['date']} ${payment['time']}\nCajero: ${payment['cashier']}',
                                  style: TextStyle(color: mutedTextColor)),
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_money.format(payment['amount'] ?? 0.0),
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
                                const SizedBox(width: 8),
                                IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                                    onPressed: () => _openEditor(payment: payment)),
                                IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => app.removeProviderPayment(payment['id'] as String)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 5. Paginador inferior perimetral
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1, totalPages) : null,
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).dividerColor)),
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text('Página $currentPage de $totalPages', style: TextStyle(color: primaryTextColor)),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1, totalPages) : null,
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).dividerColor)),
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

  // Tarjeta de estadística adaptada al contexto oscuro/claro
  Widget _buildStatCard(BuildContext context, {required String label, required String value, required String note, required Color tone}) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: tone, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(note, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11)),
        ],
      ),
    );
  }
}