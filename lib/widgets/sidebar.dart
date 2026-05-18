import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CustomSidebar extends StatelessWidget {
  final String currentPath;
  final Function(String) onPathSelected;

  const CustomSidebar({
    super.key,
    required this.currentPath,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sidebarBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDark ? const Color(0xFF9F9F9F) : const Color(0xFF6B6B6B);

    final controlPanelPaths = [
      '/dashboard', '/productos', '/combos', '/recetas', '/empleados', 
      '/inventario', '/mesas', '/reportes', '/gastos', '/nominas', 
      '/historial-cortes', '/ajustes'
    ];
    final isControlPanelActive = controlPanelPaths.contains(currentPath);

    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: activeColor, size: 28),
                const SizedBox(width: 12),
                Text('LA BRASA POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.2)),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildMenuItem(context, title: 'Tomar Orden', path: '/tomar-orden', icon: Icons.restaurant_menu_outlined),
                _buildMenuItem(context, title: 'Caja', path: '/caja', icon: Icons.point_of_sale_outlined),
                _buildMenuItem(context, title: 'Proveedores', path: '/proveedores', icon: Icons.local_shipping_outlined),
                _buildMenuItem(context, title: 'Órdenes', path: '/ordenes', icon: Icons.receipt_long_outlined),
                _buildMenuItem(context, title: 'Reservaciones', path: '/reservaciones', icon: Icons.calendar_today_outlined),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), child: Divider(height: 1)),
                
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: isControlPanelActive,
                    leading: Icon(Icons.settings_input_component_outlined, color: isControlPanelActive ? activeColor : inactiveColor, size: 20),
                    title: Text('Panel de Control', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isControlPanelActive ? activeColor : textColor)),
                    iconColor: activeColor,
                    collapsedIconColor: inactiveColor,
                    childrenPadding: const EdgeInsets.only(left: 12),
                    children: [
                      _buildMenuItem(context, title: 'Dashboard', path: '/dashboard', icon: Icons.dashboard_outlined),
                      _buildMenuItem(context, title: 'Productos', path: '/productos', icon: Icons.fastfood_outlined),
                      _buildMenuItem(context, title: 'Combos', path: '/combos', icon: Icons.auto_awesome_motion_outlined),
                      _buildMenuItem(context, title: 'Recetas', path: '/recetas', icon: Icons.menu_book_outlined),
                      _buildMenuItem(context, title: 'Empleados', path: '/empleados', icon: Icons.people_alt_outlined),
                      _buildMenuItem(context, title: 'Inventario', path: '/inventario', icon: Icons.inventory_2_outlined),
                      _buildMenuItem(context, title: 'Mesas', path: '/mesas', icon: Icons.table_bar_outlined),
                      _buildMenuItem(context, title: 'Reportes', path: '/reportes', icon: Icons.bar_chart_outlined),
                      _buildMenuItem(context, title: 'Gastos', path: '/gastos', icon: Icons.money_off_csred_outlined),
                      _buildMenuItem(context, title: 'Nóminas', path: '/nominas', icon: Icons.payments_outlined),
                      _buildMenuItem(context, title: 'Cortes de Caja', path: '/historial-cortes', icon: Icons.history_toggle_off_outlined),
                      _buildMenuItem(context, title: 'Ajustes', path: '/ajustes', icon: Icons.settings_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: inactiveColor, size: 20),
                    const SizedBox(width: 12),
                    Text(isDark ? 'Modo Oscuro' : 'Modo Claro', style: TextStyle(color: inactiveColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  activeThumbColor: activeColor,
                  onChanged: (bool value) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required String title, required String path, required IconData icon}) {
    final isSelected = currentPath == path;
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
        leading: Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 20),
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? activeColor : textThemeColor)),
        onTap: () => onPathSelected(path),
      ),
    );
  }
}