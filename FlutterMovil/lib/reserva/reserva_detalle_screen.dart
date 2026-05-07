import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'reserva_controller.dart';
import 'reserva_pdf.dart';

class ReservaDetalleScreen extends StatefulWidget {
  final int reservaId;
  const ReservaDetalleScreen({super.key, required this.reservaId});

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

  //  Abono
  Future<void> _showAbono() async {
    if (_reserva == null || _reserva!.estadoEnum == EstadoReserva.anulada)
      return;
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
                      _infoRow('Total', formatCop(r.totalValor.round())),
                      if (!esPrimerAbono)
                        _infoRow('Pagado', formatCop(pagado.round()),
                            color: const Color(0xFF047857)),
                      _infoRow('Saldo pendiente', formatCop(saldo.round()),
                          color: const Color(0xFFB91C1C), bold: true),
                    ]),
              ),
              const SizedBox(height: 16),
              if (esPrimerAbono) ...[
                const Text('Selecciona el monto a pagar:',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _montoBtn(
                          label: '50%',
                          sublabel: formatCop(anticipo50.round()),
                          selected: montoSeleccionado == anticipo50,
                          onTap: () =>
                              setS(() => montoSeleccionado = anticipo50))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _montoBtn(
                          label: '100%',
                          sublabel: formatCop(saldo.round()),
                          selected: montoSeleccionado == saldo,
                          onTap: () => setS(() => montoSeleccionado = saldo))),
                ]),
              ] else ...[
                const Text('Monto a pagar (saldo restante):',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textMuted)),
                const SizedBox(height: 10),
                _montoBtn(
                    label: '100% restante',
                    sublabel: formatCop(saldo.round()),
                    selected: true,
                    onTap: () {}),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: metodo,
                decoration: const InputDecoration(
                    labelText: 'Metodo de pago', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                  DropdownMenuItem(
                      value: 'TRANSFERENCIA', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'NEQUI', child: Text('Nequi')),
                  DropdownMenuItem(
                      value: 'DAVIPLATA', child: Text('Daviplata')),
                  DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                ],
                onChanged: (v) => setS(() => metodo = v ?? 'EFECTIVO'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
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
    final success =
        await controller.registrarAbono(r.id, monto: monto, metodoPago: metodo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Abono registrado exitosamente' : controller.errorMsg),
        backgroundColor: success ? Colors.green : AppColors.primary,
      ));
      if (success) _cargarDetalle();
    }
  }

  //  Anular
  Future<void> _confirmAnular() async {
    if (_reserva == null || _reserva!.estadoEnum == EstadoReserva.anulada)
      return;
    final controller = context.read<ReservaController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular Reserva'),
        content: Text(
            'Anular la reserva #${_reserva!.id}?\n\nCliente: ${_reserva!.clienteNombre}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Anular')),
        ],
      ),
    );
    if (ok != true) return;
    final success = await controller.anular(_reserva!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Reserva anulada exitosamente' : controller.errorMsg),
        backgroundColor: success ? Colors.orange : AppColors.primary,
      ));
      if (success) _cargarDetalle();
    }
  }

  //  Reprogramar
  Future<void> _showReprogramar() async {
    if (_reserva == null ||
        _reserva!.estadoEnum == EstadoReserva.anulada ||
        _reserva!.estadoEnum == EstadoReserva.finalizado) return;
    final controller = context.read<ReservaController>();
    final r = _reserva!;
    DateTime fechaSel = r.fechaEvento;
    String horaIni = r.horaInicio;
    String horaFin = r.horaFin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Reprogramar Reserva'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: () async {
                final f = await showDatePicker(
                    context: ctx,
                    initialDate: fechaSel,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if (f != null) setS(() => fechaSel = f);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text('${fechaSel.day}/${fechaSel.month}/${fechaSel.year}'),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: horaIni,
                decoration: const InputDecoration(
                    labelText: 'Hora inicio',
                    border: OutlineInputBorder(),
                    hintText: 'HH:MM'),
                onChanged: (v) => setS(() => horaIni = v)),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: horaFin,
                decoration: const InputDecoration(
                    labelText: 'Hora fin',
                    border: OutlineInputBorder(),
                    hintText: 'HH:MM'),
                onChanged: (v) => setS(() => horaFin = v)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reprogramar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final success =
        await controller.reprogramarReserva(r.id, fechaSel, horaIni, horaFin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Reserva reprogramada exitosamente'
            : controller.errorMsg),
        backgroundColor: success ? Colors.green : AppColors.primary,
      ));
      if (success) _cargarDetalle();
    }
  }

  //  PDF
  Future<void> _descargarPdf() async {
    if (_reserva == null) return;
    try {
      await descargarReservaPdf(_reserva!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  //  Helpers dialogo
  static Widget _infoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? AppColors.text)),
      ]),
    );
  }

  static Widget _montoBtn(
      {required String label,
      required String sublabel,
      required bool selected,
      required VoidCallback onTap}) {
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
              width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.text)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textMuted)),
        ]),
      ),
    );
  }

  //  BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _reserva != null ? 'Reserva #${_reserva!.id}' : 'Detalle de Reserva',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (_reserva != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                if (_reserva!.estadoEnum != EstadoReserva.anulada &&
                    _reserva!.saldoPendiente > 0)
                  const PopupMenuItem(
                      value: 'abono',
                      child: Row(children: [
                        Icon(Icons.payments_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Registrar Abono')
                      ])),
                if (_reserva!.estadoEnum != EstadoReserva.anulada &&
                    _reserva!.estadoEnum != EstadoReserva.finalizado)
                  const PopupMenuItem(
                      value: 'reprogramar',
                      child: Row(children: [
                        Icon(Icons.schedule, size: 18),
                        SizedBox(width: 8),
                        Text('Reprogramar')
                      ])),
                const PopupMenuItem(
                    value: 'pdf',
                    child: Row(children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          size: 18, color: Color(0xFFB91C1C)),
                      SizedBox(width: 8),
                      Text('Descargar PDF',
                          style: TextStyle(color: Color(0xFFB91C1C)))
                    ])),
                if (_reserva!.estadoEnum != EstadoReserva.anulada &&
                    _reserva!.estadoEnum != EstadoReserva.finalizado) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'anular',
                      child: Row(children: [
                        Icon(Icons.cancel_outlined,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Anular', style: TextStyle(color: Colors.red))
                      ])),
                ],
              ],
              onSelected: (v) {
                switch (v) {
                  case 'abono':
                    _showAbono();
                  case 'reprogramar':
                    _showReprogramar();
                  case 'pdf':
                    _descargarPdf();
                  case 'anular':
                    _confirmAnular();
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _cargarDetalle,
            child: const Text('Reintentar')),
      ]));
    }
    if (_reserva == null)
      return const Center(child: Text('Reserva no encontrada'));

    final r = _reserva!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner estado
        _EstadoBanner(reserva: r),
        const SizedBox(height: 16),

        // Cliente
        _Seccion(titulo: 'Cliente', icono: Icons.person_outline, children: [
          _Fila(label: 'Nombre', valor: r.clienteNombre),
          if (r.clienteEmail.isNotEmpty)
            _Fila(label: 'Email', valor: r.clienteEmail),
          if (r.clienteTelefono.isNotEmpty)
            _Fila(label: 'Telefono', valor: r.clienteTelefono),
          if (r.homenajeado.isNotEmpty)
            _Fila(label: 'Homenajeado', valor: r.homenajeado),
        ]),
        const SizedBox(height: 12),

        // Evento
        _Seccion(titulo: 'Evento', icono: Icons.event_outlined, children: [
          _Fila(
              label: 'Fecha',
              valor:
                  '${r.fechaEvento.day}/${r.fechaEvento.month}/${r.fechaEvento.year}'),
          _Fila(label: 'Horario', valor: '${r.horaInicio} - ${r.horaFin}'),
          _Fila(label: 'Lugar', valor: r.ubicacion),
        ]),
        const SizedBox(height: 12),

        // Servicios
        if (r.chips.isNotEmpty) ...[
          _Seccion(
              titulo: 'Servicios',
              icono: Icons.music_note_outlined,
              children: [
                ...r.chips.map((s) => _ChipServicioFila(servicio: s)),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1)),
                _Fila(
                    label: 'Total servicios',
                    valor: formatCop(r.totalValor.round()),
                    valorBold: true,
                    valorColor: AppColors.primary),
              ]),
          const SizedBox(height: 12),
        ],

        // Financiero
        _Seccion(
            titulo: 'Resumen Financiero',
            icono: Icons.account_balance_wallet_outlined,
            children: [
              _FilaFinanciera(
                  label: 'Valor total',
                  valor: formatCop(r.totalValor.round()),
                  bold: true),
              _FilaFinanciera(
                  label: 'Pagado',
                  valor: formatCop((r.totalValor - r.saldoPendiente).round()),
                  color: const Color(0xFF047857)),
              _FilaFinanciera(
                label: 'Saldo pendiente',
                valor: formatCop(r.saldoPendiente.round()),
                color: r.saldoPendiente > 0
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF047857),
                bold: r.saldoPendiente > 0,
                badge: r.saldoPendiente == 0 ? 'PAGADO' : null,
              ),
            ]),

        // Abonos
        if (r.abonos.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Seccion(
              titulo: 'Historial de Pagos',
              icono: Icons.payments_outlined,
              children: r.abonos
                  .asMap()
                  .entries
                  .map((e) => _AbonoFila(abono: e.value, numero: e.key + 1))
                  .toList()),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }
}

