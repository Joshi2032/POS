import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/provider_payment.dart';
import '../providers/provider_payment.dart';
import '../providers/inventario_provider.dart';
import '../widgets/app_widgets.dart';

class ProveedoresPage extends StatelessWidget {
  const ProveedoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProveedoresView();
  }
}

class _ProveedoresView extends StatefulWidget {
  const _ProveedoresView();

  @override
  State<_ProveedoresView> createState() => _ProveedoresViewState();
}

class _ProveedoresViewState extends State<_ProveedoresView> {
  final _money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  void _openEditor(PaymentsProvider provider, {ProviderPayment? payment}) {
    final todayIso = DateTime.now().toIso8601String().split('T').first;
    final idCtrl = TextEditingController(
        text: payment?.id ?? 'PAG-${DateTime.now().millisecondsSinceEpoch}');
    final providerCtrl =
        TextEditingController(text: payment?.provider ?? '');
    final categoryCtrl =
        TextEditingController(text: payment?.category ?? '');
    final amountCtrl =
        TextEditingController(text: payment?.amount.toString() ?? '0');
    final dateCtrl =
        TextEditingController(text: payment?.date ?? todayIso);
    final timeCtrl =
        TextEditingController(text: payment?.time ?? '09:00 a.m.');
    final cashierCtrl =
        TextEditingController(text: payment?.cashier ?? 'Laura S.');
    String method = payment?.method ?? 'Transferencia';
    bool saving = false;

    final w = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            // Diálogo casi full-width en móvil
            insetPadding: EdgeInsets.symmetric(
              horizontal: w < 480 ? 12 : 40,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text(
              payment == null ? 'Nuevo Pago' : 'Editar Pago',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: w < 480 ? double.infinity : 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogField(ctrl: idCtrl, label: 'ID', readOnly: true),
                    const SizedBox(height: 12),
                    _DialogField(ctrl: providerCtrl, label: 'Proveedor'),
                    const SizedBox(height: 12),
                    _DialogField(ctrl: categoryCtrl, label: 'Concepto'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(ctx).cardColor,
                      initialValue: method,
                      items: const [
                        DropdownMenuItem(
                            value: 'Transferencia',
                            child: Text('Transferencia')),
                        DropdownMenuItem(
                            value: 'Efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(
                            value: 'Tarjeta', child: Text('Tarjeta')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => method = v ?? 'Transferencia'),
                      decoration: const InputDecoration(
                          labelText: 'Método',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    _DialogField(
                      ctrl: amountCtrl,
                      label: 'Monto',
                      prefixText: '\$ ',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // Fecha + Hora en fila cuando hay espacio
                    w < 400
                        ? Column(children: [
                            _DialogField(ctrl: dateCtrl, label: 'Fecha'),
                            const SizedBox(height: 12),
                            _DialogField(ctrl: timeCtrl, label: 'Hora'),
                          ])
                        : Row(children: [
                            Expanded(
                                child: _DialogField(
                                    ctrl: dateCtrl, label: 'Fecha')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _DialogField(
                                    ctrl: timeCtrl, label: 'Hora')),
                          ]),
                    const SizedBox(height: 12),
                    _DialogField(ctrl: cashierCtrl, label: 'Cajero'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final data = ProviderPayment(
                          id: idCtrl.text,
                          provider: providerCtrl.text.trim(),
                          category: categoryCtrl.text.trim(),
                          method: method,
                          amount: double.tryParse(amountCtrl.text) ?? 0.0,
                          date: dateCtrl.text,
                          time: timeCtrl.text,
                          cashier: cashierCtrl.text,
                        );

                        if (data.provider.isEmpty ||
                            data.category.isEmpty ||
                            data.amount <= 0) {
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);

                        setDialogState(() => saving = true);

                        bool exito;
                        if (payment == null) {
                          final inv = Provider.of<InventarioProvider>(ctx,
                              listen: false);
                          exito = await provider.addPayment(data, inv);
                        } else {
                          exito =
                              await provider.updatePayment(payment.id, data);
                        }

                        if (!ctx.mounted) return;

                        if (exito) {
                          Navigator.pop(ctx);
                        } else {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.errorMessage ??
                                    'No se pudo guardar el pago.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).primaryColor,
                    foregroundColor: Colors.white),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentsProvider>();
    final paginated = provider.paginatedPayments;
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPad = w < 480 ? 16.0 : 24.0;
            final isCompact = w < 600;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── HEADER ──────────────────────────────────────
                      if (isCompact) ...[
                        SectionHeader(
                          title: '📦 Control de Proveedores',
                          subtitle:
                              'Historial de pagos y liquidación de insumos',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo Pago',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openEditor(provider),
                          ),
                        ),
                      ] else ...[
                        SectionHeader(
                          title: '📦 Control de Proveedores',
                          subtitle:
                              'Historial de pagos y liquidación de insumos',
                          actionLabel: 'Nuevo Pago',
                          onAction: () => _openEditor(provider),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── BUSCADOR ────────────────────────────────────
                      TextField(
                        style: TextStyle(color: primaryTextColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText:
                              'Buscar por proveedor, concepto, método...',
                        ),
                        onChanged: provider.setSearch,
                      ),

                      const SizedBox(height: 20),

                      // ── STAT CARDS ──────────────────────────────────
                      // Grid adaptativo: 2 cols en móvil, 4 en escritorio
                      GridView(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isCompact ? 2 : 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // Altura fija por contenido, no ratio
                          childAspectRatio: isCompact ? 1.4 : 1.3,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatCard(
                            label: 'Pagos hoy',
                            value: _money.format(provider.todayTotal),
                            note:
                                '${provider.todayPaymentsCount} operaciones',
                            tone: Colors.deepOrange,
                          ),
                          _StatCard(
                            label: 'Total semana',
                            value: _money.format(provider.weekTotal),
                            note: 'Últimos 7 días',
                            tone: Colors.red,
                          ),
                          _StatCard(
                            label: 'Total mes',
                            value: _money.format(provider.monthTotal),
                            note: 'Mes en curso',
                            tone: Colors.green,
                          ),
                          _StatCard(
                            label: 'Proveedores',
                            value:
                                provider.uniqueProvidersCount.toString(),
                            note: 'Rastreados distintos',
                            tone: Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── CONTADOR ────────────────────────────────────
                      Text(
                        '${provider.filteredPayments.length} registro(s) encontrado(s)',
                        style:
                            Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      // ── LISTA ───────────────────────────────────────
                      if (paginated.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No hay pagos que coincidan con tu búsqueda.',
                              style: TextStyle(color: mutedTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginated.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.3),
                          ),
                          itemBuilder: (_, index) {
                            final payment = paginated[index];
                            return _PaymentTile(
                              payment: payment,
                              money: _money,
                              primaryTextColor: primaryTextColor,
                              mutedTextColor: mutedTextColor,
                              isCompact: isCompact,
                              onEdit: () =>
                                  _openEditor(provider, payment: payment),
                              onDelete: () =>
                                  provider.removePayment(payment.id),
                            );
                          },
                        ),

                      const SizedBox(height: 12),

                      // ── PAGINACIÓN ──────────────────────────────────
                      if (provider.totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: provider.currentPage > 1
                                    ? () => provider.goToPage(
                                        provider.currentPage - 1)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .dividerColor)),
                                child: Text(
                                    isCompact ? '← Ant.' : 'Anterior'),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Pág. ${provider.currentPage}/${provider.totalPages}',
                                style:
                                    TextStyle(color: primaryTextColor),
                              ),
                              const SizedBox(width: 14),
                              OutlinedButton(
                                onPressed: provider.currentPage <
                                        provider.totalPages
                                    ? () => provider.goToPage(
                                        provider.currentPage + 1)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .dividerColor)),
                                child: Text(
                                    isCompact ? 'Sig. →' : 'Siguiente'),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────────────────────

/// Campo de texto reutilizable para el diálogo
class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.ctrl,
    required this.label,
    this.readOnly = false,
    this.prefixText,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String label;
  final bool readOnly;
  final String? prefixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Tarjeta de estadística
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.tone,
  });
  final String label;
  final String value;
  final String note;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(note,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

/// Tile de un pago en la lista
class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.money,
    required this.primaryTextColor,
    required this.mutedTextColor,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
  });

  final ProviderPayment payment;
  final NumberFormat money;
  final Color primaryTextColor;
  final Color mutedTextColor;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initial = payment.provider.isNotEmpty
        ? payment.provider[0].toUpperCase()
        : '?';

    // En móvil: monto + acciones debajo de la info
    if (isCompact) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context)
                      .primaryColor
                      .withValues(alpha: 0.1),
                  child: Text(initial,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(payment.provider,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  money.format(payment.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: primaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                '${payment.category} · ${payment.method}\n${payment.date} ${payment.time} · ${payment.cashier}',
                style: TextStyle(color: mutedTextColor, fontSize: 11),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blueGrey, size: 18),
                  onPressed: onEdit,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Tablet / escritorio: layout original de ListTile
    return AppCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Text(initial,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(payment.provider,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: primaryTextColor)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${payment.category} · ${payment.method} · ${payment.date} ${payment.time}\nCajero: ${payment.cashier}',
            style: TextStyle(color: mutedTextColor),
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(money.format(payment.amount),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primaryTextColor)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.blueGrey, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}