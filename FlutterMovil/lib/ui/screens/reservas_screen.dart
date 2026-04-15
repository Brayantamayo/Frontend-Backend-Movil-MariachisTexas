import 'package:flutter/material.dart';

import '../../core/format/currency.dart';
import '../../core/theme/app_colors.dart';

enum EstadoReserva { pendiente, confirmada, finalizada, anulada }

class Reserva {
  final int id;
  final String cliente;
  final String evento;
  final String fecha;
  final String hora;
  final String lugar;
  EstadoReserva estado;
  final int total;
  int abonado;

  Reserva({
    required this.id,
    required this.cliente,
    required this.evento,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.estado,
    required this.total,
    required this.abonado,
  });
}

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final List<Reserva> _reservas = [
    Reserva(
      id: 107,
      cliente: 'Brayan Castañeda Tamayo',
      evento: 'Boda',
      fecha: '14/04/2026',
      hora: '20:00',
      lugar: 'Salón Los Arcos',
      estado: EstadoReserva.pendiente,
      total: 1200000,
      abonado: 0,
    ),
    Reserva(
      id: 108,
      cliente: 'Juan Pérez',
      evento: 'Serenata',
      fecha: '15/04/2026',
      hora: '23:30',
      lugar: 'Col. Centro',
      estado: EstadoReserva.confirmada,
      total: 500000,
      abonado: 250000,
    ),
    Reserva(
      id: 109,
      cliente: 'Empresa XYZ',
      evento: 'Fiesta Anual',
      fecha: '20/04/2026',
      hora: '14:00',
      lugar: 'Hacienda San José',
      estado: EstadoReserva.finalizada,
      total: 2000000,
      abonado: 2000000,
    ),
  ];

  Future<void> _showDetalle(Reserva r) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalle de Reserva #${r.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Cliente', r.cliente),
            _kv('Evento', r.evento),
            _kv('Fecha', r.fecha),
            _kv('Hora', r.hora),
            _kv('Lugar', r.lugar),
            _kv('Estado', r.estado.name),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _kv('Total', formatCop(r.total)),
            _kv('Abonado', formatCop(r.abonado)),
            _kv('Saldo', formatCop(r.total - r.abonado)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmAnular(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular reserva'),
        content: const Text('¿Estás seguro de anular esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(AppColors.primary)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => r.estado = EstadoReserva.anulada);
  }

  Future<void> _registrarAbono() async {
    final active = _reservas
        .where((r) => r.estado != EstadoReserva.finalizada && r.estado != EstadoReserva.anulada)
        .toList();
    if (active.isEmpty) return;

    int? selectedId = active.first.id;
    var tipoPago = 'anticipo'; // anticipo | total
    var metodo = 'Transferencia';
    var fechaPago = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        Reserva selected() => _reservas.firstWhere((r) => r.id == selectedId);

        int monto(Reserva r) {
          if (tipoPago == 'anticipo') return (r.total * 0.5).round();
          return (r.total - r.abonado).clamp(0, r.total);
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              final r = selected();
              final montoSel = monto(r);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REGISTRAR ABONO',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedId,
                    decoration: const InputDecoration(labelText: 'Reserva *', border: OutlineInputBorder()),
                    items: [
                      for (final it in active)
                        DropdownMenuItem(
                          value: it.id,
                          child: Text('#${it.id} — ${it.cliente} (${formatCop(it.total)})'),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => selectedId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: tipoPago == 'anticipo',
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Anticipo 50%'),
                              Text(formatCop(r.total * 0.5), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          onSelected: (_) => setLocal(() => tipoPago = 'anticipo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          selected: tipoPago == 'total',
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Pago total'),
                              Text(formatCop(r.total - r.abonado), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          onSelected: (_) => setLocal(() => tipoPago = 'total'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipoPago == 'anticipo' ? 'Anticipo (50%)' : 'Pago restante',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(AppColors.primary)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCop(montoSel),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(AppColors.primary)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${formatCop(r.total)}  •  Saldo: ${formatCop(r.total - r.abonado - montoSel)}',
                          style: const TextStyle(color: Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: metodo,
                    decoration: const InputDecoration(labelText: 'Método de Pago *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    ],
                    onChanged: (v) => setLocal(() => metodo = v ?? metodo),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaPago,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setLocal(() => fechaPago = picked);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Fecha de Pago: ${fechaPago.toIso8601String().split('T').first}'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(AppColors.primary)),
                      onPressed: () {
                        final rr = selected();
                        final m = monto(rr);
                        setState(() {
                          rr.abonado = (rr.abonado + m).clamp(0, rr.total);
                          if (rr.abonado >= rr.total) {
                            rr.estado = EstadoReserva.finalizada;
                          } else if (rr.abonado > 0) {
                            rr.estado = EstadoReserva.confirmada;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Confirmar Pago'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reservas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: _registrarAbono,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(AppColors.primary),
                  foregroundColor: Colors.white,
                ),
                child: const Text('+ Registrar Abono'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _reservas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = _reservas[i];
                return _ReservaCard(
                  r: r,
                  onDetalle: () => _showDetalle(r),
                  onAnular: r.estado == EstadoReserva.anulada ? null : () => _confirmAnular(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva r;
  final VoidCallback onDetalle;
  final VoidCallback? onAnular;

  const _ReservaCard({required this.r, required this.onDetalle, required this.onAnular});

  Color _pillBg() {
    return switch (r.estado) {
      EstadoReserva.pendiente => const Color(0xFFFEF3C7),
      EstadoReserva.confirmada => const Color(0xFFDBEAFE),
      EstadoReserva.finalizada => const Color(0xFFDCFCE7),
      EstadoReserva.anulada => const Color(0xFFFEE2E2),
    };
  }

  Color _pillFg() {
    return switch (r.estado) {
      EstadoReserva.pendiente => const Color(0xFFB45309),
      EstadoReserva.confirmada => const Color(0xFF1D4ED8),
      EstadoReserva.finalizada => const Color(0xFF047857),
      EstadoReserva.anulada => const Color(0xFFB91C1C),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${r.id}', style: const TextStyle(color: Color(AppColors.textMuted), fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.evento,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(r.cliente, style: const TextStyle(color: Color(AppColors.textMuted))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _pillBg(), borderRadius: BorderRadius.circular(999)),
                  child: Text(r.estado.name, style: TextStyle(color: _pillFg(), fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
                    if (onAnular != null) const PopupMenuItem(value: 'anular', child: Text('Anular')),
                  ],
                  onSelected: (v) {
                    if (v == 'detalle') onDetalle();
                    if (v == 'anular' && onAnular != null) onAnular!();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_outlined, r.fecha),
                _info(Icons.schedule, r.hora),
                _info(Icons.place_outlined, r.lugar),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _money('Total', formatCop(r.total), const Color(AppColors.text))),
                Expanded(child: _money('Saldo', formatCop(r.total - r.abonado), const Color(AppColors.primary))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(AppColors.textMuted)),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF475569))),
        ),
      ],
    );
  }

  static Widget _money(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(AppColors.textMuted), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(AppColors.textMuted))),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

