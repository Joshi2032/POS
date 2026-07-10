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
            if (provider.hasError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No se pudo cargar el historial de cortes: '
                        '${provider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Filtrar por fecha (YYYY-MM-DD)'),
              onChanged: provider.setFilterDate,
            ),
            const SizedBox(height: 16),
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
                    label: 'Transferencias',
                    value: money.format(provider.totalTransferencia),
                    color: Colors.orange),
                _StatCard(
                    label: 'Total Ventas',
                    value: money.format(provider.totalFiltrado),
                    color: Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            Text('${cortes.length} corte(s) de turno',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: cortes.isEmpty
                  ? const Center(
                      child: Text('No hay cortes que coincidan con los filtros.'))
                  : ListView.separated(
                      itemCount: cortes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final corte = cortes[index];
                        
                        // Calculamos el total de ventas sumando los campos exactos
                        final totalVentas = corte.cashSales + corte.cardSales + corte.transferSales;
                        
                        // Formateo de fecha y hora
                        final dateStr = corte.cutAt?.split('T').first ?? 'Sin fecha';
                        final timeStr = (corte.cutAt != null && corte.cutAt!.contains('T')) 
                            ? corte.cutAt!.split('T').last.substring(0, 5) 
                            : '';
                            
                        // Recorte visual del UUID para el avatar
                        final shortId = corte.id.length >= 4 ? corte.id.substring(0, 4) : 'CX';

                        return ListTile(
                          leading: CircleAvatar(child: Text(shortId.toUpperCase())),
                          title: Text('Turno ${corte.status == 'closed' ? 'Cerrado' : 'Abierto'}'),
                          subtitle: Text('$dateStr $timeStr\nDiferencia en caja: ${money.format(corte.difference)}'),
                          trailing: Text(money.format(totalVentas),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  const _StatCard({required this.label, required this.value, required this.color});

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
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}