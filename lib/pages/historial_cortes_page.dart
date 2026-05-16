import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class HistorialCortesPage extends StatefulWidget {
  const HistorialCortesPage({super.key});

  @override
  State<HistorialCortesPage> createState() => _HistorialCortesPageState();
}

class _HistorialCortesPageState extends State<HistorialCortesPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  String filterDate = '';
  String filterMethod = 'Todos';
  final metodos = ['Todos', 'Efectivo', 'Tarjeta', 'Mixto'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cortes = app.cortes.where((c) {
      final matchDate = filterDate.isEmpty || c['fecha'] == filterDate;
      final matchMethod =
          filterMethod == 'Todos' || c['metodo'] == filterMethod;
      return matchDate && matchMethod;
    }).toList();

    final totalEfectivo = cortes
        .where((c) => c['metodo'] == 'Efectivo')
        .fold(0.0, (sum, c) => sum + (c['monto'] as double));
    final totalTarjeta = cortes
        .where((c) => c['metodo'] == 'Tarjeta')
        .fold(0.0, (sum, c) => sum + (c['monto'] as double));
    final totalMixto = cortes
        .where((c) => c['metodo'] == 'Mixto')
        .fold(0.0, (sum, c) => sum + (c['monto'] as double));
    final totalFiltrado =
        cortes.fold(0.0, (sum, c) => sum + (c['monto'] as double));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Cortes')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Filtrar por fecha'),
              onChanged: (value) => setState(() => filterDate = value),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: metodos
                    .map((m) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(m),
                            selected: filterMethod == m,
                            onSelected: (selected) =>
                                setState(() => filterMethod = m),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    label: 'Efectivo',
                    value: _money.format(totalEfectivo),
                    color: Colors.green),
                _StatCard(
                    label: 'Tarjeta',
                    value: _money.format(totalTarjeta),
                    color: Colors.blue),
                _StatCard(
                    label: 'Mixto',
                    value: _money.format(totalMixto),
                    color: Colors.orange),
                _StatCard(
                    label: 'Total Filtrado',
                    value: _money.format(totalFiltrado),
                    color: Colors.purple),
              ],
            ),
            const SizedBox(height: 12),
            Text('${cortes.length} corte(s)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: cortes.isEmpty
                  ? const Center(
                      child:
                          Text('No hay cortes que coincidan con los filtros.'))
                  : ListView.separated(
                      itemCount: cortes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final corte = cortes[index];
                        return ListTile(
                          leading: CircleAvatar(
                              child: Text(
                                  (corte['id'] as String).split('-').last)),
                          title:
                              Text('${corte['cajero']} · ${corte['metodo']}'),
                          subtitle: Text('${corte['fecha']} ${corte['hora']}'),
                          trailing: Text(_money.format(corte['monto']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        );
                      },
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
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
