import 'package:flutter/material.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';

class VentaDetalleScreen extends StatelessWidget {
  final Venta venta;
  const VentaDetalleScreen({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    final v = venta;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          v.concepto ?? 'Venta #${v.idRaw}',
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner de estado ───────────────────────────────────────────
            _EstadoBanner(venta: v),
            const SizedBox(height: 16),

            // ── Cliente ────────────────────────────────────────────────────
            _Seccion(
              titulo: 'Cliente',
              icono: Icons.person_outline,
              children: [
                _Fila(label: 'Nombre', valor: v.clienteNombre),
                if (v.clienteEmail.isNotEmpty)
                  _Fila(label: 'Email', valor: v.clienteEmail),
                if (v.clienteTelefono.isNotEmpty)
                  _Fila(label: 'Teléfono', valor: v.clienteTelefono),
              ],
            ),
            const SizedBox(height: 12),

            // ── Venta / Evento ─────────────────────────────────────────────
            if (_tieneInfoEvento(v)) ...[
              _Seccion(
                titulo: 'Venta',
                icono: Icons.event_outlined,
                children: [
                  if (v.concepto != null && v.concepto!.isNotEmpty)
                    _Fila(label: 'Concepto', valor: v.concepto!),
                  if (v.tipoEvento != null && v.tipoEvento!.isNotEmpty)
                    _Fila(
                        label: 'Tipo de evento',
                        valor: _labelTipoEvento(v.tipoEvento!)),
                  if (v.homenajeado != null && v.homenajeado!.isNotEmpty)
                    _Fila(label: 'Homenajeado', valor: v.homenajeado!),
                  if (v.fechaEvento != null)
                    _Fila(
                      label: 'Fecha',
                      valor:
                          '${v.fechaEvento!.day}/${v.fechaEvento!.month}/${v.fechaEvento!.year}',
                    ),
                  if (v.horaInicio != null && v.horaFin != null)
                    _Fila(
                        label: 'Horario',
                        valor: '${v.horaInicio} - ${v.horaFin}'),
                  if (v.ubicacion != null && v.ubicacion!.isNotEmpty)
                    _Fila(label: 'Lugar', valor: v.ubicacion!),
                  if (v.notas != null && v.notas!.isNotEmpty)
                    _Fila(label: 'Notas', valor: v.notas!),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Servicios ──────────────────────────────────────────────────
            if (v.servicios.isNotEmpty) ...[
              _Seccion(
                titulo: 'Servicios',
                icono: Icons.music_note_outlined,
                children: [
                  ...v.servicios.map((s) => _ServicioFila(servicio: s)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _Fila(
                    label: 'Total servicios',
                    valor: formatCop(v.servicios
                        .fold(0.0, (sum, s) => sum + s.subtotal)
                        .round()),
                    valorBold: true,
                    valorColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Resumen financiero ─────────────────────────────────────────
            _Seccion(
              titulo: 'Resumen Financiero',
              icono: Icons.account_balance_wallet_outlined,
              children: [
                _FilaFinanciera(
                  label: 'Valor total',
                  valor: formatCop(v.totalValor.round()),
                  bold: true,
                ),
                _FilaFinanciera(
                  label: 'Pagado',
                  valor: formatCop(v.montoPagado.round()),
                  color: const Color(0xFF047857),
                ),
                _FilaFinanciera(
                  label: 'Saldo pendiente',
                  valor: formatCop(v.saldoPendiente.round()),
                  color: v.saldoPendiente > 0
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF047857),
                  bold: v.saldoPendiente > 0,
                  badge: v.saldoPendiente == 0 ? 'PAGADO' : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Historial de abonos ────────────────────────────────────────
            if (v.abonos.isNotEmpty) ...[
              _Seccion(
                titulo: 'Historial de Pagos',
                icono: Icons.payments_outlined,
                children: v.abonos
                    .asMap()
                    .entries
                    .map((e) => _AbonoFila(
                          abono: e.value,
                          numero: e.key + 1,
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _tieneInfoEvento(Venta v) =>
      v.fechaEvento != null ||
      v.horaInicio != null ||
      v.ubicacion != null ||
      v.homenajeado != null ||
      (v.tipoEvento != null && v.tipoEvento!.isNotEmpty) ||
      (v.notas != null && v.notas!.isNotEmpty);

  String _labelTipoEvento(String tipo) => switch (tipo.toUpperCase()) {
        'BODA' => 'Boda',
        'CUMPLEANOS' => 'Cumpleaños',
        'QUINCEANIOS' => 'Quinceaños',
        'FUNERAL' => 'Funeral',
        'RECONCILIACION' => 'Reconciliación',
        'DIA_DE_MADRE' => 'Día de la Madre',
        'AMOR' => 'Amor',
        'ANIVERSARIO' => 'Aniversario',
        'PADRES' => 'Día del Padre',
        'FIESTA' => 'Fiesta',
        _ => tipo,
      };
}

// ─── BANNER DE ESTADO ─────────────────────────────────────────────────────────

class _EstadoBanner extends StatelessWidget {
  final Venta venta;
  const _EstadoBanner({required this.venta});

  Color get _bg => switch (venta.estadoEnum) {
        EstadoVenta.confirmado => const Color(0xFFDCFCE7),
        EstadoVenta.finalizado => const Color(0xFFDBEAFE),
        EstadoVenta.cancelada => const Color(0xFFFEE2E2),
      };

  Color get _fg => switch (venta.estadoEnum) {
        EstadoVenta.confirmado => const Color(0xFF047857),
        EstadoVenta.finalizado => const Color(0xFF1D4ED8),
        EstadoVenta.cancelada => const Color(0xFFB91C1C),
      };

  IconData get _icon => switch (venta.estadoEnum) {
        EstadoVenta.confirmado => Icons.check_circle_outline,
        EstadoVenta.finalizado => Icons.verified_outlined,
        EstadoVenta.cancelada => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _fg, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venta.estadoLabel,
                style: TextStyle(
                  color: _fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              Text(
                venta.tipo ?? 'Venta',
                style: TextStyle(
                  color: _fg.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '#${venta.idRaw}',
            style: TextStyle(
              color: _fg.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECCIÓN ──────────────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icono, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FILA SIMPLE ──────────────────────────────────────────────────────────────

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  final Color? valorColor;
  final bool valorBold;

  const _Fila({
    required this.label,
    required this.valor,
    this.valorColor,
    this.valorBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 13,
                color: valorColor ?? AppColors.text,
                fontWeight: valorBold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

  const _FilaFinanciera({
    required this.label,
    required this.valor,
    this.color,
    this.bold = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 13,
                  color: color ?? AppColors.text,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FILA SERVICIO ────────────────────────────────────────────────────────────

class _ServicioFila extends StatelessWidget {
  final VentaServicio servicio;
  const _ServicioFila({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note,
                size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
                if (servicio.cantidad > 1)
                  Text(
                    'x${servicio.cantidad} · ${formatCop(servicio.precio.round())} c/u',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            formatCop(servicio.subtotal.round()),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FILA ABONO ───────────────────────────────────────────────────────────────

class _AbonoFila extends StatelessWidget {
  final Abono abono;
  final int numero;
  const _AbonoFila({required this.abono, required this.numero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF047857).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  abono.metodoPago,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '${abono.fechaPago.day}/${abono.fechaPago.month}/${abono.fechaPago.year}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                if (abono.notas != null && abono.notas!.isNotEmpty)
                  Text(
                    abono.notas!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            formatCop(abono.monto.round()),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }
}
