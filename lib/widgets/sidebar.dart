import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Definición exacta de los módulos sincronizados con Angular
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Tomar Orden', 'icon': Icons.restaurant_menu},
      {'title': 'Control de Caja', 'icon': Icons.point_of_sale},
      {'title': 'Gestión de Mesas', 'icon': Icons.table_restaurant},
      {'title': 'Productos', 'icon': Icons.fastfood},
      {'title': 'Inventario', 'icon': Icons.inventory},
      {'title': 'Empleados', 'icon': Icons.people},
      {'title': 'Gastos', 'icon': Icons.money_off},
      {'title': 'Reportes y Métricas', 'icon': Icons.bar_chart},
    ];

    final activeColor = Theme.of(context).primaryColor;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header / Logo del restaurante (Estilo Angular layout)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront, color: activeColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZAPATA', 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                    ),
                    Text(
                      'Punto de Venta', 
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          
          // Lista de Módulos / Opciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: ListTile(
                    horizontalTitleGap: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    selected: isSelected,
                    selectedTileColor: activeColor.withValues(alpha: 0.08),
                    leading: Icon(
                      item['icon'], 
                      color: isSelected ? activeColor : Colors.grey[600],
                      size: 21,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? activeColor : Colors.black87,
                      ),
                    ),
                    onTap: () => onIndexChanged(index),
                  ),
                );
              },
            ),
          ),
          
          // Footer de la barra lateral (Información del usuario firmado)
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE5E7EB),
                  radius: 18,
                  child: Icon(Icons.person, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Administrador', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Sucursal Principal', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                  onPressed: () {
                    // Cierre de sesión
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}