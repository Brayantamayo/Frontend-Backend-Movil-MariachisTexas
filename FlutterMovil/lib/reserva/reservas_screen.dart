import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_controller.dart';
import 'reserva_detalle_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _search = TextEditingController();
  late ReservaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ReservaController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cargar();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _controller.buscar(query);
  }

  Future<void> _showDetalle(Reserva r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservaDetalleScreen(reservaId: r.id),
      ),
    );
  }

  Future<void> _confirmAnular(Reserva r) async {
    if (r.estadoEnum == EstadoReserva.anulada) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular Reserva'),
        content: Text(
          '¿Estás seguro de anular la reserva #${r.id}?\n\n'
          'Cliente: ${r.clienteNombre}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await _controller.anular(r.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reserva anulada exitosamente' : _controller.errorMsg,
          ),
          backgroundColor: success ? Colors.orange : AppColors.primary,
        ),
      );
    }
  }

  Future<void> _showAbono(Reserva r) async {
    if (r.estadoEnum == EstadoReserva.anulada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede registrar abono en una reserva anulada'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final pagado = r.totalValor - r.saldoPendiente;
    final esPrimerAbono = pagado == 0;
    final anticipo50 = (r.totalValor / 2).ceilToDouble();
    final saldo = r.saldoPendiente;

    // Si ya pagó el 50%, solo puede pagar el saldo restante
    // Si es el primer abono, puede elegir 50% o 100%
    double? montoSeleccionado;
    String metodo = 'EFECTIVO';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Registrar Abono'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen financiero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _abonoInfoRow('Total', formatCop(r.totalValor.round())),
                    if (!esPrimerAbono)
                      _abonoInfoRow('Pagado', formatCop(pagado.round()),
                          color: const Color(0xFF047857)),
                    _abonoInfoRow(
                      'Saldo pendiente',
                      formatCop(saldo.round()),
                      color: const Color(0xFFB91C1C),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Opciones de monto
              if (esPrimerAbono) ...[
                const Text(
                  'Selecciona el monto a pagar:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _montoBtn(
                        label: '50%',
                        sublabel: formatCop(anticipo50.round()),
                        selected: montoSeleccionado == anticipo50,
                        onTap: () => setS(() => montoSeleccionado = anticipo50),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _montoBtn(
                        label: '100%',
                        sublabel: formatCop(saldo.round()),
                        selected: montoSeleccionado == saldo,
                        onTap: () => setS(() => montoSeleccionado = saldo),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Monto a pagar (saldo restante):',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _montoBtn(
                  label: '100% restante',
                  sublabel: formatCop(saldo.round()),
                  selected: true,
                  onTap: () => setS(() => montoSeleccionado = saldo),
                ),
              ],
              const SizedBox(height: 16),
              // Método de pago
              DropdownButtonFormField<String>(
                initialValue: metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'EFECTIVO',      child: Text('Efectivo')),
                  DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'NEQUI',         child: Text('Nequi')),
                  DropdownMenuItem(value: 'DAVIPLATA',     child: Text('Daviplata')),
                  DropdownMenuItem(value: 'OTRO',          child: Text('Otro')),
                ],
                onChanged: (v) => setS(() => metodo = v ?? 'EFECTIVO'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: (montoSeleccionado != null || !esPrimerAbono)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final monto = esPrimerAbono ? montoSeleccionado! : saldo;

    final success = await _controller.registrarAbono(
      r.id,
      monto: monto,
      metodoPago: metodo,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Abono registrado exitosamente' : _controller.errorMsg,
          ),
          backgroundColor: success ? Colors.green : AppColors.primary,
        ),
      );
    }
  }

  // ── Helpers para el diálogo de abono ──────────────────────────────────────

  static Widget _abonoInfoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _montoBtn({
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: selected ? AppColors.primary : AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservaController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar reserva...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 14),
                Expanded(child: _buildContent(controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ReservaController controller) {
    return switch (controller.status) {
      ReservaStatus.inicial => const Center(
          child: Text('Presiona el botón para cargar reservas'),
        ),
      ReservaStatus.cargando => const Center(
          child: CircularProgressIndicator(),
        ),
      ReservaStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ReservaStatus.listo => controller.reservas.isEmpty
          ? const Center(child: Text('No se encontraron reservas.'))
          : ListView.separated(
              itemCount: controller.reservas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ReservaCard(
                r: controller.reservas[i],
                onDetalle: () => _showDetalle(controller.reservas[i]),
                onAnular: controller.reservas[i].estadoEnum != EstadoReserva.anulada
                    ? () => _confirmAnular(controller.reservas[i])
                    : null,
                onAbono: controller.reservas[i].estadoEnum != EstadoReserva.anulada
                    ? () => _showAbono(controller.reservas[i])
                    : null,
              ),
            ),
    };
  }
}

// ─── CARD ─────────────────────────────────────────────────────────────────────

class _ReservaCard extends StatelessWidget {
  final Reserva r;
  final VoidCallback onDetalle;
  final VoidCallback? onAnular;
  final VoidCallback? onAbono;

  const _ReservaCard({
    required this.r,
    required this.onDetalle,
    required this.onAnular,
    required this.onAbono,
  });

  Color _pillBg() => switch (r.estadoEnum) {
        EstadoReserva.pendiente  => const Color(0xFFFEF3C7),
        EstadoReserva.confirmada => const Color(0xFFDCFCE7),
        EstadoReserva.anulada    => const Color(0xFFFEE2E2),
        EstadoReserva.finalizado => const Color(0xFFDBEAFE),
      };

  Color _pillFg() => switch (r.estadoEnum) {
        EstadoReserva.pendiente  => const Color(0xFFB45309),
        EstadoReserva.confirmada => const Color(0xFF047857),
        EstadoReserva.anulada    => const Color(0xFFB91C1C),
        EstadoReserva.finalizado => const Color(0xFF1D4ED8),
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado: ID + tipo evento + estado + menú ───────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${r.id}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tipoLabel(r.tipoEvento),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.clienteNombre,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      if (r.homenajeado.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Para: ${r.homenajeado}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pillBg(),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    r.estadoLabel,
                    style: TextStyle(
                      color: _pillFg(),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'detalle',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ver Detalle'),
                        ],
                      ),
                    ),
                    if (onAbono != null)
                      const PopupMenuItem(
                        value: 'abono',
                        child: Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Registrar Abono'),
                          ],
                        ),
                      ),
                    if (onAnular != null) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'anular',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Anular',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'detalle':
                        onDetalle();
                      case 'abono':
                        onAbono?.call();
                      case 'anular':
                        onAnular?.call();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Info: fecha, horario, lugar ────────────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(
                  Icons.calendar_month_outlined,
                  '${r.fechaEvento.day}/${r.fechaEvento.month}/${r.fechaEvento.year}',
                ),
                _info(Icons.schedule, '${r.horaInicio} - ${r.horaFin}'),
                _info(Icons.place_outlined, r.ubicacion),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Resumen financiero ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valor Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCop(r.totalValor.round()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCop(r.saldoPendiente.round()),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: r.saldoPendiente > 0
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _tipoLabel(String tipo) {
    const map = {
      'BODA': 'Boda',
      'CUMPLEANOS': 'Cumpleaños',
      'QUINCEANIOS': 'Quinceaños',
      'FUNERAL': 'Funeral',
      'RECONCILIACION': 'Reconciliación',
      'DIA_DE_MADRE': 'Día de la Madre',
      'AMOR': 'Amor',
      'ANIVERSARIO': 'Aniversario',
      'PADRES': 'Día del Padre',
      'FIESTA': 'Fiesta',
      'OTRO': 'Otro',
    };
    return map[tipo] ?? tipo;
  }

  static Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }
}
