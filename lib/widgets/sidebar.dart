import 'package:flutter/material.dart';
import '../routes.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
                child: Text('Zapata', style: TextStyle(fontSize: 20))),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => _navigateTo(context, Routes.dashboard),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Órdenes'),
              onTap: () => _navigateTo(context, Routes.ordenes),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Productos'),
              onTap: () => _navigateTo(context, Routes.productos),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Inventario'),
              onTap: () => _navigateTo(context, Routes.inventario),
            ),
            ListTile(
              leading: const Icon(Icons.table_bar),
              title: const Text('Mesas'),
              onTap: () => _navigateTo(context, Routes.mesas),
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Reservaciones'),
              onTap: () => _navigateTo(context, Routes.reservaciones),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Caja'),
              onTap: () => _navigateTo(context, Routes.caja),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Proveedores'),
              onTap: () => _navigateTo(context, Routes.proveedores),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Combos'),
              onTap: () => _navigateTo(context, Routes.combos),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Empleados'),
              onTap: () => _navigateTo(context, Routes.empleados),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Tomar Orden'),
              onTap: () => _navigateTo(context, Routes.tomarOrden),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Recetas'),
              onTap: () => _navigateTo(context, Routes.recetas),
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reportes'),
              onTap: () => _navigateTo(context, Routes.reportes),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Gastos'),
              onTap: () => _navigateTo(context, Routes.gastos),
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Nóminas'),
              onTap: () => _navigateTo(context, Routes.nominas),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Cortes'),
              onTap: () => _navigateTo(context, Routes.historialCortes),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () => _navigateTo(context, Routes.ajustes),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cerrar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
