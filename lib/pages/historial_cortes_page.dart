import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/historial_cortes_provider.dart';

class HistorialCortesPage extends StatelessWidget {
  const HistorialCortesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HistorialCortesView();
  }
}

class _HistorialCortesView extends StatelessWidget {
  const _HistorialCortesView();

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final provider = context.watch<HistorialCortesProvider>();
    final cortes = provider.cortesFiltrados;

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
              onChanged: provider.setFilterDate,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.metodos
                    .map((m) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(m),
                            selected: provider.filterMethod == m,
                            onSelected: (_) => provider.setFilterMethod(m),
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
                    value: money.format(provider.totalEfectivo),
                    color: Colors.green),
                _StatCard(
                    label: 'Tarjeta',
                    value: money.format(provider.totalTarjeta),
                    color: Colors.blue),
                _StatCard(
                    label: 'Mixto',
                    value: money.format(provider.totalMixto),
                    color: Colors.orange),
                _StatCard(
                    label: 'Total Filtrado',
                    value: money.format(provider.totalFiltrado),
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
                                  (corte.id as String).split('-').last)),
                          title:
                              Text('${corte.cajero} · ${corte.metodo}'),
                          subtitle: Text('${corte.fecha} ${corte.hora}'),
                          trailing: Text(money.format(corte.monto ),
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