//  BANNER

class _EstadoBanner extends StatelessWidget {
  final Reserva reserva;
  const _EstadoBanner({required this.reserva});

  Color get _bg => switch (reserva.estadoEnum) {
        EstadoReserva.pendiente => const Color(0xFFFEF3C7),
        EstadoReserva.confirmada => const Color(0xFFDCFCE7),
        EstadoReserva.anulada => const Color(0xFFFEE2E2),
        EstadoReserva.finalizado => const Color(0xFFDBEAFE),
      };

  Color get _fg => switch (reserva.estadoEnum) {
        EstadoReserva.pendiente => const Color(0xFFB45309),
        EstadoReserva.confirmada => const Color(0xFF047857),
        EstadoReserva.anulada => const Color(0xFFB91C1C),
        EstadoReserva.finalizado => const Color(0xFF1D4ED8),
      };

  IconData get _icon => switch (reserva.estadoEnum) {
        EstadoReserva.pendiente => Icons.hourglass_empty_rounded,
        EstadoReserva.confirmada => Icons.check_circle_outline,
        EstadoReserva.anulada => Icons.cancel_outlined,
        EstadoReserva.finalizado => Icons.verified_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(_icon, color: _fg, size: 22),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reserva.estadoLabel,
              style: TextStyle(
                  color: _fg, fontWeight: FontWeight.w900, fontSize: 15)),
          Text(reserva.tipoSerenata,
              style: TextStyle(
                  color: _fg.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        Text('#${reserva.id}',
            style: TextStyle(
                color: _fg.withValues(alpha: 0.6),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ]),
    );
  }
}

