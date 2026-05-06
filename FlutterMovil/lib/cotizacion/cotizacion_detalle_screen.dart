import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'cotizacion_controller.dart';

class CotizacionDetalleScreen extends StatefulWidget {
  final int cotizacionId;
  const CotizacionDetalleScreen({super.key, required this.cotizacionId});

  @override
  State<CotizacionDetalleScreen> createState() =>
      _CotizacionDetalleScreenState();
}

class _CotizacionDetalleScreenState extends State<CotizacionDetalleScreen> {
  Cotizacion? _cotizacion;
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
    final controller = context.read<CotizacionController>();
    final cotizacion = await controller.getDetalle(widget.cotizacionId);
    setState(() {
      _loading = false;
      if (cotizacion != null) {
        _cotizacion = cotizacion;
      } else {
        _error = controller.errorMsg.isNotEmpty
            ? controller.errorMsg
            : 'Error al cargar el detalle';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _cotizacion != null
              ? 'Cotización #${_cotizacion!.id}'
              : 'Detalle de Cotización',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
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
            child: const Text('Reintentar'),
          ),
        ]),
      );
    }
    if (_cotizacion == null) {
      return const Center(child: Text('Cotización no encontrada'));
    }

    final c = _cotizacion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Banner estado ──────────────────────────────────────────────────
        _EstadoBanner(cotizacion: c),
        const SizedBox(height: 16),

        // ── Cliente ────────────────────────────────────────────────────────
        _Seccion(titulo: 'Cliente', icono: Icons.person_outline, children: [
          _Fila(label: 'Nombre', valor: c.clienteNombre),
          if (c.clienteEmail.isNotEmpty)
            _Fila(label: 'Email', valor: c.clienteEmail),
          if (c.clienteTelefono.isNotEmpty)
            _Fila(label: 'Teléfono', valor: c.clienteTelefono),
          if (c.homenajeado.isNotEmpty)
            _Fila(label: 'Homenajeado', valor: c.homenajeado),
        ]),
        const SizedBox(height: 12),

        // ── Evento ─────────────────────────────────────────────────────────
        _Seccion(titulo: 'Evento', icono: Icons.event_outlined, children: [
          _Fila(label: 'Tipo', valor: c.tipoEventoLabel),
          _Fila(
            label: 'Fecha',
            valor:
                '${c.fechaEvento.day}/${c.fechaEvento.month}/${c.fechaEvento.year}',
          ),
          _Fila(label: 'Horario', valor: '${c.horaInicio} - ${c.horaFin}'),
          _Fila(label: 'Lugar', valor: c.ubicacion),
          if (c.notas != null && c.notas!.isNotEmpty)
            _Fila(label: 'Notas', valor: c.notas!),
          _Fila(
            label: 'Creada el',
            valor:
                '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
          ),
        ]),
        const SizedBox(height: 12),

        // ── Servicios ──────────────────────────────────────────────────────
        if (c.servicios.isNotEmpty) ...[
          _Seccion(
            titulo: 'Servicios',
            icono: Icons.music_note_outlined,
            children: [
              ...c.servicios.map((s) => _ServicioFila(servicio: s)),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1)),
              _Fila(
                label: 'Total estimado',
                valor: c.totalEstimado != null
                    ? formatCop(c.totalEstimado!.round())
                    : 'No calculado',
                valorBold: true,
                valorColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Repertorio ─────────────────────────────────────────────────────
        if (c.repertorios.isNotEmpty) ...[
          _Seccion(
            titulo: 'Repertorio',
            icono: Icons.queue_music_outlined,
            children: c.repertorios
                .map((item) => _RepertorioFila(item: item))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // ── Resumen financiero ─────────────────────────────────────────────
        _Seccion(
          titulo: 'Resumen Financiero',
          icono: Icons.account_balance_wallet_outlined,
          children: [
            _FilaFinanciera(
              label: 'Total estimado',
              valor: c.totalEstimado != null
                  ? formatCop(c.totalEstimado!.round())
                  : 'No calculado',
              bold: true,
            ),
          ],
        ),

        // ── Reserva asociada ───────────────────────────────────────────────
        if (c.reserva != null) ...[
          const SizedBox(height: 12),
          _Seccion(
            titulo: 'Reserva Asociada',
            icono: Icons.bookmark_added_outlined,
            children: [
              _Fila(label: 'ID', valor: '#${c.reserva!.id}'),
              _Fila(label: 'Estado', valor: c.reserva!.estadoLabel),
              _Fila(
                  label: 'Total',
                  valor: formatCop(c.reserva!.totalValor.round())),
              _FilaFinanciera(
                label: 'Saldo pendiente',
                valor: formatCop(c.reserva!.saldoPendiente.round()),
                color: c.reserva!.saldoPendiente > 0
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF047857),
                badge: c.reserva!.saldoPendiente == 0 ? 'PAGADO' : null,
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─── BANNER ───────────────────────────────────────────────────────────────────

class _EstadoBanner extends StatelessWidget {
  final Cotizacion cotizacion;
  const _EstadoBanner({required this.cotizacion});

  Color get _bg => switch (cotizacion.estado) {
        EstadoCotizacion.enEspera => const Color(0xFFFEF3C7),
        EstadoCotizacion.convertida => const Color(0xFFDCFCE7),
        EstadoCotizacion.anulada => const Color(0xFFFEE2E2),
      };

  Color get _fg => switch (cotizacion.estado) {
        EstadoCotizacion.enEspera => const Color(0xFFB45309),
        EstadoCotizacion.convertida => const Color(0xFF047857),
        EstadoCotizacion.anulada => const Color(0xFFB91C1C),
      };

  IconData get _icon => switch (cotizacion.estado) {
        EstadoCotizacion.enEspera => Icons.hourglass_empty_rounded,
        EstadoCotizacion.convertida => Icons.check_circle_outline,
        EstadoCotizacion.anulada => Icons.cancel_outlined,
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
          Text(cotizacion.estadoLabel,
              style: TextStyle(
                  color: _fg, fontWeight: FontWeight.w900, fontSize: 15)),
          Text(cotizacion.tipoEventoLabel,
              style: TextStyle(
                  color: _fg.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        Text('#${cotizacion.id}',
            style: TextStyle(
                color: _fg.withValues(alpha: 0.6),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
      ]),
    );
  }
}

// ─── SECCIÓN ──────────────────────────────────────────────────────────────────

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
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );
  }
}

// ─── FILA ─────────────────────────────────────────────────────────────────────

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
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(valor,
              style: TextStyle(
                  fontSize: 13,
                  color: valorColor ?? AppColors.text,
                  fontWeight: valorBold ? FontWeight.w800 : FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ─── FILA FINANCIERA ──────────────────────────────────────────────────────────

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

// ─── FILA SERVICIO ────────────────────────────────────────────────────────────

class _ServicioFila extends StatelessWidget {
  final CotizacionServicio servicio;
  const _ServicioFila({required this.servicio});

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
            Text(servicio.servicio.nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text)),
            if (servicio.cantidad > 1)
              Text(
                  'x${servicio.cantidad}  ${formatCop(servicio.servicio.precio.round())} c/u',
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

// ─── FILA REPERTORIO ──────────────────────────────────────────────────────────

class _RepertorioFila extends StatelessWidget {
  final CotizacionRepertorio item;
  const _RepertorioFila({required this.item});

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
          child: Center(
            child: Text('${item.orden}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.repertorio.titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text)),
            Text(item.repertorio.artista,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        if (item.repertorio.duracion.isNotEmpty)
          Text(item.repertorio.duracion,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}
