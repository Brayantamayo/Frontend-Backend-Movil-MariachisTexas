import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import 'ensayo_controller.dart';

class EnsayoDetalleScreen extends StatefulWidget {
  final int ensayoId;
  const EnsayoDetalleScreen({super.key, required this.ensayoId});

  @override
  State<EnsayoDetalleScreen> createState() => _EnsayoDetalleScreenState();
}

class _EnsayoDetalleScreenState extends State<EnsayoDetalleScreen> {
  Ensayo? _ensayo;
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
    final controller = context.read<EnsayoController>();
    final ensayo = await controller.getDetalle(widget.ensayoId);
    setState(() {
      _loading = false;
      if (ensayo != null) {
        _ensayo = ensayo;
      } else {
        _error = controller.errorMsg.isNotEmpty
            ? controller.errorMsg
            : 'Error al cargar el detalle';
      }
    });
  }

  Future<void> _toggleEstado() async {
    if (_ensayo == null) return;
    final esListo = _ensayo!.estado == EstadoEnsayo.listo;
    final controller = context.read<EnsayoController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esListo ? 'Marcar como Pendiente' : 'Marcar como Listo'),
        content: Text(
          esListo
              ? '¿Confirmas marcar este ensayo como pendiente?'
              : '¿Confirmas marcar este ensayo como listo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: Text(esListo ? 'Marcar Pendiente' : 'Marcar Listo'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = esListo
        ? await controller.marcarComoPendiente(_ensayo!.id)
        : await controller.marcarComoListo(_ensayo!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Estado actualizado exitosamente' : controller.errorMsg),
        backgroundColor: success ? Colors.green : AppColors.primary,
      ));
      if (success) _cargarDetalle();
    }
  }

  Future<void> _confirmEliminar() async {
    if (_ensayo == null) return;
    final controller = context.read<EnsayoController>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Ensayo'),
        content: Text(
          '¿Estás seguro de eliminar el ensayo "${_ensayo!.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await controller.eliminar(_ensayo!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Ensayo eliminado exitosamente' : controller.errorMsg),
        backgroundColor: success ? Colors.red : AppColors.primary,
      ));
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _ensayo != null ? 'Ensayo #${_ensayo!.id}' : 'Detalle del Ensayo',
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
        actions: [
          if (_ensayo != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      _ensayo!.estado == EstadoEnsayo.listo
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(_ensayo!.estado == EstadoEnsayo.listo
                        ? 'Marcar como Pendiente'
                        : 'Marcar como Listo'),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
              onSelected: (v) {
                if (v == 'toggle') _toggleEstado();
                if (v == 'eliminar') _confirmEliminar();
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
            child: const Text('Reintentar'),
          ),
        ]),
      );
    }
    if (_ensayo == null) {
      return const Center(child: Text('Ensayo no encontrado'));
    }

    final e = _ensayo!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Banner estado ──────────────────────────────────────────────────
        _EstadoBanner(ensayo: e),
        const SizedBox(height: 16),

        // ── Información del evento ─────────────────────────────────────────
        _Seccion(
            titulo: 'Información del Ensayo',
            icono: Icons.music_note_outlined,
            children: [
              _Fila(label: 'Nombre', valor: e.nombre),
              _Fila(
                label: 'Fecha',
                valor: DateFormat('dd/MM/yyyy').format(e.fechaHora),
              ),
              _Fila(
                label: 'Hora',
                valor: DateFormat('HH:mm').format(e.fechaHora),
              ),
              _Fila(label: 'Lugar', valor: e.lugar),
              if (e.ubicacion != null && e.ubicacion!.isNotEmpty)
                _Fila(label: 'Ubicación', valor: e.ubicacion!),
              if (e.createdAt != null)
                _Fila(
                  label: 'Creado el',
                  valor: DateFormat('dd/MM/yyyy').format(e.createdAt!),
                ),
            ]),
        const SizedBox(height: 12),

        // ── Repertorio ─────────────────────────────────────────────────────
        if (e.repertorios.isNotEmpty) ...[
          _Seccion(
            titulo:
                'Repertorio (${e.repertorios.length} canción${e.repertorios.length != 1 ? 'es' : ''})',
            icono: Icons.queue_music_outlined,
            children: e.repertorios.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final rep = entry.value;
              return _RepertorioFila(index: index, rep: rep);
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 12),
      ]),
    );
  }
}

// ─── BANNER ───────────────────────────────────────────────────────────────────

class _EstadoBanner extends StatelessWidget {
  final Ensayo ensayo;
  const _EstadoBanner({required this.ensayo});

  Color get _bg => ensayo.estado == EstadoEnsayo.listo
      ? const Color(0xFFDCFCE7)
      : const Color(0xFFFEF3C7);

  Color get _fg => ensayo.estado == EstadoEnsayo.listo
      ? const Color(0xFF047857)
      : const Color(0xFFB45309);

  IconData get _icon => ensayo.estado == EstadoEnsayo.listo
      ? Icons.check_circle_outline
      : Icons.hourglass_empty_rounded;

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
          Text(
            ensayo.estado == EstadoEnsayo.listo ? 'Listo' : 'Pendiente',
            style: TextStyle(
                color: _fg, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          Text(
            ensayo.nombre,
            style: TextStyle(
                color: _fg.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
        const Spacer(),
        Text('#${ensayo.id}',
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
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.text)),
            ),
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
  const _Fila({required this.label, required this.valor});

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
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ─── FILA REPERTORIO ──────────────────────────────────────────────────────────

class _RepertorioFila extends StatelessWidget {
  final int index;
  final Repertorio rep;
  const _RepertorioFila({required this.index, required this.rep});

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
            child: Text('$index',
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
            Text(rep.titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.text)),
            Text(rep.artista,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        if (rep.duracion.isNotEmpty)
          Text(rep.duracion,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}
