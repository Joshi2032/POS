import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reservaciones_provider.dart';
import '../models/reservacion.dart';
import '../widgets/app_widgets.dart';
import '../widgets/layout_widgets.dart';

class ReservacionesPage extends StatefulWidget {
  const ReservacionesPage({super.key});

  @override
  State<ReservacionesPage> createState() => _ReservacionesPageState();
}

class _ReservacionesPageState extends State<ReservacionesPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservacionesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF1E1E2D) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final isCompact = w < 600;
              final isMedium = w >= 600 && w < 900;
              final hPad = w < 480 ? 16.0 : (w < 900 ? 20.0 : 24.0);

              return Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: hPad, vertical: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.hasError) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No se pudieron cargar las reservaciones: '
                                '${provider.errorMessage}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // ── HEADER ──────────────────────────────────────────
                    if (isCompact) ...[
                      _HeaderTitle(textColor: textColor, isDark: isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerButton(
                              provider: provider,
                              textColor: textColor,
                              cardBg: cardBg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NuevaReservacionButton(provider: provider),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _HeaderTitle(
                                textColor: textColor, isDark: isDark),
                          ),
                          const SizedBox(width: 12),
                          _DatePickerButton(
                            provider: provider,
                            textColor: textColor,
                            cardBg: cardBg,
                          ),
                          const SizedBox(width: 10),
                          _NuevaReservacionButton(provider: provider),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── STATS ────────────────────────────────────────────
                    if (isCompact)
                      Column(
                        children: [
                          _StatCard(
                            label: 'Reservaciones Hoy',
                            value: '${provider.totalToday}',
                            sub: 'confirmadas: ${provider.confirmedToday}',
                            textColor: textColor,
                            subColor: isDark ? Colors.white38 : Colors.grey[500]!,
                            labelColor:
                                isDark ? Colors.white60 : Colors.grey[600]!,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Personas Hoy',
                                  value: '${provider.guestsTodayCount}',
                                  sub: 'personas confirmadas',
                                  textColor: textColor,
                                  subColor: Colors.orange,
                                  labelColor: Colors.orange[400]!,
                                  labelBold: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Fecha Seleccionada',
                                  value: provider.selectedDate,
                                  valueFontSize: 16,
                                  sub:
                                      '${provider.filteredReservations.length} reservaciones',
                                  textColor: textColor,
                                  subColor:
                                      isDark ? Colors.white38 : Colors.grey[500]!,
                                  labelColor:
                                      isDark ? Colors.white60 : Colors.grey[600]!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Reservaciones Hoy',
                              value: '${provider.totalToday}',
                              sub: 'confirmadas: ${provider.confirmedToday}',
                              textColor: textColor,
                              subColor:
                                  isDark ? Colors.white38 : Colors.grey[500]!,
                              labelColor:
                                  isDark ? Colors.white60 : Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Personas Hoy',
                              value: '${provider.guestsTodayCount}',
                              sub: 'personas confirmadas',
                              textColor: textColor,
                              subColor: Colors.orange,
                              labelColor: Colors.orange[400]!,
                              labelBold: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Fecha Seleccionada',
                              value: provider.selectedDate,
                              valueFontSize: isMedium ? 16 : 20,
                              sub:
                                  '${provider.filteredReservations.length} reservaciones',
                              textColor: textColor,
                              subColor:
                                  isDark ? Colors.white38 : Colors.grey[500]!,
                              labelColor:
                                  isDark ? Colors.white60 : Colors.grey[600]!,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // ── BUSCADOR ─────────────────────────────────────────
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nombre del cliente...',
                      ),
                      onChanged: (v) => provider.setSearchTerm(v),
                    ),
                    const SizedBox(height: 14),

                    // ── LISTA ────────────────────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.cargarReservaciones(),
                        child: provider.filteredReservations.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: const EmptyState(
                                      message:
                                          'No hay reservaciones para esta fecha',
                                      icon: Icons.inbox_outlined,
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  provider.paginatedReservations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final res =
                                    provider.paginatedReservations[index];
                                return _ReservacionCard(
                                  res: res,
                                  provider: provider,
                                  textColor: textColor,
                                  isDark: isDark,
                                  isCompact: isCompact,
                                );
                              },
                            ),
                      ),
                    ),

                    // ── PAGINACIÓN ───────────────────────────────────────
                    if (provider.totalPages > 1) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: provider.currentPage == 1
                                ? null
                                : () => provider
                                    .goToPage(provider.currentPage - 1),
                            child: Text(isCompact ? '← Ant.' : '← Anterior'),
                          ),
                          Text(
                            'Pág. ${provider.currentPage}/${provider.totalPages}',
                            style: TextStyle(
                                color: textColor,
                                fontSize: isCompact ? 12 : 14),
                          ),
                          ElevatedButton(
                            onPressed:
                                provider.currentPage == provider.totalPages
                                    ? null
                                    : () => provider
                                        .goToPage(provider.currentPage + 1),
                            child: Text(isCompact ? 'Sig. →' : 'Siguiente →'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // ── MODAL ────────────────────────────────────────────────────────
          if (provider.showModal) ...[
            const FadeInBarrier(onTap: null),
            FadeScaleIn(
              child: _ReservacionModal(provider: provider, cardBg: cardBg),
            ),
          ],
        ],
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.textColor, required this.isDark});
  final Color textColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📅 ', style: TextStyle(fontSize: 22)),
            Text('Reservaciones',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
        Text('Gestiona reservaciones de mesas',
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontSize: 13)),
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.provider,
    required this.textColor,
    required this.cardBg,
  });
  final ReservacionesProvider provider;
  final Color textColor;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_month, size: 16),
      label: Text(
        provider.selectedDate,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: cardBg,
        foregroundColor: textColor,
        elevation: 0,
        side: BorderSide(color: Theme.of(context).dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.tryParse(provider.selectedDate) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          provider.setSelectedDate(picked.toIso8601String().substring(0, 10));
        }
      },
    );
  }
}

