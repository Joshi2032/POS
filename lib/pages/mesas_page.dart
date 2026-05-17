import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/search_bar.dart';

class Mesa {
  final String numero;
  final String area;
  final int capacidad;
  final String estado;

  Mesa({
    required this.numero,
    required this.area,
    required this.capacidad,
    required this.estado,
  });
}

class MesasPage extends StatefulWidget {
  const MesasPage({super.key});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  final List<Mesa> _mesas = [
    Mesa(numero: 'Mesa 1', area: 'Terraza', capacidad: 4, estado: 'Disponible'),
    Mesa(numero: 'Mesa 2', area: 'Terraza', capacidad: 6, estado: 'Ocupada'),
    Mesa(numero: 'Mesa 3', area: 'Salón Principal', capacidad: 2, estado: 'Reservada'),
    Mesa(numero: 'Mesa 4', area: 'VIP', capacidad: 8, estado: 'Disponible'),
  ];

  String _searchTerm = '';
  String _selectedEstado = 'Todos';

  final List<String> _estados = ['Todos', 'Disponible', 'Ocupada', 'Reservada'];
  final List<String> _areas = ['Salón Principal', 'Terraza', 'VIP', 'Bar'];

  List<Mesa> get _mesasFiltrados {
    return _mesas.where((m) {
      final matchesSearch = m.numero.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          m.area.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesEstado = _selectedEstado == 'Todos' || m.estado == _selectedEstado;
      return matchesSearch && matchesEstado;
    }).toList();
  }

  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  String _formArea = 'Salón Principal';
  String _formEstado = 'Disponible';

  void _abrirFormularioModal({Mesa? mesa, int? index}) {
    if (mesa != null) {
      _numeroCtrl.text = mesa.numero;
      _capacidadCtrl.text = mesa.capacidad.toString();
      _formArea = mesa.area;
      _formEstado = mesa.estado;
    } else {
      _numeroCtrl.clear();
      _capacidadCtrl.clear();
      _formArea = 'Salón Principal';
      _formEstado = 'Disponible';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(mesa != null ? 'Editar Configuración' : 'Nueva Mesa', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _numeroCtrl,
                        decoration: const InputDecoration(labelText: 'Identificador (Ej: Mesa 1)', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        value: _formArea,
                        decoration: const InputDecoration(labelText: 'Ubicación / Área', border: OutlineInputBorder()),
                        items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (v) => setModalState(() => _formArea = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _capacidadCtrl,
                        decoration: const InputDecoration(labelText: 'Capacidad de Comensales', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).cardColor,
                        value: _formEstado,
                        decoration: const InputDecoration(labelText: 'Estado Operativo', border: OutlineInputBorder()),
                        items: _estados.where((e) => e != 'Todos').map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setModalState(() => _formEstado = v!),
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
                      final nuevo = Mesa(
                        numero: _numeroCtrl.text,
                        area: _formArea,
                        capacidad: int.tryParse(_capacidadCtrl.text) ?? 4,
                        estado: _formEstado,
                      );
                      setState(() {
                        if (index != null) {
                          _mesas[index] = nuevo;
                        } else {
                          _mesas.add(nuevo);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(mesa != null ? 'Guardar' : 'Crear'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _mesasFiltrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '🍽️ Control de Mesas',
              subtitle: '${_mesas.where((m) => m.estado == 'Ocupada').length} mesas ocupadas actualmente',
              actionLabel: 'Nueva Mesa',
              onAction: () => _abrirFormularioModal(),
            ),
            const SizedBox(height: 24),
            
            // Barra de búsqueda y filtrado tematizado
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomSearchBar(
                    hint: 'Buscar por identificador o área...',
                    onChanged: (v) => setState(() => _searchTerm = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    value: _selectedEstado,
                    items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedEstado = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyState(
                      message: 'No hay mesas en este estado operativo.',
                      icon: Icons.table_bar_outlined,
                      actionLabel: 'Ver Todas',
                      onAction: () => setState(() { _searchTerm = ''; _selectedEstado = 'Todos'; }),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, idx) {
                        final mesa = filtrados[idx];
                        
                        Color estadoColor = Colors.green;
                        if (mesa.estado == 'Ocupada') estadoColor = Colors.redAccent;
                        if (mesa.estado == 'Reservada') estadoColor = Colors.orange;

                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(mesa.numero, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: estadoColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(mesa.estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: estadoColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Área: ${mesa.area}', style: Theme.of(context).textTheme.bodySmall),
                              Text('Capacidad: ${mesa.capacidad} personas', style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.blueGrey),
                                    onPressed: () => _abrirFormularioModal(mesa: mesa, index: _mesas.indexOf(mesa)),
                                  ),
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