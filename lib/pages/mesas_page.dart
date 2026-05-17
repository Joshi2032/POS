import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

// Modelo exacto basado en tu interfaz Mesa de Angular
class Mesa {
  String nombre;
  int capacidad;
  String area;
  String estado; // 'Libre' | 'Ocupada'

  Mesa({
    required this.nombre,
    required this.capacidad,
    required this.area,
    required this.estado,
  });
}

class MesasPage extends StatefulWidget {
  const MesasPage({super.key});

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  // Datos semilla iniciales de tu Angular
  final List<Mesa> _mesas = [
    Mesa(nombre: 'Mesa A1', capacidad: 4, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa A2', capacidad: 4, area: 'Área A', estado: 'Ocupada'),
    Mesa(nombre: 'Mesa A3', capacidad: 6, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa A4', capacidad: 4, area: 'Área A', estado: 'Libre'),
    Mesa(nombre: 'Mesa B1', capacidad: 4, area: 'Área B', estado: 'Libre'),
    Mesa(nombre: 'Mesa B2', capacidad: 6, area: 'Área B', estado: 'Ocupada'),
    Mesa(nombre: 'Mesa B3', capacidad: 4, area: 'Área B', estado: 'Libre'),
  ];

  String _filtroSeleccionado = 'Todas';

  // Valores Computados
  List<String> get _areas => _mesas.map((m) => m.area).toSet().toList();
  List<String> get _filtros => ['Todas', ..._areas];

  List<Mesa> get _mesasFiltradas {
    if (_filtroSeleccionado == 'Todas') return _mesas;
    return _mesas.where((m) => m.area == _filtroSeleccionado).toList();
  }

  int get _libres => _mesasFiltradas.where((m) => m.estado == 'Libre').length;
  int get _ocupadas => _mesasFiltradas.where((m) => m.estado == 'Ocupada').length;
  int get _porCobrar => _ocupadas;

  // Controladores de Formulario
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  void _abrirModalAgregarEditar({Mesa? mesa, int? index}) {
    if (mesa != null) {
      _nombreCtrl.text = mesa.nombre;
      _capacidadCtrl.text = mesa.capacidad.toString();
      _areaCtrl.text = mesa.area;
    } else {
      _nombreCtrl.text = '';
      _capacidadCtrl.text = '1';
      _areaCtrl.text = '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(mesa != null ? 'Editar Mesa' : 'Agregar Mesa', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio.';
                      if (v.length < 2 || v.length > 30) return 'El nombre debe tener entre 2 y 30 caracteres.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Capacidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _capacidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      final num = int.tryParse(v ?? '');
                      if (num == null) return 'La capacidad debe ser un número entero.';
                      if (num < 1 || num > 20) return 'La capacidad debe estar entre 1 y 20.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Área:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El área es obligatoria.';
                      if (v.length < 2 || v.length > 30) return 'El área debe tener entre 2 y 30 caracteres.';
                      return null;
                    },
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
                  setState(() {
                    if (mesa != null && index != null) {
                      _mesas[index].nombre = _nombreCtrl.text.trim();
                      _mesas[index].capacidad = int.parse(_capacidadCtrl.text);
                      _mesas[index].area = _areaCtrl.text.trim();
                    } else {
                      _mesas.add(Mesa(
                        nombre: _nombreCtrl.text.trim(),
                        capacidad: int.parse(_capacidadCtrl.text),
                        area: _areaCtrl.text.trim(),
                        estado: 'Libre', // Por defecto como en Angular
                      ));
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _solicitarBorrado(Mesa mesa) {
    if (mesa.estado == 'Ocupada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar una mesa ocupada. Primero libérala o cierra su cuenta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text('Se eliminará ${mesa.nombre}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _mesas.remove(mesa));
              Navigator.pop(context);
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (replicando app-page-header y botón .mesas-add)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionHeader(
                  title: 'Configuración de Mesas',
                  subtitle: '${_mesas.length} mesas configuradas',
                ),
                ElevatedButton(
                  onPressed: () => _abrirModalAgregarEditar(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('+ Nueva Mesa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
            const SizedBox(height: 32),

            // KPIs (replicando mesas-kpis y kpi-card)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKpiCard('Libres', _libres, const Color(0xFF2FFF7A)),
                const SizedBox(width: 20),
                _buildKpiCard('Ocupadas', _ocupadas, primaryColor),
                const SizedBox(width: 20),
                _buildKpiCard('Por cobrar', _porCobrar, const Color(0xFFFFB347)),
              ],
            ),
            const SizedBox(height: 32),

            // Filtros de Área (replicando mesas-filtros y filtro-btn)
            Wrap(
              spacing: 12,
              children: _filtros.map((f) {
                final isActive = _filtroSeleccionado == f;
                return InkWell(
                  onTap: () => setState(() => _filtroSeleccionado = f),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : Theme.of(context).cardColor,
                      border: Border.all(color: isActive ? primaryColor : Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : primaryTextColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Contenedor principal: Listado de áreas y Grid de mesas
            Expanded(
              child: ListView(
                children: _areas.where((area) => _filtroSeleccionado == 'Todas' || _filtroSeleccionado == area).map((area) {
                  final mesasEnArea = _mesas.where((m) => m.area == area).toList();
                  if (mesasEnArea.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: Text(
                          area,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryTextColor),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: mesasEnArea.length,
                        itemBuilder: (context, index) {
                          final mesa = mesasEnArea[index];
                          final isLibre = mesa.estado == 'Libre';
                          final badgeColor = isLibre ? const Color(0xFF2FFF7A) : primaryColor;

                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Stack(
                              children: [
                                // Badge de Estado
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mesa.estado,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                  ),
                                ),
                                // Botones de Acción Superiores
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.edit_outlined, size: 20, color: primaryColor),
                                        onPressed: () => _abrirModalAgregarEditar(mesa: mesa, index: _mesas.indexOf(mesa)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        onPressed: () => _solicitarBorrado(mesa),
                                      ),
                                    ],
                                  ),
                                ),
                                // Textos Centrales e Inferior
                                Positioned(
                                  top: 36,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mesa.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text('${mesa.capacidad} personas', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      Text(mesa.area, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, height: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            )
          ],
        ),
      ),
    );
  }
}