class _NuevaReservacionButton extends StatelessWidget {
  const _NuevaReservacionButton({required this.provider});
  final ReservacionesProvider provider;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isCompact = w < 600;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => provider.abrirModal(),
      child: Text(
        isCompact ? '+ Reservación' : '+ Nueva Reservación',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.textColor,
    required this.subColor,
    required this.labelColor,
    this.valueFontSize = 24,
    this.labelBold = false,
  });

  final String label;
  final String value;
  final String sub;
  final Color textColor;
  final Color subColor;
  final Color labelColor;
  final double valueFontSize;
  final bool labelBold;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight:
                      labelBold ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ),
          Text(sub, style: TextStyle(color: subColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ReservacionCard extends StatelessWidget {
  const _ReservacionCard({
    required this.res,
    required this.provider,
    required this.textColor,
    required this.isDark,
    required this.isCompact,
  });

  final Reservacion res;
  final ReservacionesProvider provider;
  final Color textColor;
  final bool isDark;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    Color chipColor = Colors.green;
    if (res.estado == 'cancelada') chipColor = Colors.red;
    if (res.estado == 'completada') chipColor = Colors.blue;

    // En móvil los botones de acción van debajo de la info
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoSection(
                  res: res,
                  textColor: textColor,
                  isDark: isDark,
                  chipColor: chipColor,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _AccionesRow(
                  res: res,
                  provider: provider,
                  isCompact: true,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoSection(
                    res: res,
                    textColor: textColor,
                    isDark: isDark,
                    chipColor: chipColor,
                  ),
                ),
                const SizedBox(width: 8),
                _AccionesRow(
                  res: res,
                  provider: provider,
                  isCompact: false,
                ),
              ],
            ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.res,
    required this.textColor,
    required this.isDark,
    required this.chipColor,
  });

  final Reservacion res;
  final Color textColor;
  final bool isDark;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID + nombre + estado
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4)),
              child: Text(res.id,
                  style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight: FontWeight.bold)),
            ),
            Text(res.cliente,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            Chip(
              label: Text(res.estado.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              backgroundColor: chipColor,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Detalles: usa Wrap para que se reorganicen en móvil
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _IconText(
                icon: Icons.people, text: '${res.personas} persona(s)',
                iconColor: iconColor, textColor: mutedColor),
            _IconText(
                icon: Icons.access_time, text: res.hora,
                iconColor: iconColor, textColor: mutedColor),
            _IconText(
                icon: Icons.phone, text: res.telefono,
                iconColor: iconColor, textColor: mutedColor),
          ],
        ),
        const SizedBox(height: 6),
        Text('Mesa/Área: ${res.mesa}',
            style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.orange[400])),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
  });
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: textColor)),
      ],
    );
  }
}

