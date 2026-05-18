import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/proveedores_provider.dart';
import '../providers/inventario_provider.dart';
import '../widgets/app_widgets.dart';

class ProveedoresPage extends StatelessWidget {
  const ProveedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProveedoresProvider(),
      child: const _ProveedoresView(),
    );
  }
}

class _ProveedoresView extends StatefulWidget {
  const _ProveedoresView();

  @override
  State<_ProveedoresView> createState() => _ProveedoresViewState();
}

class _ProveedoresViewState extends State<_ProveedoresView> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  void _openEditor(ProveedoresProvider provider,
      {Map<String, dynamic>? payment}) {
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(payment == null ? 'Nuevo Pago' : 'Editar Pago',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: idController,
                        decoration: const InputDecoration(
                            labelText: 'ID', border: OutlineInputBorder()),
                        readOnly: true),
                    const SizedBox(height: 12),
                    TextField(
                        controller: providerController,
                        decoration: const InputDecoration(
                            labelText: 'Proveedor',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                            labelText: 'Concepto',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).cardColor,
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
                      decoration: const InputDecoration(
                          labelText: 'Método', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                            labelText: 'Monto',
                            prefixText: '\$ ',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                            labelText: 'Fecha', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: timeController,
                        decoration: const InputDecoration(
                            labelText: 'Hora', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: cashierController,
                        decoration: const InputDecoration(
                            labelText: 'Cajero', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
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

                    if ((data['provider'] as String).isNotEmpty &&
                        (data['category'] as String).isNotEmpty &&
                        (data['amount'] as double) > 0) {
                      if (payment == null) {
                        final inventarioGlobal =
                            Provider.of<InventarioProvider>(context,
                                listen: false);
                        provider.addPayment(data, inventarioGlobal);
                      } else {
                        provider.updatePayment(payment['id'], data);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white),
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
    final provider = context.watch<ProveedoresProvider>();
    final paginated = provider.paginatedPayments;

    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '📦 Control de Proveedores',
              subtitle: 'Historial de pagos y liquidación de insumos',
              actionLabel: 'Nuevo Pago',
              onAction: () => _openEditor(provider),
            ),
            const SizedBox(height: 24),
            TextField(
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por proveedor, concepto, método...',
              ),
              onChanged: provider.setSearch,
            ),
            const SizedBox(height: 24),
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
                  value: _money.format(provider.todayTotal),
                  note: '${provider.todayPaymentsCount} operaciones',
                  tone: Colors.deepOrange,
                ),
                _buildStatCard(
                  context,
                  label: 'Total semana',
                  value: _money.format(provider.weekTotal),
                  note: 'Últimos 7 días',
                  tone: Colors.red,
                ),
                _buildStatCard(
                  context,
                  label: 'Total mes',
                  value: _money.format(provider.monthTotal),
                  note: 'Mes en curso',
                  tone: Colors.green,
                ),
                _buildStatCard(
                  context,
                  label: 'Proveedores',
                  value: provider.uniqueProvidersCount.toString(),
                  note: 'Rastreados distintos',
                  tone: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
                '${provider.filteredPayments.length} registro(s) encontrado(s)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: paginated.isEmpty
                  ? Center(
                      child: Text('No hay pagos que coincidan con tu búsqueda.',
                          style: TextStyle(color: mutedTextColor)))
                  : ListView.separated(
                      itemCount: paginated.length,
                      separatorBuilder: (_, __) => Divider(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.3)),
                      itemBuilder: (_, index) {
                        final payment = paginated[index];
                        final providerName = payment['provider'] ?? '';
                        return AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              child: Text(
                                providerName.isNotEmpty
                                    ? providerName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(providerName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor)),
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: primaryTextColor)),
                                const SizedBox(width: 8),
                                IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blueGrey, size: 20),
                                    onPressed: () => _openEditor(provider,
                                        payment: payment)),
                                IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () => provider.removePayment(
                                        payment['id'] as String)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (provider.totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: provider.currentPage > 1
                          ? () => provider.goToPage(provider.currentPage - 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).dividerColor)),
                      child: const Text('Anterior'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                        'Página ${provider.currentPage} de ${provider.totalPages}',
                        style: TextStyle(color: primaryTextColor)),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: provider.currentPage < provider.totalPages
                          ? () => provider.goToPage(provider.currentPage + 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).dividerColor)),
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

  Widget _buildStatCard(BuildContext context,
      {required String label,
      required String value,
      required String note,
      required Color tone}) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: tone, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(note,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
