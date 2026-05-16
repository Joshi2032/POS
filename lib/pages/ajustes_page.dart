import 'package:flutter/material.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final nombreController =
      TextEditingController(text: 'La Brasa — Parrilla & Grill');
  final rfcController = TextEditingController(text: 'XAXX010101000');
  final direccionController =
      TextEditingController(text: 'Av. Reforma 123, CDMX');
  final telefonoController = TextEditingController(text: '+52 55 1234 5678');
  final pinController = TextEditingController(text: '1234');

  bool alertaStock = true;
  bool resumenDiario = true;
  bool nuevasOrdenes = true;
  bool cierreAutomatico = true;
  bool showPin = false;
  String saveStatus = 'idle'; // idle | saving | success

  void _save() {
    setState(() => saveStatus = 'saving');
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => saveStatus = 'success');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => saveStatus = 'idle');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información del Negocio',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: nombreController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Negocio')),
            const SizedBox(height: 8),
            TextField(
                controller: rfcController,
                decoration: const InputDecoration(labelText: 'RFC')),
            const SizedBox(height: 8),
            TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Dirección')),
            const SizedBox(height: 8),
            TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono')),
            const SizedBox(height: 24),
            Text('Notificaciones',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
                value: alertaStock,
                onChanged: (v) => setState(() => alertaStock = v),
                title: const Text('Alerta de stock bajo')),
            SwitchListTile(
                value: resumenDiario,
                onChanged: (v) => setState(() => resumenDiario = v),
                title: const Text('Resumen diario')),
            SwitchListTile(
                value: nuevasOrdenes,
                onChanged: (v) => setState(() => nuevasOrdenes = v),
                title: const Text('Nuevas órdenes')),
            const SizedBox(height: 24),
            Text('Seguridad', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: 'PIN de seguridad',
                suffixIcon: IconButton(
                    icon:
                        Icon(showPin ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showPin = !showPin)),
              ),
              obscureText: !showPin,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
                value: cierreAutomatico,
                onChanged: (v) => setState(() => cierreAutomatico = v),
                title: const Text('Cierre automático')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveStatus == 'saving' ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: saveStatus == 'saving'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : saveStatus == 'success'
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.check),
                                  SizedBox(width: 8),
                                  Text('Guardado')
                                ])
                          : const Text('Guardar Cambios'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    rfcController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    pinController.dispose();
    super.dispose();
  }
}
