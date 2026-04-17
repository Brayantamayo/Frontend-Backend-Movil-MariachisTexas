import 'package:flutter/material.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';

enum EstadoCotizacion { enEspera, convertida, anulada }

class Cotizacion {
  final int id;
  final String cliente;
  final String evento;
  final String fecha;
  final int total;
  EstadoCotizacion estado;

  Cotizacion({
    required this.id,
    required this.cliente,
    required this.evento,
    required this.fecha,
    required this.total,
    required this.estado,
  });
}

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final _search = TextEditingController();

  final List<Cotizacion> _items = [
    Cotizacion(id: 1001, cliente: 'Familia Martínez', evento: 'Boda', fecha: '14/04/2026', total: 1200000, estado: EstadoCotizacion.enEspera),
    Cotizacion(id: 1002, cliente: 'Juan Pérez', evento: 'Serenata', fecha: '15/04/2026', total: 500000, estado: EstadoCotizacion.convertida),
    Cotizacion(id: 1003, cliente: 'Empresa XYZ', evento: 'Fiesta Anual', fecha: '20/04/2026', total: 2000000, estado: EstadoCotizacion.anulada),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Cotizacion> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((c) {
      return c.cliente.toLowerCase().contains(q) || c.evento.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showDetalle(Cotizacion c) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalle de Cotización #${c.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Cliente', c.cliente),
            _kv('Evento', c.evento),
            _kv('Fecha', c.fecha),
            _kv('Estado', _estadoLabel(c.estado)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _kv('Total Cotizado', formatCop(c.total)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Cotizacion c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Estás seguro de eliminar esta cotización?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(AppColors.primary)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _items.removeWhere((x) => x.id == c.id));
  }

  void _setEstado(Cotizacion c, EstadoCotizacion e) {
    setState(() => c.estado = e);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cotizaciones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar cotización...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No se encontraron cotizaciones.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _CotizacionCard(
                      c: items[i],
                      onDetalle: () => _showDetalle(items[i]),
                      onConvertir: items[i].estado == EstadoCotizacion.enEspera ? () => _setEstado(items[i], EstadoCotizacion.convertida) : null,
                      onAnular: items[i].estado == EstadoCotizacion.enEspera ? () => _setEstado(items[i], EstadoCotizacion.anulada) : null,
                      onDelete: () => _confirmDelete(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CotizacionCard extends StatelessWidget {
  final Cotizacion c;
  final VoidCallback onDetalle;
  final VoidCallback? onConvertir;
  final VoidCallback? onAnular;
  final VoidCallback onDelete;

  const _CotizacionCard({
    required this.c,
    required this.onDetalle,
    required this.onConvertir,
    required this.onAnular,
    required this.onDelete,
  });

  Color _pillBg() {
    return switch (c.estado) {
      EstadoCotizacion.enEspera => const Color(0xFFFEF3C7),
      EstadoCotizacion.convertida => const Color(0xFFDCFCE7),
      EstadoCotizacion.anulada => const Color(0xFFFEE2E2),
    };
  }

  Color _pillFg() {
    return switch (c.estado) {
      EstadoCotizacion.enEspera => const Color(0xFFB45309),
      EstadoCotizacion.convertida => const Color(0xFF047857),
      EstadoCotizacion.anulada => const Color(0xFFB91C1C),
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${c.id}', style: const TextStyle(color: Color(AppColors.textMuted), fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c.evento, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(AppColors.text))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(c.cliente, style: const TextStyle(color: Color(AppColors.textMuted))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _pillBg(), borderRadius: BorderRadius.circular(999)),
                  child: Text(_estadoLabel(c.estado), style: TextStyle(color: _pillFg(), fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
                    if (onConvertir != null) const PopupMenuItem(value: 'convertir', child: Text('Convertir a Reserva')),
                    if (onAnular != null) const PopupMenuItem(value: 'anular', child: Text('Anular')),
                    const PopupMenuItem(value: 'pdf', child: Text('Ver PDF')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  onSelected: (v) {
                    if (v == 'detalle') onDetalle();
                    if (v == 'convertir' && onConvertir != null) onConvertir!();
                    if (v == 'anular' && onAnular != null) onAnular!();
                    if (v == 'delete') onDelete();
                    // "pdf" es placeholder en esta versión.
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(c.fecha, style: const TextStyle(color: Color(AppColors.textMuted))),
                const Spacer(),
                Text(formatCop(c.total), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(AppColors.text))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _estadoLabel(EstadoCotizacion e) {
  return switch (e) {
    EstadoCotizacion.enEspera => 'en espera',
    EstadoCotizacion.convertida => 'convertida',
    EstadoCotizacion.anulada => 'anulada',
  };
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

