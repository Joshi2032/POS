import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Deja que el MainLayout ponga el fondo
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Dashboard',
              subtitle: 'Resumen general de hoy',
            ),
            const SizedBox(height: 24),
            
            // Usamos tus propios StatCards
            Row(
              children: [
                const Expanded(
                  child: StatCard(
                    label: 'Ventas del Día',
                    value: '\$4,520.00',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: StatCard(
                    label: 'Órdenes Activas',
                    value: '12',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Mesas Ocupadas',
                    value: '5 / 15',
                    icon: Icons.table_restaurant,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Aquí irían tus gráficas...',
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}