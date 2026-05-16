import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  // Mantenemos el parámetro 'hint' exacto para no romper empleados ni mesas
  final String hint;
  final Function(String) onChanged;
  final IconData icon;

  const CustomSearchBar({
    super.key,
    this.hint = 'Buscar...',
    required this.onChanged,
    this.icon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      // Hace que el texto que escribe el usuario use el color correcto del tema
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon), 
        // Eliminamos 'fillColor', 'filled' y los 'borders' manuales de aquí.
        // Ahora heredará limpia y automáticamente el diseño oscuro/claro
        // que configuramos en el 'inputDecorationTheme' global de tu AppTheme.
      ),
    );
  }
}