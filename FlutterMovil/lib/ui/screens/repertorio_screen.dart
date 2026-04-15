import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum EstadoCancion { activo, inactivo }

class Cancion {
  final int id;
  final String titulo;
  final String artista;
  final String genero;
  final String letra;
  final String? audioUrl;
  EstadoCancion estado;

  Cancion({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.genero,
    required this.estado,
    required this.letra,
    this.audioUrl,
  });
}

class RepertorioScreen extends StatefulWidget {
  const RepertorioScreen({super.key});

  @override
  State<RepertorioScreen> createState() => _RepertorioScreenState();
}

class _RepertorioScreenState extends State<RepertorioScreen> {
  final _search = TextEditingController();

  final List<Cancion> _items = [
    Cancion(
      id: 1,
      titulo: 'El Rey',
      artista: 'Vicente Fernández',
      genero: 'Ranchera',
      estado: EstadoCancion.activo,
      letra: 'Yo sé bien que estoy afuera...',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    Cancion(
      id: 2,
      titulo: 'Si Nos Dejan',
      artista: 'José Alfredo Jiménez',
      genero: 'Bolero Ranchero',
      estado: EstadoCancion.activo,
      letra: 'Si nos dejan, nos vamos a querer toda la vida...',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    Cancion(
      id: 3,
      titulo: 'Hermoso Cariño',
      artista: 'Vicente Fernández',
      genero: 'Ranchera',
      estado: EstadoCancion.activo,
      letra: 'Hermoso cariño, hermoso cariño...',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    Cancion(
      id: 4,
      titulo: 'Cielito Lindo',
      artista: 'Tradicional',
      genero: 'Huapango',
      estado: EstadoCancion.inactivo,
      letra: 'De la sierra morena, cielito lindo, vienen bajando...',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Cancion> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((c) {
      return c.titulo.toLowerCase().contains(q) || c.artista.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(Cancion c) {
    setState(() {
      c.estado = c.estado == EstadoCancion.activo ? EstadoCancion.inactivo : EstadoCancion.activo;
    });
  }

  Future<void> _delete(Cancion c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: const Text('¿Estás seguro de eliminar esta canción?'),
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

  Future<void> _detalle(Cancion c) async {
    final player = AudioPlayer();
    var position = Duration.zero;
    var duration = Duration.zero;

    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;

    Future<void> stop() async {
      try {
        await player.stop();
      } catch (_) {}
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          sub1 ??= player.onPlayerStateChanged.listen((_) {
            if (ctx.mounted) setDialog(() {});
          });
          sub2 ??= player.onPositionChanged.listen((p) {
            position = p;
            if (ctx.mounted) setDialog(() {});
          });
          sub3 ??= player.onDurationChanged.listen((d) {
            duration = d;
            if (ctx.mounted) setDialog(() {});
          });

          return AlertDialog(
          title: const Text("Detalle de Canción"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Título', c.titulo),
                _kv('Artista', c.artista),
                _kv('Género', c.genero),
                _kv('Estado', c.estado.name),
                const SizedBox(height: 10),
                const Text(
                  'Letra',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(AppColors.textMuted)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      c.letra,
                      style: const TextStyle(height: 1.35, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                if (c.audioUrl != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Reproducir Audio',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(AppColors.textMuted)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final state = player.state;
                          if (state == PlayerState.playing) {
                            await player.pause();
                          } else {
                            await player.play(UrlSource(c.audioUrl!));
                          }
                          if (ctx.mounted) setDialog(() {});
                        },
                        icon: Icon(player.state == PlayerState.playing ? Icons.pause_circle : Icons.play_circle),
                        color: const Color(AppColors.primary),
                        iconSize: 40,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble().clamp(0, double.infinity)),
                              min: 0,
                              max: (duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds).toDouble(),
                              onChanged: (v) async {
                                await player.seek(Duration(milliseconds: v.round()));
                              },
                            ),
                            Text(
                              '${_mmss(position)} / ${_mmss(duration)}',
                              style: const TextStyle(fontSize: 12, color: Color(AppColors.textMuted)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await stop();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
        },
      ),
    );

    await stop();
    await sub1?.cancel();
    await sub2?.cancel();
    await sub3?.cancel();
    await player.dispose();
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
            'Repertorio',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar canción o artista...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No se encontraron canciones.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CancionCard(
                      c: items[i],
                      onDetalle: () => _detalle(items[i]),
                      onPlay: items[i].audioUrl == null ? null : () => _detalle(items[i]),
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

class _CancionCard extends StatelessWidget {
  final Cancion c;
  final VoidCallback onDetalle;
  final VoidCallback? onPlay;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CancionCard({
    required this.c,
    required this.onDetalle,
    required this.onPlay,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = c.estado == EstadoCancion.activo;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.music_note, color: active ? const Color(AppColors.primary) : const Color(AppColors.textMuted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.titulo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, color: active ? const Color(AppColors.text) : const Color(AppColors.textMuted)),
                  ),
                  const SizedBox(height: 2),
                  Text(c.artista, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(AppColors.textMuted))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip(c.genero, const Color(0xFFF1F5F9), const Color(0xFF475569)),
                      if (!active) _chip('Inactiva', const Color(0xFFFEE2E2), const Color(AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            if (onPlay != null)
              IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_circle, size: 30),
                color: const Color(AppColors.primary),
                tooltip: 'Reproducir',
              ),
            PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
                PopupMenuItem(value: 'toggle', child: Text('Activar/Desactivar')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
              onSelected: (v) {
                if (v == 'detalle') onDetalle();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: fg),
      ),
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

String _mmss(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

