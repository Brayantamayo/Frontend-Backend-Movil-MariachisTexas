import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import 'cancion.model.dart';
import 'repertorio_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Player global compartido: una sola instancia para toda la pantalla
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalPlayer {
  static final AudioPlayer _player = AudioPlayer();
  static AudioPlayer get instance => _player;
}

class RepertorioScreen extends StatefulWidget {
  const RepertorioScreen({super.key});

  @override
  State<RepertorioScreen> createState() => _RepertorioScreenState();
}

class _RepertorioScreenState extends State<RepertorioScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  // Estado del player en la pantalla principal
  int? _playingId;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepertorioController>().cargar();
    });

    final p = _GlobalPlayer.instance;
    _subs.add(p.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    }));
    _subs.add(p.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    }));
    _subs.add(p.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    }));
    _subs.add(p.onPlayerComplete.listen((_) {
      if (mounted)
        setState(() {
        _playingId = null;
        _position = Duration.zero;
        });
    }));
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _GlobalPlayer.instance.stop();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<RepertorioController>().buscar(q);
    });
  }

  Future<void> _togglePlay(Cancion c) async {
    final p = _GlobalPlayer.instance;

    if (_playingId == c.id) {
      // Pausa o reanuda la misma canción
      if (_playerState == PlayerState.playing) {
        await p.pause();
      } else {
        await p.resume();
      }
    } else {
      // Cambia de canción
      await p.stop();
      setState(() {
        _playingId = c.id;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await p.play(UrlSource(c.audioUrl!));
    }
  }

  Future<void> _stopPlay() async {
    await _GlobalPlayer.instance.stop();
    setState(() {
      _playingId = null;
      _position = Duration.zero;
    });
  }

  Future<void> _detalle(Cancion c) async {
    // Pausa el player mientras se ve el detalle
    final wasPlaying = _playerState == PlayerState.playing;
    if (wasPlaying) await _GlobalPlayer.instance.pause();

    final ctrl = context.read<RepertorioController>();
    final detalle = await ctrl.getDetalle(c.id);
    if (!mounted) return;
    final cd = detalle ?? c;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _DetalleDialog(cancion: cd),
    );

    // Reanuda si estaba reproduciendo
    if (wasPlaying && mounted) await _GlobalPlayer.instance.resume();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F0), Color(0xFFFAFAFA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header decorativo ──────────────────────────────────────────────
          _Header(onSearch: _onSearch, controller: _search),

          // ── Mini player flotante ───────────────────────────────────────────
          if (_playingId != null)
            _MiniPlayer(
              playingId: _playingId!,
              playerState: _playerState,
              position: _position,
              duration: _duration,
              onPlayPause: () {
                final ctrl = context.read<RepertorioController>();
                final c = ctrl.canciones.firstWhere((x) => x.id == _playingId);
                _togglePlay(c);
              },
              onClose: _stopPlay,
              onSeek: (v) => _GlobalPlayer.instance
                  .seek(Duration(milliseconds: v.round())),
              canciones: context.watch<RepertorioController>().canciones,
            ),

          // ── Lista ──────────────────────────────────────────────────────────
          Expanded(
            child: _Body(
              playingId: _playingId,
              playerState: _playerState,
              onPlay: _togglePlay,
              onDetalle: _detalle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header con búsqueda
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final TextEditingController controller;

  const _Header({required this.onSearch, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.queue_music,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repertorio',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text(
                    'Canciones disponibles',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF9CA3AF), size: 20),
                hintText: 'Buscar canción o artista...',
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini player que aparece cuando hay una canción activa
// ─────────────────────────────────────────────────────────────────────────────
class _MiniPlayer extends StatelessWidget {
  final int playingId;
  final PlayerState playerState;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;
  final ValueChanged<double> onSeek;
  final List<Cancion> canciones;

  const _MiniPlayer({
    required this.playingId,
    required this.playerState,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onClose,
    required this.onSeek,
    required this.canciones,
  });

  @override
  Widget build(BuildContext context) {
    final c = canciones.where((x) => x.id == playingId).firstOrNull;
    final isPlaying = playerState == PlayerState.playing;
    // Conversión explícita a double para evitar errores de tipo num
    final maxMs =
        duration.inMilliseconds == 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final curMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [(AppColors.primary), Color(0xFFE53E3E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (AppColors.primary).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                // Portada mini
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: c?.portada != null
                      ? Image.network(c!.portada!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultCover(44))
                      : _defaultCover(44),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c?.titulo ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                      Text(
                        c?.artista ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFFFCDD2), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 36,
                      color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close,
                      size: 18, color: Color(0xFFFFCDD2)),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Barra de progreso
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Row(
              children: [
                Text(_mmss(position),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: curMs, // double
                      min: 0.0, // double explícito
                      max: maxMs, // double
                      onChanged: onSeek,
                    ),
                  ),
                ),
                Text(_mmss(duration),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCover(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final int? playingId;
  final PlayerState playerState;
  final Future<void> Function(Cancion) onPlay;
  final Future<void> Function(Cancion) onDetalle;

  const _Body({
    required this.playingId,
    required this.playerState,
    required this.onPlay,
    required this.onDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RepertorioController>();

    if (ctrl.status == RepertorioStatus.cargando) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (ctrl.status == RepertorioStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Text(ctrl.errorMsg,
                style: const TextStyle(color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<RepertorioController>().cargar(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (ctrl.canciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_outlined,
                size: 52, color: Color(0xFFE2E8F0)),
            SizedBox(height: 12),
            Text('No se encontraron canciones',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: ctrl.canciones.length,
      itemBuilder: (_, i) {
        final c = ctrl.canciones[i];
        final isThisPlaying =
            playingId == c.id && playerState == PlayerState.playing;
        final isThisActive = playingId == c.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CancionCard(
            c: c,
            isPlaying: isThisPlaying,
            isActive: isThisActive,
            onPlay: c.audioUrl != null ? () => onPlay(c) : null,
            onDetalle: () => onDetalle(c),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de canción — estética nueva
// ─────────────────────────────────────────────────────────────────────────────
class _CancionCard extends StatelessWidget {
  final Cancion c;
  final bool isPlaying;
  final bool isActive;
  final VoidCallback? onPlay;
  final VoidCallback onDetalle;

  const _CancionCard({
    required this.c,
    required this.isPlaying,
    required this.isActive,
    required this.onPlay,
    required this.onDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetalle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (AppColors.primary).withOpacity(0.4)
                : const Color(0xFFF1F5F9),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? (AppColors.primary).withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Portada ────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: c.portada != null
                  ? Image.network(
                      c.portada!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultPortada(),
                    )
                  : _defaultPortada(),
            ),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isActive
                            ? (AppColors.primary)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.artista,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(c.genero),
                        if (!c.activa) ...[
                          const SizedBox(width: 6),
                          _chipInactiva(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Botón play ─────────────────────────────────────────────────
            if (onPlay != null)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: onPlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? (AppColors.primary)
                          : (AppColors.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isPlaying
                          ? Colors.white
                          : (AppColors.primary),
                      size: 22,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _defaultPortada() => Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEE2E2), Color(0xFFFECDD3)],
          ),
        ),
        child: const Icon(Icons.music_note,
            color: (AppColors.primary), size: 28),
      );

  static Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBE123C),
              letterSpacing: 0.3),
        ),
      );

  static Widget _chipInactiva() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Inactiva',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de detalle completo
// ─────────────────────────────────────────────────────────────────────────────
class _DetalleDialog extends StatelessWidget {
  final Cancion cancion;

  const _DetalleDialog({required this.cancion});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Portada grande ─────────────────────────────────────────────
              SizedBox(
                height: 180,
                width: double.infinity,
                child: cancion.portada != null
                    ? Image.network(cancion.portada!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _headerDefault())
                    : _headerDefault(),
              ),

              // ── Info ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cancion.titulo,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 4),
                    Text(cancion.artista,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 14)),
                    const SizedBox(height: 14),

                    // Chips de info
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(Icons.album, cancion.genero),
                        _infoChip(Icons.category_outlined, cancion.categoria),
                        _infoChip(Icons.timer_outlined, cancion.duracion),
                        _infoChip(Icons.bar_chart, cancion.dificultad),
                        _infoChip(
                          cancion.activa
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          cancion.activa ? 'Activa' : 'Inactiva',
                        ),
                      ],
                    ),

                    // Letra
                    if (cancion.letra != null && cancion.letra!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'LETRA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            cancion.letra!,
                            style: const TextStyle(
                                height: 1.6,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: Color(0xFF374151)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: (AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFFEE2E2)),
                          ),
                        ),
                        child: const Text('Cerrar',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerDefault() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [(AppColors.primary), Color(0xFFE53E3E)],
          ),
        ),
        child: const Center(
            child: Icon(Icons.music_note, color: Colors.white54, size: 64)),
      );

  static Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: (AppColors.primary)),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE123C))),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _mmss(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
