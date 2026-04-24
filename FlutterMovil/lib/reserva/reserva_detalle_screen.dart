import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_controller.dart';

class ReservaDetalleScreen extends StatefulWidget {
  final int reservaId;

  const ReservaDetalleScreen({
    super.key,
    required this.reservaId,
  });

  @override
  State<ReservaDetalleScreen> createState() => _ReservaDetalleScreenState();
}

class _ReservaDetalleScreenState extends State<ReservaDetalleScreen> {
  Reserva? _reserva;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final controller = context.read<ReservaController>();
    final reserva = await controller.getDetalle(widget.reservaId);

    setState(() {
      _loading = false;
      if (reserva != null) {
        _reserva = reserva;
      } else {
        _error = controller.errorMsg.isNotEmpty
            ? controller.errorMsg
            : 'Error al cargar el detalle';
      }
    });
  }

  Future<void> _confirmAnular() async {
    if (_reserva == null) return;
    if (_reserva!.estadoEnum == EstadoReserva.anulada) return;

    final controller = context.read<ReservaController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular Reserva'),
        content: Text(
          '¿Estás seguro de anular la reserva #${_reserva!.id}?\n\n'
          'Cliente: ${_reserva!.clienteNombre}',
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

    final success = await controller.anular(_reserva!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reserva anulada exitosamente' : controller.errorMsg,
          ),
          backgroundColor: success ? Colors.orange : AppColors.primary,
        ),
      );
      if (success) _cargarDetalle();
    }
  }

  Future<void> _showAbono() async {
    if (_reserva == null) return;
    if (_reserva!.estadoEnum == EstadoReserva.anulada) return;

    final controller = context.read<ReservaController>();
    final r = _reserva!;
    final pagado = r.totalValor - r.saldoPendiente;
    final esPrimerAbono = pagado == 0;
    final anticipo50 = (r.totalValor / 2).ceilToDouble();
    final saldo = r.saldoPendiente;

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
                  onTap: () {},
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

    final success = await controller.registrarAbono(
      r.id,
      monto: monto,
      metodoPago: metodo,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Abono registrado exitosamente' : controller.errorMsg,
          ),
          backgroundColor: success ? Colors.green : AppColors.primary,
        ),
      );
      if (success) _cargarDetalle();
    }
  }

  // ── Helpers para el diálogo ────────────────────────────────────────────────

  static Widget _abonoInfoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          _reserva != null ? 'Reserva #${_reserva!.id}' : 'Detalle de Reserva',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_reserva != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) => [
                if (_reserva!.estadoEnum != EstadoReserva.anulada)
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
                if (_reserva!.estadoEnum != EstadoReserva.anulada) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'anular',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Anular', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ],
              onSelected: (v) {
                if (v == 'abono') _showAbono();
                if (v == 'anular') _confirmAnular();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _cargarDetalle,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_reserva == null) {
      return const Center(child: Text('Reserva no encontrada'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildContacto(),
          const SizedBox(height: 16),
          _buildFinanciero(),
          if (_reserva!.abonos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAbonos(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final r = _reserva!;
    final estadoColor = _estadoColor(r.estadoEnum);
    final estadoBg = _estadoBg(r.estadoEnum);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tipoLabel(r.tipoEvento),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      if (r.homenajeado.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Para: ${r.homenajeado}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: estadoColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    r.estadoLabel,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow(Icons.person_outline, 'Cliente', r.clienteNombre),
            const SizedBox(height: 8),
            _infoRow(
              Icons.calendar_month_outlined,
              'Fecha del Evento',
              '${r.fechaEvento.day}/${r.fechaEvento.month}/${r.fechaEvento.year}',
            ),
            const SizedBox(height: 8),
            _infoRow(
                Icons.schedule, 'Horario', '${r.horaInicio} - ${r.horaFin}'),
            const SizedBox(height: 8),
            _infoRow(Icons.place_outlined, 'Lugar', r.ubicacion),
          ],
        ),
      ),
    );
  }

  Widget _buildContacto() {
    final r = _reserva!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _detailItem('Nombre', r.clienteNombre),
            const SizedBox(height: 8),
            _detailItem('Email', r.clienteEmail),
            const SizedBox(height: 8),
            _detailItem('Teléfono', r.clienteTelefono),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanciero() {
    final r = _reserva!;
    final pagado = r.totalValor - r.saldoPendiente;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen Financiero',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'VALOR TOTAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCop(r.totalValor.round()),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    'Pagado',
                    formatCop(pagado.round()),
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCop(r.saldoPendiente.round()),
                        style: TextStyle(
                          fontSize: 15,
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

  Widget _buildAbonos() {
    final r = _reserva!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abonos (${r.abonos.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ...r.abonos.asMap().entries.map(
              (entry) {
                final i = entry.key + 1;
                final a = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$i',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.metodoPago,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${a.fechaPago.day}/${a.fechaPago.month}/${a.fechaPago.year}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCop(a.monto.round()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
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

  static Color _estadoColor(EstadoReserva e) => switch (e) {
        EstadoReserva.pendiente  => const Color(0xFFB45309),
        EstadoReserva.confirmada => const Color(0xFF047857),
        EstadoReserva.anulada    => const Color(0xFFB91C1C),
        EstadoReserva.finalizado => const Color(0xFF1D4ED8),
      };

  static Color _estadoBg(EstadoReserva e) => switch (e) {
        EstadoReserva.pendiente  => const Color(0xFFFEF3C7),
        EstadoReserva.confirmada => const Color(0xFFDCFCE7),
        EstadoReserva.anulada    => const Color(0xFFFEE2E2),
        EstadoReserva.finalizado => const Color(0xFFDBEAFE),
      };
}
