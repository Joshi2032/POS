import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ReservacionesPage extends StatefulWidget {
  const ReservacionesPage({super.key});

  @override
  State<ReservacionesPage> createState() => _ReservacionesPageState();
}

class _ReservacionesPageState extends State<ReservacionesPage> {
  String search = '';

  void openEditor({Map<String, dynamic>? reservacion}) {
    final idController = TextEditingController(
        text:
            reservacion?['id'] ?? 'R-${DateTime.now().millisecondsSinceEpoch}');
    final clienteController =
        TextEditingController(text: reservacion?['cliente'] ?? '');
    final telefonoController =
        TextEditingController(text: reservacion?['telefono'] ?? '');
    final fechaController =
        TextEditingController(text: reservacion?['fecha'] ?? '');
    final horaController =
        TextEditingController(text: reservacion?['hora'] ?? '');
    final personasController = TextEditingController(
        text: reservacion?['personas']?.toString() ?? '2');
    final mesaController =
        TextEditingController(text: reservacion?['mesa'] ?? '');
    String estado = reservacion?['estado'] ?? 'Pendiente';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(reservacion == null
                  ? 'Agregar Reservación'
                  : 'Editar Reservación'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID')),
                    TextField(
                        controller: clienteController,
                        decoration:
                            const InputDecoration(labelText: 'Cliente')),
                    TextField(
                        controller: telefonoController,
                        decoration:
                            const InputDecoration(labelText: 'Teléfono')),
                    TextField(
                        controller: fechaController,
                        decoration: const InputDecoration(labelText: 'Fecha')),
                    TextField(
                        controller: horaController,
                        decoration: const InputDecoration(labelText: 'Hora')),
                    TextField(
                        controller: personasController,
                        decoration:
                            const InputDecoration(labelText: 'Personas'),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: mesaController,
                        decoration: const InputDecoration(labelText: 'Mesa')),
                    DropdownButtonFormField<String>(
                      initialValue: estado,
                      items: const [
                        DropdownMenuItem(
                            value: 'Pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(
                            value: 'Confirmada', child: Text('Confirmada')),
                        DropdownMenuItem(
                            value: 'Cancelada', child: Text('Cancelada')),
                        DropdownMenuItem(
                            value: 'Completada', child: Text('Completada')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => estado = value ?? 'Pendiente'),
                      decoration: const InputDecoration(labelText: 'Estado'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final app = context.read<AppState>();
                    final data = {
                      'id': idController.text,
                      'cliente': clienteController.text,
                      'telefono': telefonoController.text,
                      'fecha': fechaController.text,
                      'hora': horaController.text,
                      'personas': int.tryParse(personasController.text) ?? 2,
                      'mesa': mesaController.text,
                      'estado': estado,
                    };

                    if (reservacion == null) {
                      app.addReservacion(data);
                    } else {
                      app.updateReservacion(reservacion['id'], data);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
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
    final app = context.watch<AppState>();
    final items = app.reservaciones.where((r) {
      if (search.isEmpty) return true;
      final query = search.toLowerCase();
      return [r['cliente'], r['telefono'], r['fecha'], r['mesa'], r['estado']]
          .whereType<String>()
          .any((v) => v.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reservaciones')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar reservaciones'),
              onChanged: (value) => setState(() => search = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No hay reservaciones'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text('${item['cliente']} · ${item['mesa']}'),
                          subtitle: Text(
                              '${item['fecha']} ${item['hora']} · ${item['personas']} personas · ${item['estado']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      openEditor(reservacion: item)),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => app
                                      .removeReservacion(item['id'] as String)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
