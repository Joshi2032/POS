import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movimiento_caja_provider.dart';
import '../models/movimiento_caja.dart';
import '../utils/mexico_time.dart';
import '../widgets/app_widgets.dart';

class MovimientosCajaPage extends StatefulWidget {
  const MovimientosCajaPage({super.key});

  @override
  State<MovimientosCajaPage> createState() => _MovimientosCajaPageState();
}

class _MovimientosCajaPageState extends State<MovimientosCajaPage> {
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String _tipo = 'Ingreso';
  bool _guardando = false;
  late final String _hoy;

  @override
  void initState() {
    super.initState();
    _hoy = fechaHoyMexicoStr();
    Future.microtask(() {
      if (mounted) {
        context.read<MovimientoCajaProvider>().cargarMovimientosPorFecha(_hoy);
      }
    });
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarMovimiento() async {
    final concepto = _conceptoCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text.trim());

    if (concepto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un concepto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto numérico mayor a 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final movimientoProvider = context.read<MovimientoCajaProvider>();
    final exito = await movimientoProvider.agregarMovimiento(
      MovimientoCaja(
        id: '',
        concepto: concepto,
        tipo: _tipo,
        monto: monto,
        fecha: _hoy,
      ),
    );

    if (!mounted) return;

    setState(() => _guardando = false);

    if (exito) {
      _conceptoCtrl.clear();
      _montoCtrl.clear();
      await movimientoProvider.cargarMovimientosPorFecha(_hoy);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movimientoProvider.errorMessage ??
                'No se pudo registrar el movimiento.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Movimientos de Caja',
              subtitle: 'Ingresos y egresos manuales de hoy ($_hoy)',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final lista = _buildLista(context);
                  final formulario = _buildFormulario(context);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: lista),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: formulario),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 400, child: lista),
                        const SizedBox(height: 24),
                        formulario,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context) {
    return AppCard(
      child: Consumer<MovimientoCajaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los movimientos: '
                '${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.movimientos.isEmpty) {
            return const Center(
              child: Text('Sin movimientos registrados hoy.'),
            );
          }

          return ListView.separated(
            itemCount: provider.movimientos.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final m = provider.movimientos[index];
              final esIngreso = m.tipo == 'Ingreso';

              return ListTile(
                dense: true,
                title: Text(
                  m.concepto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(m.tipo),
                trailing: Text(
                  '${esIngreso ? '+' : '-'}\$${m.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: esIngreso ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Registrar movimiento manual',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Ingreso'),
                  selected: _tipo == 'Ingreso',
                  onSelected: (_) => setState(() => _tipo = 'Ingreso'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Egreso'),
                  selected: _tipo == 'Egreso',
                  onSelected: (_) => setState(() => _tipo = 'Egreso'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conceptoCtrl,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardarMovimiento,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }
}