class _AccionesRow extends StatelessWidget {
  const _AccionesRow({
    required this.res,
    required this.provider,
    required this.isCompact,
  });
  final Reservacion res;
  final ReservacionesProvider provider;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      // Botones más pequeños, en fila horizontal
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Editar', style: TextStyle(fontSize: 12)),
            onPressed: res.estado == 'completada'
                ? null
                : () => provider.abrirEditarModal(res),
          ),
          TextButton.icon(
            icon: const Icon(Icons.block, size: 14, color: Colors.red),
            label: const Text('Cancelar',
                style: TextStyle(color: Colors.red, fontSize: 12)),
            onPressed: res.estado != 'confirmada'
                ? null
                : () => provider.cancelarReservacion(res.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            tooltip: 'Eliminar reservación',
            onPressed: () => _confirmarEliminar(context, provider, res),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit, size: 15),
          label: const Text('Editar'),
          onPressed: res.estado == 'completada'
              ? null
              : () => provider.abrirEditarModal(res),
        ),
        TextButton.icon(
          icon: const Icon(Icons.block, size: 15, color: Colors.red),
          label:
              const Text('Cancelar', style: TextStyle(color: Colors.red)),
          onPressed: res.estado != 'confirmada'
              ? null
              : () => provider.cancelarReservacion(res.id),
        ),
        IconButton(
          icon:
              const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Eliminar reservación',
          onPressed: () => _confirmarEliminar(context, provider, res),
        ),
      ],
    );
  }

  void _confirmarEliminar(
    BuildContext context,
    ReservacionesProvider provider,
    Reservacion res,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar reservación'),
          content: Text(
            '¿Seguro que deseas eliminar la reservación de '
            '"${res.cliente}"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);

                final exito = await provider.eliminarReservacion(res.id);

                if (!context.mounted) return;

                if (!exito) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'No se pudo eliminar la reservación.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}

// ── MODAL ────────────────────────────────────────────────────────────────────

class _ReservacionModal extends StatelessWidget {
  const _ReservacionModal({
    required this.provider,
    required this.cardBg,
  });
  final ReservacionesProvider provider;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Ancho adaptativo: en móvil casi full-width, en escritorio fijo
    final modalW = screenW < 520 ? screenW - 32 : 460.0;
    // Alto máximo para que no se salga de pantalla en móvil
    final maxH = screenH * 0.88;

    return Center(
      child: Container(
        width: modalW,
        constraints: BoxConstraints(maxHeight: maxH),
        margin: EdgeInsets.symmetric(horizontal: screenW < 520 ? 16 : 0),
        padding: EdgeInsets.all(screenW < 480 ? 18 : 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      provider.editingId != null
                          ? 'Editar Reservación'
                          : 'Nueva Reservación',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    tooltip: 'Cerrar',
                    onPressed: () => provider.cerrarModal(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (provider.modalError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(provider.modalError,
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 14),
              _FormField(
                label: 'Nombre del Cliente',
                initialValue: provider.formValues['cliente'],
                textColor: textColor,
                onChanged: (v) => provider.updateFormField('cliente', v),
              ),
              const SizedBox(height: 10),
              _FormField(
                label: 'Teléfono',
                initialValue: provider.formValues['telefono'],
                textColor: textColor,
                onChanged: (v) => provider.updateFormField('telefono', v),
              ),
              const SizedBox(height: 10),
              // Personas + Fecha: en móvil apilados, en escritorio en fila
              if (screenW < 400)
                Column(
                  children: [
                    _FormField(
                      label: 'Nº Personas',
                      initialValue: provider.formValues['personas'].toString(),
                      textColor: textColor,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => provider.updateFormField(
                          'personas', int.tryParse(v) ?? 2),
                    ),
                    const SizedBox(height: 10),
                    _FormField(
                      label: 'Fecha (YYYY-MM-DD)',
                      initialValue: provider.formValues['fecha'],
                      textColor: textColor,
                      onChanged: (v) => provider.updateFormField('fecha', v),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'Nº Personas',
                        initialValue:
                            provider.formValues['personas'].toString(),
                        textColor: textColor,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => provider.updateFormField(
                            'personas', int.tryParse(v) ?? 2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FormField(
                        label: 'Fecha (YYYY-MM-DD)',
                        initialValue: provider.formValues['fecha'],
                        textColor: textColor,
                        onChanged: (v) =>
                            provider.updateFormField('fecha', v),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              _FormField(
                label: 'Hora (HH:MM)',
                initialValue: provider.formValues['hora'],
                textColor: textColor,
                onChanged: (v) => provider.updateFormField('hora', v),
              ),
              const SizedBox(height: 10),
              _FormField(
                label: 'Mesa / Notas',
                initialValue: provider.formValues['mesa'],
                textColor: textColor,
                onChanged: (v) => provider.updateFormField('mesa', v),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final success = await provider.guardarReservacion();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Reservación procesada exitosamente'),
                                  backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage ??
                                      'No se pudo guardar la reservación.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          provider.editingId != null
                              ? 'Actualizar Reservación'
                              : 'Guardar Reservación',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.initialValue,
    required this.textColor,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String? initialValue;
  final Color textColor;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(color: textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}