// lib/pages/mesas_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mesa.dart';
import '../providers/mesas_provider.dart';
import '../widgets/app_widgets.dart';

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

  final _nombreController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _capacidadController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  int _columnasPorAncho(double width) {
    if (width < 400) return 1;
    if (width < 640) return 2;
    if (width < 960) return 3;
    return 4;
  }

  bool _esMesaOcupada(Mesa mesa) {
    return mesa.estado.trim().toLowerCase() == 'ocupada';
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _capacidadController.text = '1';
    _areaController.clear();
  }

  void _cargarFormulario(Mesa mesa) {
    _nombreController.text = mesa.nombre;
    _capacidadController.text = mesa.capacidad.toString();
    _areaController.text = mesa.area;
  }

  Future<void> _abrirFormularioMesa(
    MesasProvider provider, {
    Mesa? mesa,
  }) async {
    if (mesa == null) {
      _limpiarFormulario();
    } else {
      _cargarFormulario(mesa);
    }

    final esEdicion = mesa != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 480 ? 16 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            esEdicion ? 'Editar Mesa' : 'Agregar Mesa',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: width < 480 ? double.infinity : 400,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CampoFormulario(
                      label: 'Nombre',
                      controller: _nombreController,
                      validator: (value) {
                        final texto = value?.trim() ?? '';

                        if (texto.isEmpty) {
                          return 'El nombre es obligatorio.';
                        }

                        if (texto.length < 2 || texto.length > 30) {
                          return 'Debe tener entre 2 y 30 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _CampoFormulario(
                      label: 'Capacidad',
                      controller: _capacidadController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final capacidad = int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (capacidad == null) {
                          return 'Debe ser un número entero.';
                        }

                        if (capacidad < 1 || capacidad > 20) {
                          return 'Debe estar entre 1 y 20.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _CampoFormulario(
                      label: 'Área',
                      controller: _areaController,
                      validator: (value) {
                        final texto = value?.trim() ?? '';

                        if (texto.isEmpty) {
                          return 'El área es obligatoria.';
                        }

                        if (texto.length < 2 || texto.length > 30) {
                          return 'Debe tener entre 2 y 30 caracteres.';
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
  onPressed: () async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final rootMessenger = ScaffoldMessenger.of(context);
    final dialogNavigator = Navigator.of(dialogContext);
    final dialogMessenger = ScaffoldMessenger.of(dialogContext);

    final nuevaMesa = Mesa(
      id: mesa?.id ?? '',
      nombre: _nombreController.text.trim(),
      capacidad: int.parse(
        _capacidadController.text.trim(),
      ),
      area: _areaController.text.trim(),
      estado: mesa?.estado ?? 'Libre',
    );

    final guardada = esEdicion
        ? await provider.updateMesa(
            mesa.id,
            nuevaMesa,
          )
        : await provider.addMesa(nuevaMesa);

    if (!dialogContext.mounted) return;

    if (guardada) {
      dialogNavigator.pop();

      rootMessenger.showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Mesa actualizada correctamente.'
                : 'Mesa creada correctamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      dialogMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'No se pudo guardar la mesa.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(dialogContext).primaryColor,
    foregroundColor: Colors.white,
  ),
  child: const Text('Guardar'),
),
          ],
        );
      },
    );
  }

  Future<void> _confirmarEliminar(
    MesasProvider provider,
    Mesa mesa,
  ) async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar mesa'),
          content: Text(
            '¿Seguro que deseas eliminar ${mesa.nombre}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmada != true || !mounted) return;

    final eliminada = await provider.removeMesa(mesa.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eliminada
              ? 'Mesa eliminada correctamente.'
              : provider.errorMessage ??
                  'No se pudo eliminar la mesa.',
        ),
        backgroundColor:
            eliminada ? Colors.green : Colors.red,
      ),
    );
  }

  void _mostrarErrorMesaOcupada() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No puedes eliminar una mesa ocupada.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesasProvider>();

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width < 480
                ? 16.0
                : width < 900
                    ? 24.0
                    : 40.0;

            final verticalPadding =
                width < 480 ? 16.0 : 24.0;

            final isCompact = width < 600;

            final mesasVisibles = provider.mesasFiltradas;

            final areasVisibles = mesasVisibles
                .map((mesa) => mesa.area.trim())
                .where((area) => area.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            return RefreshIndicator(
              onRefresh: provider.cargarMesas,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _HeaderMesas(
                          isCompact: isCompact,
                          totalMesas: provider.mesas.length,
                          primaryColor: primaryColor,
                          onNuevaMesa: () {
                            _abrirFormularioMesa(provider);
                          },
                        ),
                        const SizedBox(height: 24),

                        _ResumenMesas(
                          libres: provider.libres,
                          ocupadas: provider.ocupadas,
                          porCobrar: provider.porCobrar,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 24),

                        _FiltrosMesas(
                          filtros: provider.filtros,
                          filtroSeleccionado:
                              provider.filtroSeleccionado,
                          primaryColor: primaryColor,
                          isCompact: isCompact,
                          onSelected: provider.setFiltro,
                        ),
                        const SizedBox(height: 20),

                        if (provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 30,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        if (provider.hasError &&
                            !provider.isLoading)
                          _MensajeEstado(
                            icon: Icons.error_outline,
                            mensaje: provider.errorMessage ??
                                'Ocurrió un error al cargar las mesas.',
                            color: Colors.redAccent,
                          ),

                        if (!provider.isLoading &&
                            !provider.hasError &&
                            mesasVisibles.isEmpty)
                          _MensajeEstado(
                            icon: Icons.table_restaurant_outlined,
                            mensaje:
                                'No hay mesas para el filtro seleccionado.',
                            color: textColor.withValues(
                              alpha: 0.65,
                            ),
                          ),
                      ]),
                    ),
                  ),

                  if (!provider.isLoading &&
                      !provider.hasError)
                    for (final area in areasVisibles)
                      _construirSeccionArea(
                        area: area,
                        mesasVisibles: mesasVisibles,
                        width: width,
                        horizontalPadding:
                            horizontalPadding,
                        isCompact: isCompact,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        provider: provider,
                      ),

                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: verticalPadding,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirSeccionArea({
    required String area,
    required List<Mesa> mesasVisibles,
    required double width,
    required double horizontalPadding,
    required bool isCompact,
    required Color primaryColor,
    required Color textColor,
    required MesasProvider provider,
  }) {
    final mesasEnArea = mesasVisibles.where((mesa) {
      return mesa.area.trim().toLowerCase() ==
          area.trim().toLowerCase();
    }).toList();

    if (mesasEnArea.isEmpty) {
      return const SliverToBoxAdapter();
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 12,
            ),
            child: Text(
              area,
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columnasPorAncho(width),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio:
                  isCompact ? 1.15 : 1.05,
            ),
            itemCount: mesasEnArea.length,
            itemBuilder: (context, index) {
              final mesa = mesasEnArea[index];
              final ocupada = _esMesaOcupada(mesa);

              return _MesaCard(
                mesa: mesa,
                ocupada: ocupada,
                isCompact: isCompact,
                primaryColor: primaryColor,
                onEditar: () {
                  _abrirFormularioMesa(
                    provider,
                    mesa: mesa,
                  );
                },
                onEliminar: ocupada
                    ? _mostrarErrorMesaOcupada
                    : () {
                        _confirmarEliminar(
                          provider,
                          mesa,
                        );
                      },
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _HeaderMesas extends StatelessWidget {
  const _HeaderMesas({
    required this.isCompact,
    required this.totalMesas,
    required this.primaryColor,
    required this.onNuevaMesa,
  });

  final bool isCompact;
  final int totalMesas;
  final Color primaryColor;
  final VoidCallback onNuevaMesa;

  @override
  Widget build(BuildContext context) {
    final header = SectionHeader(
      title: '🪑 Configuración de Mesas',
      subtitle: '$totalMesas mesas configuradas',
    );

    final boton = _BotonNuevaMesa(
      primaryColor: primaryColor,
      onPressed: onNuevaMesa,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          boton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: header),
        const SizedBox(width: 16),
        boton,
      ],
    );
  }
}

class _ResumenMesas extends StatelessWidget {
  const _ResumenMesas({
    required this.libres,
    required this.ocupadas,
    required this.porCobrar,
    required this.primaryColor,
  });

  final int libres;
  final int ocupadas;
  final int porCobrar;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _KpiCard(
              data: _KpiData(
                'Libres',
                libres,
                const Color(0xFF2FFF7A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              data: _KpiData(
                'Ocupadas',
                ocupadas,
                primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              data: _KpiData(
                'Por cobrar',
                porCobrar,
                primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosMesas extends StatelessWidget {
  const _FiltrosMesas({
    required this.filtros,
    required this.filtroSeleccionado,
    required this.primaryColor,
    required this.isCompact,
    required this.onSelected,
  });

  final List<String> filtros;
  final String filtroSeleccionado;
  final Color primaryColor;
  final bool isCompact;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filtros.map((filtro) {
        final seleccionado =
            filtroSeleccionado == filtro;

        return InkWell(
          onTap: () => onSelected(filtro),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: seleccionado
                  ? primaryColor
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: seleccionado
                    ? primaryColor
                    : Colors.transparent,
              ),
            ),
            child: Text(
              filtro,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 13 : 14,
                color: seleccionado
                    ? Colors.white
                    : Colors.white70,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MesaCard extends StatelessWidget {
  const _MesaCard({
    required this.mesa,
    required this.ocupada,
    required this.isCompact,
    required this.primaryColor,
    required this.onEditar,
    required this.onEliminar,
  });

  final Mesa mesa;
  final bool ocupada;
  final bool isCompact;
  final Color primaryColor;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final estadoNormalizado =
        mesa.estado.trim().toLowerCase();

    final Color estadoColor;

    if (estadoNormalizado == 'ocupada') {
      estadoColor = Colors.orange;
    } else if (estadoNormalizado == 'por cobrar' ||
        estadoNormalizado == 'cuenta') {
      estadoColor = Colors.redAccent;
    } else {
      estadoColor = Colors.green;
    }

    return AppCard(
      padding: EdgeInsets.all(
        isCompact ? 12 : 16,
      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor,
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    mesa.estado,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAccion(
                    icon: Icons.edit,
                    color: primaryColor,
                    onPressed: onEditar,
                  ),
                  const SizedBox(width: 2),
                  _IconAccion(
                    icon: Icons.delete,
                    color: ocupada
                        ? Colors.grey
                        : Colors.redAccent,
                    onPressed: onEliminar,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mesa.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 15 : 18,
              color: Colors.white,
            ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoFormulario extends StatelessWidget {
  const _CampoFormulario({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  const _MensajeEstado({
    required this.icon,
    required this.mensaje,
    required this.color,
  });

  final IconData icon;
  final String mensaje;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 36,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
      child: const Text(
        '+ Nueva Mesa',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
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
      icon: Icon(
        icon,
        size: 18,
      ),
      color: color,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 30,
        minHeight: 30,
      ),
      splashRadius: 18,
    );
  }
}

class _KpiData {
  const _KpiData(
    this.label,
    this.value,
    this.color,
  );

  final String label;
  final int value;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.data,
  });

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: data.color,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.value.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: data.color,
              height: 1,
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