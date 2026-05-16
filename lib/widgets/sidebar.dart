import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  // FIX: Volvemos a usar int y Function(int) para que no rompa tu dashboard actual
  final int currentIndex;
  final Function(int) onIndexChanged;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB347), Color(0xFFFF4500)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_fire_department, color: Color(0xFFFF4500), size: 40),
            ),
            accountName: const Text('La Brasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: const Text('PARRILLA & GRILL', style: TextStyle(letterSpacing: 1.2)),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Panel de Control', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _buildTile(context, icon: Icons.dashboard, title: 'Dashboard', index: 0),
                _buildTile(context, icon: Icons.shopping_bag, title: 'Productos', index: 1),
                _buildTile(context, icon: Icons.widgets, title: 'Combos', index: 2),
                _buildTile(context, icon: Icons.receipt_long, title: 'Recetas', index: 3),
                _buildTile(context, icon: Icons.people, title: 'Empleados', index: 4),
                _buildTile(context, icon: Icons.inventory, title: 'Inventario', index: 5),
                _buildTile(context, icon: Icons.table_restaurant, title: 'Mesas', index: 6),
                _buildTile(context, icon: Icons.bar_chart, title: 'Reportes', index: 7),
                _buildTile(context, icon: Icons.money_off, title: 'Gastos', index: 8),
                _buildTile(context, icon: Icons.assignment, title: 'Nómina', index: 9),
                _buildTile(context, icon: Icons.history, title: 'Historial', index: 10),
                _buildTile(context, icon: Icons.settings, title: 'Ajustes', index: 11),
                
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Extras', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _buildTile(context, icon: Icons.star, title: 'Tomar Orden', index: 12),
                _buildTile(context, icon: Icons.point_of_sale, title: 'Caja', index: 13),
              ],
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Text('D', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Dueño', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Propietario'),
            trailing: IconButton(
              icon: const Icon(Icons.brightness_6),
              // FIX: IconButton no tiene la propiedad onChanged, se elimina.
              onPressed: () {
                // Lógica de cambio de tema
              },
            ),
          ),
        ],
      ),
    );
  }

  // Se modificó para recibir y comparar un entero (index)
  Widget _buildTile(BuildContext context, {required IconData icon, required String title, required int index}) {
    final isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        onIndexChanged(index);
      },
    );
  }
}