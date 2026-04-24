import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import 'ensayo_controller.dart';
import 'ensayo_detalle_screen.dart';

class EnsayosScreen extends StatefulWidget {
  const EnsayosScreen({super.key});

  @override
  State<EnsayosScreen> createState() => _EnsayosScreenState();
}

class _EnsayosScreenState extends State<EnsayosScreen> {
  final _search = TextEditingController();
  late EnsayoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<EnsayoController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cargar();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _controller.buscar(query);
  }

  Future<void> _showDetalle(Ensayo e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnsayoDetalleScreen(ensayoId: e.id),
      ),
    );
  }

  Future<void> _toggleEstado(Ensayo e) async {
    final esListo = e.estado == EstadoEnsayo.listo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esListo ? 'Marcar como Pendiente' : 'Marcar como Listo'),
        content: Text(
          esListo
              ? '¿Confirmas marcar el ensayo "${e.nombre}" como pendiente?'
              : '¿Confirmas marcar el ensayo "${e.nombre}" como listo?',
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
        ? await _controller.marcarComoPendiente(e.id)
        : await _controller.marcarComoListo(e.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Estado actualizado exitosamente' : _controller.errorMsg,
          ),
          backgroundColor: success ? Colors.green : AppColors.primary,
        ),
      );
    }
  }

  Future<void> _confirmEliminar(Ensayo e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Ensayo'),
        content: Text(
          '¿Estás seguro de eliminar el ensayo "${e.nombre}"?\n\n'
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

    final success = await _controller.eliminar(e.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Ensayo eliminado exitosamente' : _controller.errorMsg,
          ),
          backgroundColor: success ? Colors.red : AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnsayoController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ensayos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar ensayo...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 14),
                Expanded(child: _buildContent(controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(EnsayoController controller) {
    return switch (controller.status) {
      EnsayoStatus.inicial => const Center(
          child: Text('Presiona el botón para cargar ensayos'),
        ),
      EnsayoStatus.cargando => const Center(
          child: CircularProgressIndicator(),
        ),
      EnsayoStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      EnsayoStatus.listo => controller.ensayos.isEmpty
          ? const Center(child: Text('No se encontraron ensayos.'))
          : ListView.separated(
              itemCount: controller.ensayos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _EnsayoCard(
                e: controller.ensayos[i],
                onDetalle: () => _showDetalle(controller.ensayos[i]),
                onToggle: () => _toggleEstado(controller.ensayos[i]),
                onEliminar: () => _confirmEliminar(controller.ensayos[i]),
              ),
            ),
    };
  }
}

// ─── CARD ─────────────────────────────────────────────────────────────────────

class _EnsayoCard extends StatelessWidget {
  final Ensayo e;
  final VoidCallback onDetalle;
  final VoidCallback onToggle;
  final VoidCallback onEliminar;

  const _EnsayoCard({
    required this.e,
    required this.onDetalle,
    required this.onToggle,
    required this.onEliminar,
  });

  Color _pillBg() {
    return e.estado == EstadoEnsayo.listo
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);
  }

  Color _pillFg() {
    return e.estado == EstadoEnsayo.listo
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);
  }

  @override
  Widget build(BuildContext context) {
    final listo = e.estado == EstadoEnsayo.listo;
    final fechaFormato = DateFormat('dd/MM/yyyy').format(e.fechaHora);
    final horaFormato = DateFormat('HH:mm').format(e.fechaHora);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
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
                          Text(
                            '#${e.id}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.nombre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: listo
                                    ? AppColors.textMuted
                                    : AppColors.text,
                                decoration: listo
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.lugar,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      if (e.repertorios.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${e.repertorios.length} canción${e.repertorios.length != 1 ? 'es' : ''}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pillBg(),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e.estadoLabel.toUpperCase(),
                    style: TextStyle(
                      color: _pillFg(),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'detalle',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ver Detalle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            listo
                                ? Icons.pending_outlined
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(listo
                              ? 'Marcar como Pendiente'
                              : 'Marcar como Listo'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'detalle':
                        onDetalle();
                      case 'toggle':
                        onToggle();
                      case 'eliminar':
                        onEliminar();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_outlined, fechaFormato),
                _info(Icons.schedule, horaFormato),
                _info(Icons.place_outlined, e.lugar),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha y Hora',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$fechaFormato a las $horaFormato',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repertorio',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.repertorios.isEmpty
                            ? 'Sin canciones'
                            : '${e.repertorios.length} canción${e.repertorios.length != 1 ? 'es' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
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

  static Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }
}
