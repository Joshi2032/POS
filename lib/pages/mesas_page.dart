// lib/pages/mesas_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesas_provider.dart';
import '../widgets/app_widgets.dart';
import '../models/mesa.dart'; 

class MesasPage extends StatelessWidget {
  const MesasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MesasView();
  }
}

class _MesasView extends StatefulWidget {
  const _MesasView();

  @override
  State<_MesasView> createState() => _MesasViewState();
}

class _MesasViewState extends State<_MesasView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _capacidadCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _abrirModalAgregarEditar(MesasProvider provider,
      {Mesa? mesa, int? index}) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(mesa != null ? 'Editar Mesa' : 'Agregar Mesa',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      if (v.length < 2 || v.length > 30) {
                        return 'El nombre debe tener entre 2 y 30 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Capacidad:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _capacidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      final num = int.tryParse(v ?? '');
                      if (num == null) {
                        return 'La capacidad debe ser un número entero.';
                      }
                      if (num < 1 || num > 20) {
                        return 'La capacidad debe estar entre 1 y 20.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Área:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _areaCtrl,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El área es obligatoria.';
                      }
                      if (v.length < 2 || v.length > 30) {
                        return 'El área debe tener entre 2 y 30 caracteres.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (mesa != null) {
  await provider.updateMesa(
  mesa.id,
  Mesa(
    id: mesa.id,
    nombre: _nombreCtrl.text.trim(),
    capacidad: int.parse(_capacidadCtrl.text),
    area: _areaCtrl.text.trim(),
    estado: mesa.estado,
  ),
);
} else {
                    await provider.addMesa(Mesa(
                      id: '', 
                      nombre: _nombreCtrl.text.trim(),
                      capacidad: int.parse(_capacidadCtrl.text),
                      area: _areaCtrl.text.trim(),
                      estado: 'Libre',
                    ));
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Colores oscuros para igualar el mockup
    final darkBgColor = const Color(0xFF1E1E1E); 

    final provider = Provider.of<MesasProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SectionHeader(
                    title: '🪑 Configuración de Mesas', // Icono añadido
                    subtitle: '${provider.mesas.length} mesas configuradas',
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _abrirModalAgregarEditar(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                  child: const Text('+ Nueva Mesa',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // KPI CARDS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKpiCard('Libres', provider.libres, const Color(0xFF2FFF7A)),
                const SizedBox(width: 20),
                _buildKpiCard('Ocupadas', provider.ocupadas, primaryColor),
                const SizedBox(width: 20),
                _buildKpiCard('Por cobrar', provider.porCobrar, primaryColor), // Ajustado al naranja de la imagen
              ],
            ),
            const SizedBox(height: 32),

            // FILTROS (CHIPS)
            Wrap(
              spacing: 12,
              children: provider.filtros.map((f) {
                final isActive = provider.filtroSeleccionado == f;
                return InkWell(
                  onTap: () => provider.setFiltro(f),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                        color: isActive ? primaryColor : darkBgColor, // Naranja o gris oscuro
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isActive ? primaryColor : Colors.transparent),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // LISTADO DE ÁREAS Y MESAS
            Expanded(
              child: ListView(
                children: provider.areas
                    .where((area) =>
                        provider.filtroSeleccionado == 'Todas' ||
                        provider.filtroSeleccionado == area)
                    .map((area) {
                  final mesasEnArea =
                      provider.mesas.where((m) => m.area == area).toList();
                  if (mesasEnArea.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Text(
                          area,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final cardWidth = 280.0;
                          final spacing = 16.0;
                          final columns = ((availableWidth + spacing) / (cardWidth + spacing)).floor();
                          final adjustedCardWidth = (availableWidth - (spacing * (columns > 0 ? columns - 1 : 0))) / (columns > 0 ? columns : 1);

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns > 0 ? columns : 1,
                              childAspectRatio: adjustedCardWidth / 200,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                            ),
                            itemCount: mesasEnArea.length,
                            itemBuilder: (context, index) {
                              final mesa = mesasEnArea[index];
                              final isOcupada = mesa.estado == 'Ocupada';
                              
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Stack(
                                  children: [
                                    // Contenido principal
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Badge de estado + Botones
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                mesa.estado,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  color: primaryColor,
                                                  onPressed: () => _abrirModalAgregarEditar(provider, mesa: mesa),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 18),
                                                  color: Colors.redAccent,
                                                  onPressed: isOcupada
                                                      ? () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('No puedes eliminar una mesa ocupada.'),
                                                              backgroundColor: Colors.redAccent,
                                                            ),
                                                          );
                                                        }
                                                      : () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              title: const Text('Eliminar mesa'),
                                                              content: Text('Se eliminará ${mesa.nombre}'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(context),
                                                                  child: const Text('Cancelar'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () async {
                                                                    await provider.removeMesa(mesa.id);
                                                                    if (context.mounted) {
                                                                      Navigator.pop(context);
                                                                    }
                                                                  },
                                                                  child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Nombre de la mesa
                                        Text(
                                          mesa.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Capacidad
                                        Text(
                                          '${mesa.capacidad} personas',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Área
                                        Text(
                                          mesa.area,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      )
                    ],
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
  // WIDGET KPI MEJORADO (Fondo oscuro, texto adaptado)
  Widget _buildKpiCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Fondo bien oscuro para la tarjeta
            border: Border.all(color: color, width: 1.0), // Borde fino
            borderRadius: BorderRadius.circular(12), // Bordes redondeados
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // Texto en blanco/gris claro
            )
          ],
        ),
      ),
    );
  }
}