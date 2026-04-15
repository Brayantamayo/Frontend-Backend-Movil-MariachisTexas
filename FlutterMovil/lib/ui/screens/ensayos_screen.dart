import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum EstadoEnsayo { pendiente, listo }

class Ensayo {
  final int id;
  final String titulo;
  final String fecha;
  final String hora;
  final String lugar;
  EstadoEnsayo estado;

  Ensayo({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.estado,
  });
}

class EnsayosScreen extends StatefulWidget {
  const EnsayosScreen({super.key});

  @override
  State<EnsayosScreen> createState() => _EnsayosScreenState();
}

class _EnsayosScreenState extends State<EnsayosScreen> {
  final _search = TextEditingController();

  final List<Ensayo> _items = [
    Ensayo(id: 1, titulo: 'Ensayo General - Boda Martínez', fecha: '12/04/2026', hora: '18:00', lugar: 'Sala de Ensayos A', estado: EstadoEnsayo.listo),
    Ensayo(id: 2, titulo: 'Práctica Nuevo Repertorio', fecha: '16/04/2026', hora: '19:00', lugar: 'Sala de Ensayos B', estado: EstadoEnsayo.pendiente),
    Ensayo(id: 3, titulo: 'Ensayo Serenata', fecha: '18/04/2026', hora: '20:00', lugar: 'Casa de Juan', estado: EstadoEnsayo.pendiente),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Ensayo> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((e) {
      return e.titulo.toLowerCase().contains(q) || e.lugar.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(Ensayo e) {
    setState(() => e.estado = e.estado == EstadoEnsayo.pendiente ? EstadoEnsayo.listo : EstadoEnsayo.pendiente);
  }

  Future<void> _delete(Ensayo e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ensayo'),
        content: const Text('¿Estás seguro de eliminar este ensayo?'),
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
    setState(() => _items.removeWhere((x) => x.id == e.id));
  }

  Future<void> _detalle(Ensayo e) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle del Ensayo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Título', e.titulo),
            _kv('Fecha', e.fecha),
            _kv('Hora', e.hora),
            _kv('Lugar', e.lugar),
            _kv('Estado', e.estado.name),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
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
            'Ensayos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar ensayo...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No se encontraron ensayos.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _EnsayoCard(
                      e: items[i],
                      onDetalle: () => _detalle(items[i]),
                      onToggle: () => _toggle(items[i]),
                      onDelete: () => _delete(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EnsayoCard extends StatelessWidget {
  final Ensayo e;
  final VoidCallback onDetalle;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _EnsayoCard({
    required this.e,
    required this.onDetalle,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final listo = e.estado == EstadoEnsayo.listo;
    final bg = listo ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final fg = listo ? const Color(0xFF047857) : const Color(0xFFB45309);

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(Icons.mic, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: listo ? const Color(AppColors.textMuted) : const Color(AppColors.text),
                          decoration: listo ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                        child: Text(e.estado.name, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
                    if (!listo) const PopupMenuItem(value: 'listo', child: Text('Marcar como listo')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  onSelected: (v) {
                    if (v == 'detalle') onDetalle();
                    if (v == 'listo') onToggle();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_outlined, e.fecha),
                _info(Icons.schedule, e.hora),
                _info(Icons.place_outlined, e.lugar),
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

