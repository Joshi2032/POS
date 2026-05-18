import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reservaciones_provider.dart';
import '../utils/ui_utils.dart'; // Asegúrate de tener tu utilidad de alertas

class ReservacionesPage extends StatelessWidget {
  const ReservacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReservacionesProvider(),
      child: const _ReservacionesView(),
    );
  }
}

class _ReservacionesView extends StatefulWidget {
  const _ReservacionesView();

  @override
  State<_ReservacionesView> createState() => _ReservacionesViewState();
}

class _ReservacionesViewState extends State<_ReservacionesView> {
  final List<String> filtrosEstado = [
    'Todos',
    'Pendiente',
    'Confirmada',
    'Completada',
    'Cancelada'
  ];

  bool showModal = false;
  String? editingId;
  String modalError = '';

  late ReservacionForm formState;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  void _resetForm() {
    formState = ReservacionForm(
      customerName: '',
      date: DateTime.now().toIso8601String().substring(0, 10),
      time: '14:00',
      guests: 2,
      table: 'Por asignar',
      status: 'Pendiente',
      notes: '',
    );
    modalError = '';
  }

  void abrirModal() {
    setState(() {
      editingId = null;
      _resetForm();
      showModal = true;
    });
  }

  void abrirEditar(Reservacion r) {
    setState(() {
      editingId = r.id;
      modalError = '';
      formState = ReservacionForm(
        customerName: r.customerName,
        date: r.date,
        time: r.time,
        guests: r.guests,
        table: r.table,
        status: r.status,
        notes: r.notes,
      );
      showModal = true;
    });
  }

  void cerrarModal() {
    setState(() {
      showModal = false;
      editingId = null;
    });
  }

  void guardarReservacion(ReservacionesProvider provider) {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (formState.customerName.trim().isEmpty ||
        formState.date.trim().isEmpty ||
        formState.guests <= 0) {
      setState(() => modalError = 'Completa nombre, fecha y personas válidas.');
      return;
    }

    if (editingId != null) {
      UiUtils.showConfirmDialog(context, 'Actualizar Reservación',
          '¿Actualizar a ${formState.customerName}?', () {
        provider.actualizarReservacion(editingId!, formState);
        UiUtils.showToast(context, 'Reservación actualizada',
            color: Colors.green);
        cerrarModal();
      });
    } else {
      UiUtils.showConfirmDialog(context, 'Crear Reservación',
          '¿Registrar a ${formState.customerName}?', () {
        provider.crearReservacion(formState);
        UiUtils.showToast(context, 'Reservación registrada',
            color: Colors.green);
        cerrarModal();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'Confirmada':
        return Colors.blue;
      case 'Completada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final provider = context.watch<ReservacionesProvider>();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABECERA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📅 ', style: TextStyle(fontSize: 26)),
                              Text('Reservaciones',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('Gestión de mesas y agendamientos',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        onPressed: abrirModal,
                        child: const Text('+ Nueva Reservación'),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),

                  // BÚSQUEDA
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, ID o mesa...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: provider.onSearch,
                  ),
                  const SizedBox(height: 25),

                  // KPIS
                  GridView.count(
                    crossAxisCount: isDesktop ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 3.0 : 4.0,
                    children: [
                      _buildStatCard('Para Hoy', '${provider.paraHoyCount}',
                          Icons.today, Colors.blueGrey.shade800),
                      _buildStatCard(
                          'Pendientes',
                          '${provider.pendientesCount}',
                          Icons.pending_actions,
                          Colors.orange.shade900),
                      _buildStatCard(
                          'Confirmadas',
                          '${provider.confirmadasCount}',
                          Icons.check_circle_outline,
                          Colors.green.shade900),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // FILTROS TIPO PILL
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filtrosEstado.map((estado) {
                      final isActive = provider.selectedStatus == estado;
                      return ChoiceChip(
                        label: Text(estado),
                        selected: isActive,
                        onSelected: (_) => provider.filterByStatus(estado),
                        selectedColor:
                            Theme.of(context).primaryColor.withAlpha(50),
                        labelStyle: TextStyle(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade700,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // TABLA DE DATOS
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest),
                          columns: const [
                            DataColumn(
                                label: Text('Fecha y Hora',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Cliente',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Personas',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Mesa',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Estado',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Acciones',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: provider.paginatedReservaciones.map((r) {
                            return DataRow(cells: [
                              DataCell(Text('${r.date} - ${r.time}')),
                              DataCell(Text(r.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text('${r.guests} pax')),
                              DataCell(Text(r.table)),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color:
                                        _getStatusColor(r.status).withAlpha(40),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(r.status,
                                    style: TextStyle(
                                        color: _getStatusColor(r.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                      onPressed: () => abrirEditar(r),
                                      child: const Text('Editar')),
                                  if (r.status == 'Pendiente')
                                    TextButton(
                                        onPressed: () => provider.cambiarEstado(
                                            r.id, 'Confirmada'),
                                        child: const Text('Confirmar',
                                            style: TextStyle(
                                                color: Colors.green))),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  if (provider.paginatedReservaciones.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(32),
                      child: const Text('No hay reservaciones',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  const SizedBox(height: 15),

                  // PAGINACIÓN
                  if (provider.totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: provider.currentPage == 1
                              ? null
                              : () =>
                                  provider.changePage(provider.currentPage - 1),
                        ),
                        Text(
                            'Página ${provider.currentPage} de ${provider.totalPages}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: provider.currentPage == provider.totalPages
                              ? null
                              : () =>
                                  provider.changePage(provider.currentPage + 1),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),

          // MODAL FLOTANTE DE FORMULARIO
          if (showModal) ...[
            GestureDetector(
              onTap: cerrarModal,
              child: Container(color: Colors.black54),
            ),
            Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: isDesktop ? 500 : double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  editingId != null
                                      ? 'Editar Reservación'
                                      : 'Nueva Reservación',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: cerrarModal),
                            ],
                          ),
                          const Divider(),
                          if (modalError.isNotEmpty) ...[
                            Text(modalError,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                          ],
                          _buildFormFields(),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                  onPressed: cerrarModal,
                                  child: const Text('Cancelar')),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white),
                                onPressed: () => guardarReservacion(provider),
                                child: const Text('Guardar'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: formState.customerName,
          decoration: const InputDecoration(
              labelText: 'Nombre del Cliente', border: OutlineInputBorder()),
          onChanged: (val) => formState.customerName = val,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: formState.date,
                decoration: const InputDecoration(
                    labelText: 'Fecha (YYYY-MM-DD)',
                    border: OutlineInputBorder()),
                onChanged: (val) => formState.date = val,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: formState.time,
                decoration: const InputDecoration(
                    labelText: 'Hora (HH:MM)', border: OutlineInputBorder()),
                onChanged: (val) => formState.time = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: formState.guests.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Personas', border: OutlineInputBorder()),
                onChanged: (val) => formState.guests = int.tryParse(val) ?? 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: formState.status,
                decoration: const InputDecoration(
                    labelText: 'Estado', border: OutlineInputBorder()),
                items: ['Pendiente', 'Confirmada', 'Completada', 'Cancelada']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => formState.status = val ?? 'Pendiente'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.table,
          decoration: const InputDecoration(
              labelText: 'Mesa Asignada', border: OutlineInputBorder()),
          onChanged: (val) => formState.table = val,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: formState.notes,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Notas / Peticiones', border: OutlineInputBorder()),
          onChanged: (val) => formState.notes = val,
        ),
      ],
    );
  }
}
