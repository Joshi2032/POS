import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ajustes_provider.dart';

class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AjustesProvider(),
      child: const _AjustesView(),
    );
  }
}

class _AjustesView extends StatelessWidget {
  const _AjustesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AjustesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información del Negocio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: provider.nombreController, decoration: const InputDecoration(labelText: 'Nombre del Negocio')),
            const SizedBox(height: 8),
            TextField(controller: provider.rfcController, decoration: const InputDecoration(labelText: 'RFC')),
            const SizedBox(height: 8),
            TextField(controller: provider.direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
            const SizedBox(height: 8),
            TextField(controller: provider.telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
            const SizedBox(height: 24),
            Text('Notificaciones', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
                value: provider.alertaStock,
                onChanged: provider.toggleAlertaStock,
                title: const Text('Alerta de stock bajo')),
            SwitchListTile(
                value: provider.resumenDiario,
                onChanged: provider.toggleResumenDiario,
                title: const Text('Resumen diario')),
            SwitchListTile(
                value: provider.nuevasOrdenes,
                onChanged: provider.toggleNuevasOrdenes,
                title: const Text('Nuevas órdenes')),
            const SizedBox(height: 24),
            Text('Seguridad', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: provider.pinController,
              decoration: InputDecoration(
                labelText: 'PIN de seguridad',
                suffixIcon: IconButton(
                    icon: Icon(provider.showPin ? Icons.visibility_off : Icons.visibility),
                    onPressed: provider.toggleShowPin),
              ),
              obscureText: !provider.showPin,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
                value: provider.cierreAutomatico,
                onChanged: provider.toggleCierreAutomatico,
                title: const Text('Cierre automático')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.saveStatus == 'saving' ? null : provider.guardarCambios,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: provider.saveStatus == 'saving'
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : provider.saveStatus == 'success'
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check), SizedBox(width: 8), Text('Guardado')])
                          : const Text('Guardar Cambios'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}