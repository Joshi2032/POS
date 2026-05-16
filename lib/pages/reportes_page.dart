import 'package:flutter/material.dart';

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen General',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _KpiCard(
                  label: 'Ingresos', value: '\$125,600.00', change: '+18.5%'),
              const SizedBox(height: 12),
              _KpiCard(label: 'Gastos', value: '\$45,200.00', change: '-5.2%'),
              const SizedBox(height: 12),
              _KpiCard(
                  label: 'Utilidad', value: '\$80,400.00', change: '+28.3%'),
              const SizedBox(height: 24),
              Text('Productos Más Vendidos',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ...[
                'Arrachera 300g',
                'Costillas BBQ',
                'Pollo a la Brasa'
              ].asMap().entries.map((e) => ListTile(
                    title: Text(e.value),
                    trailing: Text('${120 - e.key * 10} unidades',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _KpiCard(
      {required this.label, required this.value, required this.change});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(change,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w700)),
            )
          ],
        ),
      ),
    );
  }
}
