import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/empleado.dart';
import '../models/nomina_pago.dart';
import '../providers/empleados_provider.dart';
import '../providers/nominas_provider.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../utils/formatters.dart';

class NominasPage extends StatelessWidget {
  const NominasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NominasView();
  }
}

class _NominasView extends StatefulWidget {
  const _NominasView();

  @override
  State<_NominasView> createState() => _NominasViewState();
}

class _NominasViewState extends State<_NominasView> {
  Future<void> _openEditor(
    NominasProvider provider, {
    NominaPago? nomina,
  }) async {
    final fechaCtrl = TextEditingController(
      text: nomina?.fecha ??
          DateTime.now().toIso8601String().split('T').first,
    );

    String? selectedEmpleadoId = nomina?.empleadoId;

    // Incluimos también al empleado ya asignado aunque esté inactivo, para
    // no bloquear la edición de una nómina antigua (solo cambiar el monto o
    // la fecha) por haber dado de baja a ese empleado después.
    final empleadosDisponibles = context
        .read<EmpleadosProvider>()
        .empleados
        .where((e) => e.active || e.id == nomina?.empleadoId)
        .toList();

    final montoCtrl = TextEditingController(
      text: nomina == null ? '' : nomina.monto.toString(),
    );

    final notasCtrl = TextEditingController(
      text: nomina?.notas ?? '',
    );

    String tipo = nomina?.tipo ?? 'Salario';
    String periodo = nomina?.periodo ?? 'Quincenal';
    String metodo = nomina?.metodo ?? 'Transferencia';
    bool guardando = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final width = MediaQuery.sizeOf(dialogContext).width;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> guardar() async {
                if (guardando) return;

                final fechaTexto = fechaCtrl.text.trim();

                final montoTexto = montoCtrl.text
                    .trim()
                    .replaceAll(',', '.');

                final fecha = DateTime.tryParse(fechaTexto);
                final monto = double.tryParse(montoTexto) ?? 0;

                Empleado? empleadoSeleccionado;
                for (final e in empleadosDisponibles) {
                  if (e.id == selectedEmpleadoId) {
                    empleadoSeleccionado = e;
                    break;
                  }
                }

                if (empleadoSeleccionado == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Selecciona el empleado que recibe el pago.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (fecha == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La fecha debe tener el formato YYYY-MM-DD.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (monto <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El monto debe ser mayor que cero.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final nuevaNomina = NominaPago(
                  id: nomina?.id ?? '',
                  empleadoId: empleadoSeleccionado.id,
                  fecha: fechaTexto,
                  empleadoNombre:
                      '${empleadoSeleccionado.firstName} ${empleadoSeleccionado.lastName}'
                          .trim(),
                  tipo: tipo,
                  periodo: periodo,
                  monto: monto,
                  metodo: metodo,
                  notas: notasCtrl.text.trim(),
                );

                setDialogState(() {
                  guardando = true;
                });

                final bool guardado;

                if (nomina == null) {
                  guardado = await provider.agregarNomina(
                    nuevaNomina,
                  );
                } else {
                  guardado = await provider.actualizarNomina(
                    nomina.id,
                    nuevaNomina,
                  );
                }

                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                if (guardado) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nomina == null
                            ? 'Pago registrado correctamente.'
                            : 'Pago actualizado correctamente.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  setDialogState(() {
                    guardando = false;
                  });

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'No se pudo guardar el pago.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: width < 480 ? 12 : 40,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  nomina == null
                      ? 'Agregar Pago'
                      : 'Editar Pago',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: width < 480
                      ? double.infinity
                      : 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (width < 400) ...[
                          _DField(
                            ctrl: fechaCtrl,
                            label: 'Fecha',
                          ),
                          const SizedBox(height: 12),
                          _EmpleadoDropdown(
                            empleados: empleadosDisponibles,
                            selectedId: selectedEmpleadoId,
                            enabled: !guardando,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedEmpleadoId = value;
                              });
                            },
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _DField(
                                  ctrl: fechaCtrl,
                                  label: 'Fecha',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _EmpleadoDropdown(
                                  empleados: empleadosDisponibles,
                                  selectedId: selectedEmpleadoId,
                                  enabled: !guardando,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedEmpleadoId = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        if (width < 400) ...[
                          _DDropdown(
                            label: 'Tipo',
                            value: tipo,
                            items: const [
                              'Salario',
                              'Adelanto',
                              'Bono',
                              'Deducción',
                            ],
                            onChanged: guardando
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      tipo =
                                          value ?? 'Salario';
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          _DDropdown(
                            label: 'Período',
                            value: periodo,
                            items: const [
                              'Semanal',
                              'Quincenal',
                              'Mensual',
                            ],
                            onChanged: guardando
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      periodo =
                                          value ?? 'Quincenal';
                                    });
                                  },
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _DDropdown(
                                  label: 'Tipo',
                                  value: tipo,
                                  items: const [
                                    'Salario',
                                    'Adelanto',
                                    'Bono',
                                    'Deducción',
                                  ],
                                  onChanged: guardando
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            tipo = value ??
                                                'Salario';
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DDropdown(
                                  label: 'Período',
                                  value: periodo,
                                  items: const [
                                    'Semanal',
                                    'Quincenal',
                                    'Mensual',
                                  ],
                                  onChanged: guardando
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            periodo = value ??
                                                'Quincenal';
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        if (width < 400) ...[
                          _DField(
                            ctrl: montoCtrl,
                            label: 'Monto',
                            prefixText: '\$ ',
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DDropdown(
                            label: 'Método',
                            value: metodo,
                            items: const [
                              'Transferencia',
                              'Efectivo',
                              'Depósito',
                            ],
                            onChanged: guardando
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      metodo = value ??
                                          'Transferencia';
                                    });
                                  },
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _DField(
                                  ctrl: montoCtrl,
                                  label: 'Monto',
                                  prefixText: '\$ ',
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DDropdown(
                                  label: 'Método',
                                  value: metodo,
                                  items: const [
                                    'Transferencia',
                                    'Efectivo',
                                    'Depósito',
                                  ],
                                  onChanged: guardando
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            metodo = value ??
                                                'Transferencia';
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        _DField(
                          ctrl: notasCtrl,
                          label: 'Notas',
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: guardando
                        ? null
                        : () {
                            Navigator.pop(dialogContext);
                          },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(dialogContext).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: guardando ? null : guardar,
                    child: guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      fechaCtrl.dispose();
      montoCtrl.dispose();
      notasCtrl.dispose();
    }
  }

  Future<void> _confirmarEliminar(
    NominasProvider provider,
    NominaPago nomina,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pago'),
          content: Text(
            '¿Seguro que deseas eliminar el pago de ${nomina.empleado}?',
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

    if (confirmado != true || !mounted) return;

    final eliminado = await provider.eliminarNomina(
      nomina.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eliminado
              ? 'Pago eliminado correctamente.'
              : provider.errorMessage ??
                  'No se pudo eliminar el pago.',
        ),
        backgroundColor:
            eliminado ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NominasProvider>();
    final paginated = provider.paginatedNominas;

    final theme = Theme.of(context);
    final primaryTextColor =
        theme.colorScheme.onSurface;
    final mutedTextColor =
        theme.textTheme.bodySmall?.color ??
            Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding =
                width < 480 ? 16.0 : 24.0;
            final isCompact = width < 600;

            return RefreshIndicator(
              onRefresh: provider.cargarNominas,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      horizontalPadding,
                      horizontalPadding,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (isCompact) ...[
                          SectionHeader(
                            title: '💼 Nóminas y Pagos',
                            subtitle:
                                '${provider.nominasFiltradas.length} registros',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Agregar Pago',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.primaryColor,
                                foregroundColor:
                                    Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () {
                                _openEditor(provider);
                              },
                            ),
                          ),
                        ] else
                          SectionHeader(
                            title: '💼 Nóminas y Pagos',
                            subtitle:
                                '${provider.nominasFiltradas.length} registros de transacciones',
                            actionLabel: 'Agregar Pago',
                            onAction: () {
                              _openEditor(provider);
                            },
                          ),

                        const SizedBox(height: 20),

                        TextField(
                          style: TextStyle(
                            color: primaryTextColor,
                          ),
                          decoration:
                              const InputDecoration(
                            prefixIcon:
                                Icon(Icons.search),
                            hintText:
                                'Buscar pago por empleado, tipo o método...',
                          ),
                          onChanged: provider.setSearch,
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                provider.tipos.length,
                            itemBuilder:
                                (context, index) {
                              final tipo =
                                  provider.tipos[index];

                              final seleccionado =
                                  provider.selectedType ==
                                      tipo;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  right: 8,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    tipo,
                                    style: TextStyle(
                                      fontSize:
                                          isCompact
                                              ? 12
                                              : 13,
                                    ),
                                  ),
                                  selected:
                                      seleccionado,
                                  selectedColor:
                                      theme.primaryColor,
                                  backgroundColor:
                                      theme.cardColor,
                                  labelStyle:
                                      TextStyle(
                                    color: seleccionado
                                        ? Colors.white
                                        : primaryTextColor,
                                    fontWeight:
                                        seleccionado
                                            ? FontWeight
                                                .bold
                                            : FontWeight
                                                .normal,
                                  ),
                                  onSelected: (_) {
                                    provider.setType(
                                      tipo,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Total pagado este mes',
                                      style: TextStyle(
                                        color:
                                            mutedTextColor,
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    FittedBox(
                                      fit:
                                          BoxFit.scaleDown,
                                      alignment: Alignment
                                          .centerLeft,
                                      child: Text(
                                        Formatters.money(
                                          provider
                                              .totalMensual,
                                        ),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              primaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons
                                    .account_balance_wallet_outlined,
                                color:
                                    theme.primaryColor,
                                size: 28,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (provider.isLoading)
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 32,
                            ),
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          )
                        else if (provider.hasError)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 32,
                            ),
                            child: EmptyState(
                              message:
                                  provider.errorMessage ??
                                      'No se pudieron cargar los pagos.',
                              icon: Icons.error_outline,
                              actionLabel: 'Reintentar',
                              onAction:
                                  provider.cargarNominas,
                            ),
                          )
                        else if (paginated.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 32,
                            ),
                            child: EmptyState(
                              message:
                                  'No hay registros de nómina que coincidan con la búsqueda.',
                              icon:
                                  Icons.payments_outlined,
                              actionLabel:
                                  'Limpiar Filtros',
                              onAction: () {
                                provider.setSearch('');
                                provider.setType(
                                  'Todos',
                                );
                              },
                            ),
                          )
                        else
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                              child:
                                  ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    paginated.length,
                                separatorBuilder:
                                    (_, __) => Divider(
                                  color: theme.dividerColor
                                      .withValues(
                                    alpha: 0.5,
                                  ),
                                  height: 1,
                                ),
                                itemBuilder:
                                    (_, index) {
                                  final nomina =
                                      paginated[index];

                                  return _NominaTile(
                                    nomina: nomina,
                                    primaryTextColor:
                                        primaryTextColor,
                                    mutedTextColor:
                                        mutedTextColor,
                                    isCompact:
                                        isCompact,
                                    onEdit: () {
                                      _openEditor(
                                        provider,
                                        nomina: nomina,
                                      );
                                    },
                                    onDelete: () {
                                      _confirmarEliminar(
                                        provider,
                                        nomina,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        if (provider.totalPages > 1)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 24,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                OutlinedButton(
                                  onPressed: provider
                                              .currentPage >
                                          1
                                      ? () {
                                          provider
                                              .changePage(
                                            provider.currentPage -
                                                1,
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    isCompact
                                        ? '← Ant.'
                                        : 'Anterior',
                                  ),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Text(
                                  'Pág. ${provider.currentPage}/${provider.totalPages}',
                                  style: TextStyle(
                                    color:
                                        primaryTextColor,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                OutlinedButton(
                                  onPressed: provider
                                              .currentPage <
                                          provider
                                              .totalPages
                                      ? () {
                                          provider
                                              .changePage(
                                            provider.currentPage +
                                                1,
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    isCompact
                                        ? 'Sig. →'
                                        : 'Siguiente',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ]),
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
}

class _NominaTile extends StatelessWidget {
  const _NominaTile({
    required this.nomina,
    required this.primaryTextColor,
    required this.mutedTextColor,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
  });

  final NominaPago nomina;
  final Color primaryTextColor;
  final Color mutedTextColor;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nomina.empleado,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.money(nomina.monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${nomina.tipo} · ${nomina.periodo} · ${nomina.fecha}',
              style: TextStyle(
                color: mutedTextColor,
                fontSize: 12,
              ),
            ),
            if (nomina.metodo.isNotEmpty)
              Text(
                nomina.metodo,
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blueGrey,
                    size: 18,
                  ),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: Text(
        nomina.empleado,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${nomina.tipo} · ${nomina.periodo} · ${nomina.fecha}',
          style: TextStyle(
            color: mutedTextColor,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.money(nomina.monto),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.blueGrey,
              size: 20,
            ),
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DField extends StatelessWidget {
  const _DField({
    required this.ctrl,
    required this.label,
    this.prefixText,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String label;
  final String? prefixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _EmpleadoDropdown extends StatelessWidget {
  const _EmpleadoDropdown({
    required this.empleados,
    required this.selectedId,
    required this.onChanged,
    this.enabled = true,
  });

  final List<Empleado> empleados;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final valorValido =
        empleados.any((e) => e.id == selectedId) ? selectedId : null;

    return DropdownButtonFormField<String>(
      dropdownColor: Theme.of(context).cardColor,
      initialValue: valorValido,
      isExpanded: true,
      items: empleados
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.id,
              child: Text(
                e.active
                    ? '${e.firstName} ${e.lastName}'.trim()
                    : '${'${e.firstName} ${e.lastName}'.trim()} (inactivo)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: const InputDecoration(
        labelText: 'Empleado',
        border: OutlineInputBorder(),
      ),
      hint: empleados.isEmpty
          ? const Text('No hay empleados activos')
          : const Text('Selecciona un empleado'),
    );
  }
}

class _DDropdown extends StatelessWidget {
  const _DDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      dropdownColor:
          Theme.of(context).cardColor,
      initialValue: value,
      items: items
          .map(
            (item) =>
                DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border:
            const OutlineInputBorder(),
      ),
    );
  }
}