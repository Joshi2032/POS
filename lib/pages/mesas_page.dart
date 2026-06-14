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

  void _abrirModalAgregarEditar(MesasProvider provider, {Mesa? mesa}) {
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
      builder: (ctx) {
        final dw = MediaQuery.of(ctx).size.width;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: dw < 480 ? 16 : 40,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            mesa != null ? 'Editar Mesa' : 'Agregar Mesa',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: dw < 480 ? double.infinity : 400,
            child: SingleChildScrollView(
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
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null) return 'Debe ser un número entero.';
                        if (n < 1 || n > 20) {
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
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
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
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminar(
      BuildContext context, MesasProvider provider, Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text('Se eliminará ${mesa.nombre}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await provider.removeMesa(mesa.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _mesaColumns(double w) {
    if (w < 400) return 1;
    if (w < 640) return 2;
    if (w < 960) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final provider = Provider.of<MesasProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPad = w < 480 ? 16.0 : (w < 900 ? 24.0 : 40.0);
            final vPad = w < 480 ? 16.0 : 24.0;
            final isCompact = w < 600;

            // Áreas filtradas con sus mesas
            final areasFiltradas = provider.areas.where((area) =>
                provider.filtroSeleccionado == 'Todas' ||
                provider.filtroSeleccionado == area);

            return CustomScrollView(
              slivers: [
                // ── Padding top + contenido estático ──────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // HEADER
                      if (isCompact) ...[
                        SectionHeader(
                          title: '🪑 Configuración de Mesas',
                          subtitle:
                              '${provider.mesas.length} mesas configuradas',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _BotonNuevaMesa(
                            primaryColor: primaryColor,
                            onPressed: () =>
                                _abrirModalAgregarEditar(provider),
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SectionHeader(
                                title: '🪑 Configuración de Mesas',
                                subtitle:
                                    '${provider.mesas.length} mesas configuradas',
                              ),
                            ),
                            const SizedBox(width: 16),
                            _BotonNuevaMesa(
                              primaryColor: primaryColor,
                              onPressed: () =>
                                  _abrirModalAgregarEditar(provider),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // KPI CARDS — siempre en fila de 3 con IntrinsicHeight
                      // para que la altura sea la del contenido, no un ratio fijo
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _KpiCard(
                                data: _KpiData('Libres', provider.libres,
                                    const Color(0xFF2FFF7A)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                data: _KpiData(
                                    'Ocupadas', provider.ocupadas, primaryColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                data: _KpiData('Por cobrar', provider.porCobrar,
                                    primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // FILTROS
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: provider.filtros.map((f) {
                          final isActive = provider.filtroSeleccionado == f;
                          return InkWell(
                            onTap: () => provider.setFiltro(f),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? primaryColor
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? primaryColor
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 13 : 14,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                    ]),
                  ),
                ),

                // ── Áreas + grids de mesas ─────────────────────────────────
                for (final area in areasFiltradas) ...[
                  Builder(builder: (context) {
                    final mesasEnArea =
                        provider.mesas.where((m) => m.area == area).toList();
                    if (mesasEnArea.isEmpty) return const SliverToBoxAdapter();

                    return SliverPadding(
                      padding:
                          EdgeInsets.symmetric(horizontal: hPad),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Título del área
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 16, bottom: 12),
                            child: Text(
                              area,
                              style: TextStyle(
                                fontSize: isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          // Grid de mesas con shrinkWrap dentro del sliver
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _mesaColumns(w),
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: isCompact ? 1.15 : 1.05,
                            ),
                            itemCount: mesasEnArea.length,
                            itemBuilder: (context, index) {
                              final mesa = mesasEnArea[index];
                              final isOcupada = mesa.estado == 'Ocupada';

                              return AppCard(
                                padding: EdgeInsets.all(isCompact ? 12 : 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              mesa.estado,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _IconAccion(
                                              icon: Icons.edit,
                                              color: primaryColor,
                                              onPressed: () =>
                                                  _abrirModalAgregarEditar(
                                                      provider,
                                                      mesa: mesa),
                                            ),
                                            const SizedBox(width: 2),
                                            _IconAccion(
                                              icon: Icons.delete,
                                              color: Colors.redAccent,
                                              onPressed: isOcupada
                                                  ? () {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'No puedes eliminar una mesa ocupada.'),
                                                          backgroundColor:
                                                              Colors
                                                                  .redAccent,
                                                        ),
                                                      );
                                                    }
                                                  : () =>
                                                      _confirmarEliminar(
                                                          context,
                                                          provider,
                                                          mesa),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      mesa.nombre,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isCompact ? 15 : 18,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${mesa.capacidad} personas',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mesa.area,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ]),
                      ),
                    );
                  }),
                ],

                // ── Padding bottom ─────────────────────────────────────────
                SliverPadding(padding: EdgeInsets.only(bottom: vPad)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _BotonNuevaMesa extends StatelessWidget {
  const _BotonNuevaMesa({
    required this.primaryColor,
    required this.onPressed,
  });

  final Color primaryColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: const Text(
        '+ Nueva Mesa',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}

class _IconAccion extends StatelessWidget {
  const _IconAccion({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      splashRadius: 18,
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: data.color, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.value.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: data.color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}