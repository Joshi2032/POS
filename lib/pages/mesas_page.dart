// lib/pages/mesas_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesas_provider.dart';
import '../widgets/app_widgets.dart';
import '../models/mesa.dart'; // Aseguramos importar el modelo correcto

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
              // Convertimos el botón en asíncrono para esperar a Supabase
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (mesa != null && index != null) {
                    await provider.updateMesa(
                        index,
                        Mesa(
                          id: mesa.id, // Mantenemos el ID original
                          nombre: _nombreCtrl.text.trim(),
                          capacidad: int.parse(_capacidadCtrl.text),
                          area: _areaCtrl.text.trim(),
                          estado: mesa.estado,
                        ));
                  } else {
                    await provider.addMesa(Mesa(
                      id: '', // ID vacío, Supabase lo generará
                      nombre: _nombreCtrl.text.trim(),
                      capacidad: int.parse(_capacidadCtrl.text),
                      area: _areaCtrl.text.trim(),
                      estado: 'Libre',
                    ));
                  }

                  // Verifica si el widget sigue en pantalla antes de cerrarlo
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

  void _solicitarBorrado(MesasProvider provider, Mesa mesa) {
    if (mesa.estado == 'Ocupada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No puedes eliminar una mesa ocupada. Primero libérala o cierra su cuenta.'),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            // Convertimos la confirmación en asíncrona
            onPressed: () async {
              await provider.removeMesa(mesa);
              if (context.mounted) {
                Navigator.pop(context);
              }
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

    // Conectamos la interfaz al cerebro del módulo
    final provider = Provider.of<MesasProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SectionHeader(
                    title: 'Configuración de Mesas',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKpiCard(
                    'Libres', provider.libres, const Color(0xFF2FFF7A)),
                const SizedBox(width: 20),
                _buildKpiCard('Ocupadas', provider.ocupadas, primaryColor),
                const SizedBox(width: 20),
                _buildKpiCard(
                    'Por cobrar', provider.porCobrar, const Color(0xFFFFB347)),
              ],
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              children: provider.filtros.map((f) {
                final isActive = provider.filtroSeleccionado == f;
                return InkWell(
                  onTap: () => provider.setFiltro(f),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                        color: isActive
                            ? primaryColor
                            : Theme.of(context).cardColor,
                        border: Border.all(
                            color: isActive
                                ? primaryColor
                                : Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]),
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
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: Text(
                          area,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: mesasEnArea.length,
                        itemBuilder: (context, index) {
                          final mesa = mesasEnArea[index];
                          final isLibre = mesa.estado == 'Libre';
                          final badgeColor =
                              isLibre ? const Color(0xFF2FFF7A) : primaryColor;

                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    border: Border.all(
                                        color:
                                            badgeColor.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mesa.estado,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.edit_outlined,
                                            size: 20, color: primaryColor),
                                        onPressed: () =>
                                            _abrirModalAgregarEditar(provider,
                                                mesa: mesa,
                                                index: provider.mesas
                                                    .indexOf(mesa)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        onPressed: () =>
                                            _solicitarBorrado(provider, mesa),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 36,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(mesa.nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text('${mesa.capacidad} personas',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                              fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      Text(mesa.area,
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
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
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            )
          ],
        ),
      ),
    );
  }
}