//  SECCION

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  const _Seccion(
      {required this.titulo, required this.icono, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Icon(icono, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.text)),
          ]),
        ),
        const Divider(height: 1),
        Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)),
      ]),
    );
  }
}

//  FILA

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  final Color? valorColor;
  final bool valorBold;
  const _Fila(
      {required this.label,
      required this.valor,
      this.valorColor,
      this.valorBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(valor,
                style: TextStyle(
                    fontSize: 13,
                    color: valorColor ?? AppColors.text,
                    fontWeight:
                        valorBold ? FontWeight.w800 : FontWeight.w500))),
      ]),
    );
  }
}

//  FILA FINANCIERA

class _FilaFinanciera extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;
  final bool bold;
  final String? badge;
  const _FilaFinanciera(
      {required this.label,
      required this.valor,
      this.color,
      this.bold = false,
      this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        Row(children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 13,
                  color: color ?? AppColors.text,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
            ),
          ],
        ]),
      ]),
    );
  }
}

//  FILA ABONO

class _AbonoFila extends StatelessWidget {
  final Abono abono;
  final int numero;
  const _AbonoFila({required this.abono, required this.numero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF047857).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text('$numero',
                  style: const TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w900,
                      fontSize: 13))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(abono.metodoPago,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.text)),
          Text(
              '${abono.fechaPago.day}/${abono.fechaPago.month}/${abono.fechaPago.year}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          if (abono.notas != null && abono.notas!.isNotEmpty)
            Text(abono.notas!,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        Text(formatCop(abono.monto.round()),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF047857))),
      ]),
    );
  }
}

//  FILA CHIP SERVICIO (VentaServicio)

class _ChipServicioFila extends StatelessWidget {
  final VentaServicio servicio;
  const _ChipServicioFila({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child:
              const Icon(Icons.music_note, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(servicio.nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text)),
            if (servicio.cantidad > 1)
              Text(
                  'x${servicio.cantidad}  ${formatCop(servicio.precio.round())} c/u',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        Text(formatCop(servicio.subtotal.round()),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.text)),
      ]),
    );
  }
}
