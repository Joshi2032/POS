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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER DEL MÓDULO (Diseño original Angular)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📅 ', style: TextStyle(fontSize: 24)),
                            Text('Reservaciones',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                          ],
                        ),
                        Text('Gestiona reservaciones de mesas',
                            style: TextStyle(
                                color:
                                    isDark ? Colors.white60 : Colors.grey[600],
                                fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(provider.selectedDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardBg,
                            foregroundColor: textColor,
                            elevation: 0,
                            side: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(provider.selectedDate) ??
                                      DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              provider.setSelectedDate(
                                  picked.toIso8601String().substring(0, 10));
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => provider.abrirModal(),
                          child: const Text('+ Nueva Reservación',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // STATS GRID
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reservaciones Hoy',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${provider.totalToday}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            Text('confirmadas: ${provider.confirmedToday}',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[500],
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personas Hoy',
                                style: TextStyle(
                                    color: Colors.orange[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${provider.guestsTodayCount}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const Text('personas confirmadas',
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha Seleccionada',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(provider.selectedDate,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            Text(
                                '${provider.filteredReservations.length} reservaciones',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[500],
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // BARRA DE BÚSQUEDA
                TextField(
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre del cliente...',
                  ),
                  onChanged: (v) => provider.setSearchTerm(v),
                ),
                const SizedBox(height: 16),

                // LISTA DE RESERVACIONES
                Expanded(
                  child: provider.filteredReservations.isEmpty
                      ? const EmptyState(
                          message: 'No hay reservaciones para esta fecha',
                          icon: Icons.inbox_outlined)
                      : ListView.separated(
                          itemCount: provider.paginatedReservations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final res = provider.paginatedReservations[index];
                            return _buildReservationRow(context, res, provider,
                                textColor, cardBg, isDark);
                          },
                        ),
                ),

                // PAGINACIÓN
                if (provider.totalPages > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: provider.currentPage == 1
                            ? null
                            : () => provider.goToPage(provider.currentPage - 1),
                        child: const Text('← Anterior'),
                      ),
                      Text(
                          'Página ${provider.currentPage} de ${provider.totalPages}',
                          style: TextStyle(color: textColor)),
                      ElevatedButton(
                        onPressed: provider.currentPage == provider.totalPages
                            ? null
                            : () => provider.goToPage(provider.currentPage + 1),
                        child: const Text('Siguiente →'),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),

          // FORMULARIO EMERGENTE MODAL
          if (provider.showModal) ...[
            Container(color: Colors.black45),
            Center(
              child:
                  _buildReservationModal(context, provider, textColor, cardBg),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildReservationRow(
      BuildContext context,
      Reservacion res,
      ReservacionesProvider provider,
      Color textColor,
      Color cardBg,
      bool isDark) {
    Color chipColor = Colors.green;
    if (res.estado == 'cancelada') chipColor = Colors.red;
    if (res.estado == 'completada') chipColor = Colors.blue;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(res.id,
                          style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(res.cliente,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(res.estado.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: chipColor,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people,
                        size: 14, color: isDark ? Colors.white38 : Colors.grey),
                    const SizedBox(width: 4),
                    Text('${res.personas} persona(s)  |  ',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                    Icon(Icons.access_time,
                        size: 14, color: isDark ? Colors.white38 : Colors.grey),
                    const SizedBox(width: 4),
                    Text('${res.hora}  |  ',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                    Icon(Icons.phone,
                        size: 14, color: isDark ? Colors.white38 : Colors.grey),
                    const SizedBox(width: 4),
                    Text(res.telefono,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Mesa/Área Asignada: ${res.mesa}',
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.orange[400])),
              ],
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                onPressed: res.estado == 'completada'
                    ? null
                    : () => provider.abrirEditarModal(res),
              ),
              TextButton.icon(
                icon: const Icon(Icons.block, size: 16, color: Colors.red),
                label:
                    const Text('Cancelar', style: TextStyle(color: Colors.red)),
                onPressed: res.estado != 'confirmada'
                    ? null
                    : () => provider.cancelarReservacion(res.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => provider.eliminarReservacion(res.id),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReservationModal(BuildContext context,
      ReservacionesProvider provider, Color textColor, Color cardBg) {
    return Container(
      width: 460,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    provider.editingId != null
                        ? 'Editar Reservación'
                        : 'Nueva Reservación',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => provider.cerrarModal()),
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
            const SizedBox(height: 16),
            TextFormField(
              initialValue: provider.formValues['cliente'],
              style: TextStyle(color: textColor),
              decoration:
                  const InputDecoration(labelText: 'Nombre del Cliente'),
              onChanged: (v) => provider.updateFormField('cliente', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: provider.formValues['telefono'],
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Teléfono'),
              onChanged: (v) => provider.updateFormField('telefono', v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: provider.formValues['personas'].toString(),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nº Personas'),
                    onChanged: (v) => provider.updateFormField(
                        'personas', int.tryParse(v) ?? 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: provider.formValues['fecha'],
                    style: TextStyle(color: textColor),
                    decoration:
                        const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
                    onChanged: (v) => provider.updateFormField('fecha', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: provider.formValues['hora'],
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Hora (HH:MM)'),
              onChanged: (v) => provider.updateFormField('hora', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: provider.formValues['mesa'],
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Mesa / Notas'),
              onChanged: (v) => provider.updateFormField('mesa', v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (!mounted) return;
                  final success = await provider.guardarReservacion();
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Reservación procesada exitosamente'),
                          backgroundColor: Colors.green),
                    );
                  }
                },
                child: Text(
                    provider.editingId != null
                        ? 'Actualizar Reservación'
                        : 'Guardar Reservación',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
