import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/search_bar.dart';

// Modelo de datos para las Recetas
class Receta {
  final String id;
  final String nombre;
  final String categoria;
  final String tiempoPrep;
  final double costoProduccion;
  final int cantidadIngredientes;

  Receta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.tiempoPrep,
    required this.costoProduccion,
    required this.cantidadIngredientes,
  });
}

class RecetasPage extends StatefulWidget {
  const RecetasPage({super.key});

  @override
  State<RecetasPage> createState() => _RecetasPageState();
}

class _RecetasPageState extends State<RecetasPage> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  // Datos semilla simulando tu base de Angular para "La Brasa"
  final List<Receta> _recetas = [
    Receta(id: 'REC-001', nombre: 'Arrachera 300g', categoria: 'Parrilla', tiempoPrep: '15 min', costoProduccion: 110.50, cantidadIngredientes: 6),
    Receta(id: 'REC-002', nombre: 'T-Bone 500g', categoria: 'Parrilla', tiempoPrep: '20 min', costoProduccion: 185.00, cantidadIngredientes: 5),
    Receta(id: 'REC-003', nombre: 'Costillas BBQ', categoria: 'Parrilla', tiempoPrep: '35 min', costoProduccion: 130.00, cantidadIngredientes: 8),
    Receta(id: 'REC-004', nombre: 'Ensalada César', categoria: 'Ensaladas', tiempoPrep: '10 min', costoProduccion: 35.20, cantidadIngredientes: 7),
    Receta(id: 'REC-005', nombre: 'Guacamole Brasa', categoria: 'Entradas', tiempoPrep: '5 min', costoProduccion: 25.00, cantidadIngredientes: 4),
  ];

  String _searchTerm = '';
  String _selectedCategory = 'Todas';

  final List<String> _categorias = ['Todas', 'Parrilla', 'Entradas', 'Guarniciones', 'Ensaladas', 'Bebidas', 'Postres'];

  List<Receta> get _recetasFiltradas {
    return _recetas.where((r) {
      final matchesSearch = r.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) || 
                            r.id.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todas' || r.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Controladores del Formulario
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _ingredientesCtrl = TextEditingController();
  String _formCategoria = 'Parrilla';

  void _abrirFormularioModal({Receta? receta, int? index}) {
    if (receta != null) {
      _nombreCtrl.text = receta.nombre;
      _tiempoCtrl.text = receta.tiempoPrep;
      _costoCtrl.text = receta.costoProduccion.toString();
      _ingredientesCtrl.text = receta.cantidadIngredientes.toString();
      _formCategoria = receta.categoria;
    } else {
      _nombreCtrl.clear();
      _tiempoCtrl.clear();
      _costoCtrl.clear();
      _ingredientesCtrl.text = '1';
      _formCategoria = 'Parrilla';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(receta != null ? 'Editar Ficha Técnica' : 'Nueva Receta', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre del Platillo', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        initialValue: _formCategoria, // Adaptado a Flutter 3.33+
                        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                        items: _categorias.where((c) => c != 'Todas').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setModalState(() => _formCategoria = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tiempoCtrl,
                              decoration: const InputDecoration(labelText: 'Tiempo Prep.', hintText: 'Ej: 15 min', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ingredientesCtrl,
                              decoration: const InputDecoration(labelText: 'Ingredientes', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _costoCtrl,
                        decoration: const InputDecoration(labelText: 'Costo de Producción', prefixText: '\$ ', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final nueva = Receta(
                        id: receta?.id ?? 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        nombre: _nombreCtrl.text,
                        categoria: _formCategoria,
                        tiempoPrep: _tiempoCtrl.text,
                        costoProduccion: double.tryParse(_costoCtrl.text) ?? 0.0,
                        cantidadIngredientes: int.tryParse(_ingredientesCtrl.text) ?? 1,
                      );
                      setState(() {
                        if (index != null) {
                          _recetas[index] = nueva;
                        } else {
                          _recetas.add(nueva);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(receta != null ? 'Guardar Cambios' : 'Crear Receta'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _solicitarBorrado(Receta receta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Receta'),
        content: Text('Se eliminará la ficha técnica de "${receta.nombre}". Esta acción no afecta al producto final en el menú, solo a su costo de producción. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _recetas.remove(receta));
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _recetasFiltradas;
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent, // Hereda fondo del Layout Principal
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '📖 Recetas y Escandallos',
              subtitle: '${_recetas.length} fichas técnicas registradas para control de mermas',
              actionLabel: 'Nueva Receta',
              onAction: () => _abrirFormularioModal(),
            ),
            const SizedBox(height: 24),
            
            // Barra de Búsqueda y Filtros
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomSearchBar(
                    hint: 'Buscar receta por nombre o clave (Ej. REC-001)...',
                    onChanged: (v) => setState(() => _searchTerm = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(color: primaryTextColor, fontSize: 14),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    initialValue: _selectedCategory,
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: filtradas.isEmpty
                  ? EmptyState(
                      message: 'No hay recetas que coincidan con los filtros.',
                      icon: Icons.menu_book_outlined,
                      actionLabel: 'Restablecer',
                      onAction: () => setState(() {
                        _searchTerm = '';
                        _selectedCategory = 'Todas';
                      }),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340,
                        childAspectRatio: 1.35,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtradas.length,
                      itemBuilder: (context, idx) {
                        final receta = filtradas[idx];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      receta.categoria.toUpperCase(), 
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                                    ),
                                  ),
                                  Text(
                                    receta.id,
                                    style: TextStyle(fontSize: 11, color: mutedTextColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(receta.nombre, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              
                              // Indicadores de Tiempo y Elementos
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 16, color: mutedTextColor),
                                  const SizedBox(width: 4),
                                  Text(receta.tiempoPrep, style: TextStyle(color: mutedTextColor, fontSize: 12)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.kitchen_outlined, size: 16, color: mutedTextColor),
                                  const SizedBox(width: 4),
                                  Text('${receta.cantidadIngredientes} Ingredientes', style: TextStyle(color: mutedTextColor, fontSize: 12)),
                                ],
                              ),
                              
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Costo Producción', style: TextStyle(fontSize: 10, color: mutedTextColor)),
                                      Text(
                                        _money.format(receta.costoProduccion), 
                                        style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w800)
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                        tooltip: 'Editar Ficha',
                                        onPressed: () => _abrirFormularioModal(receta: receta, index: _recetas.indexOf(receta)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _solicitarBorrado(receta),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
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