import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CustomSidebar extends StatelessWidget {
  final String currentSection;
  final Function(String) onSectionSelected;

  const CustomSidebar({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores dinámicos basados en el tema activo
    final sidebarBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDark ? const Color(0xFF9F9F9F) : const Color(0xFF6B6B6B);

    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Branding / Logo del POS La Brasa
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: activeColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'LA BRASA POS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Listado de Módulos Operativos scrolleable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildMenuItem(context, title: 'Dashboard', icon: Icons.dashboard_outlined),
                _buildMenuItem(context, title: 'Tomar Orden', icon: Icons.restaurant_menu_outlined),
                _buildMenuItem(context, title: 'Órdenes', icon: Icons.receipt_long_outlined),
                _buildMenuItem(context, title: 'Productos', icon: Icons.fastfood_outlined),
                _buildMenuItem(context, title: 'Combos', icon: Icons.auto_awesome_motion_outlined),
                _buildMenuItem(context, title: 'Mesas', icon: Icons.table_bar_outlined),
                _buildMenuItem(context, title: 'Reservaciones', icon: Icons.calendar_today_outlined),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Divider(height: 1),
                ),
                _buildMenuItem(context, title: 'Empleados', icon: Icons.people_alt_outlined),
                _buildMenuItem(context, title: 'Nóminas', icon: Icons.payments_outlined),
                _buildMenuItem(context, title: 'Caja', icon: Icons.point_of_sale_outlined),
                _buildMenuItem(context, title: 'Gastos', icon: Icons.money_off_csred_outlined),
                _buildMenuItem(context, title: 'Inventario', icon: Icons.inventory_2_outlined),
                _buildMenuItem(context, title: 'Recetas', icon: Icons.menu_book_outlined),
                _buildMenuItem(context, title: 'Proveedores', icon: Icons.local_shipping_outlined),
                _buildMenuItem(context, title: 'Cortes de Caja', icon: Icons.history_toggle_off_outlined),
                _buildMenuItem(context, title: 'Ajustes', icon: Icons.settings_outlined),
              ],
            ),
          ),
          
          // Interruptor inferior para cambiar de tema (Claro / Oscuro)
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: inactiveColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDark ? 'Modo Oscuro' : 'Modo Claro',
                      style: TextStyle(color: inactiveColor, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Switch(
                  value: appState.darkMode,
                  activeThumbColor: activeColor,
                  onChanged: (bool value) {
                    appState.toggleDarkMode();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required String title, required IconData icon}) {
    final isSelected = currentSection == title;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDark ? const Color(0xFF9F9F9F) : const Color(0xFF6B6B6B);
    final textThemeColor = isDark ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: activeColor.withValues(alpha: 0.12),
        leading: Icon(
          icon,
          color: isSelected ? activeColor : inactiveColor,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : textThemeColor,
          ),
        ),
        onTap: () {
          onSectionSelected(title);
        },
      ),
    );
  }
}