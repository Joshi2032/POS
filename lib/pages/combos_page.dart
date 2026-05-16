import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class Combo {
  final String nombre;
  final String descripcion;
  final double precio;
  final bool activo;

  Combo({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.activo = true,
  });
}

class CombosPage extends StatefulWidget {
  const CombosPage({super.key});

  @override
  State<CombosPage> createState() => _CombosPageState();
}

class _CombosPageState extends State<CombosPage> {
  final List<Combo> _combos = [
    Combo(nombre: 'Combo Familiar Parrillero', descripcion: '1 T-Bone 500g, 1 Arrachera 300g, 2 Guarniciones y 1 Jarra de agua.', precio: 850.00),
    Combo(nombre: 'Combo Pareja', descripcion: '1 Costilla BBQ, 1 Pechuga Asada, 2 Bebidas y 1 Postre a elegir.', precio: 450.00),
    Combo(nombre: 'Combo Ejecutivo', descripcion: 'Arrachera 200g, ensalada de la casa y bebida.', precio: 220.00),
    Combo(nombre: 'Paquete Botanero', descripcion: 'Alitas, Papas al carbón, Queso fundido y 2 Cervezas.', precio: 380.00, activo: false),
  ];

  String _searchTerm = '';

  List<Combo> get _combosFiltrados {
    return _combos.where((c) {
      final matchNombre = c.nombre.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchDesc = c.descripcion.toLowerCase().contains(_searchTerm.toLowerCase());
      return matchNombre || matchDesc;
    }).toList();
  }

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  bool _formActivo = true;

  void _abrirFormularioModal({Combo? combo, int? index}) {
    if (combo != null) {
      _nombreCtrl.text = combo.nombre;
      _descripcionCtrl.text = combo.descripcion;
      _precioCtrl.text = combo.precio.toString();
      _formActivo = combo.activo;
    } else {
      _nombreCtrl.clear();
      _descripcionCtrl.clear();
      _precioCtrl.clear();
      _formActivo = true;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(combo != null ? 'Editar Combo' : 'Nuevo Combo', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre del Combo', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Descripción / Productos incluidos', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _precioCtrl,
                              decoration: const InputDecoration(labelText: 'Precio Especial', prefixText: '\$', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              const Text('¿Disponible?', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Switch(
                                value: _formActivo,
                                activeThumbColor: Colors.green, // <-- Corrección de advertencia
                                onChanged: (v) => setModalState(() => _formActivo = v),
                              ),
                            ],
                          )
                        ],
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
                      final nuevo = Combo(
                        nombre: _nombreCtrl.text,
                        descripcion: _descripcionCtrl.text,
                        precio: double.tryParse(_precioCtrl.text) ?? 0,
                        activo: _formActivo,
                      );
                      setState(() {
                        if (index != null) {
                          _combos[index] = nuevo;
                        } else {
                          _combos.add(nuevo);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(combo != null ? 'Guardar Cambios' : 'Crear Combo'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _solicitarBorrado(Combo combo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar combo'),
        content: Text('Se eliminará "${combo.nombre}". ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _combos.remove(combo));
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
    final filtrados = _combosFiltrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '🍱 Combos y Paquetes',
              subtitle: '${filtrados.length} combos registrados',
              actionLabel: 'Crear Combo',
              onAction: () => _abrirFormularioModal(),
            ),
            const SizedBox(height: 24),
            
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Buscar combo por nombre o contenido...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchTerm = v),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message: 'No hay combos que coincidan con tu búsqueda.',
                      icon: Icons.local_mall_outlined,
                      actionLabel: 'Limpiar Búsqueda',
                      onAction: () => setState(() => _searchTerm = ''),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, idx) {
                        final combo = filtrados[idx];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      combo.nombre, 
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      // <-- Corrección de advertencias (withValues en lugar de withOpacity)
                                      color: combo.activo ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      combo.activo ? 'Activo' : 'Inactivo', 
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: combo.activo ? Colors.green : Colors.red
                                      )
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  combo.descripcion, 
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${combo.precio.toStringAsFixed(2)}', 
                                    style: const TextStyle(fontSize: 20, color: Colors.blueAccent, fontWeight: FontWeight.w900)
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                                        onPressed: () => _abrirFormularioModal(combo: combo, index: _combos.indexOf(combo)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        onPressed: () => _solicitarBorrado(combo),
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