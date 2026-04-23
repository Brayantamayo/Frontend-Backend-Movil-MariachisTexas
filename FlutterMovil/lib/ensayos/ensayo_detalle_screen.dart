import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import 'ensayo_controller.dart';

class EnsayoDetalleScreen extends StatefulWidget {
  final int ensayoId;

  const EnsayoDetalleScreen({
    super.key,
    required this.ensayoId,
  });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Estado actualizado exitosamente' : controller.errorMsg,
          ),
          backgroundColor: success ? Colors.green : AppColors.primary,
        ),
      );
      if (success) {
        // Recargar detalle para reflejar el nuevo estado
        _cargarDetalle();
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Ensayo eliminado exitosamente' : controller.errorMsg,
          ),
          backgroundColor: success ? Colors.red : AppColors.primary,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          _ensayo != null ? 'Ensayo #${_ensayo!.id}' : 'Detalle del Ensayo',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_ensayo != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        _ensayo!.estado == EstadoEnsayo.listo
                            ? Icons.pending_outlined
                            : Icons.check_circle_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ensayo!.estado == EstadoEnsayo.listo
                            ? 'Marcar como Pendiente'
                            : 'Marcar como Listo',
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _cargarDetalle,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_ensayo == null) {
      return const Center(child: Text('Ensayo no encontrado'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInfoGeneral(),
          if (_ensayo!.repertorios.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRepertorio(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final e = _ensayo!;
    final listo = e.estado == EstadoEnsayo.listo;
    final estadoColor =
        listo ? const Color(0xFF047857) : const Color(0xFFB45309);
    final estadoBg =
        listo ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.nombre,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: listo ? AppColors.textMuted : AppColors.text,
                      decoration: listo
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: estadoColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    e.estadoLabel.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow(
              Icons.calendar_month_outlined,
              'Fecha',
              DateFormat('dd/MM/yyyy').format(e.fechaHora),
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.schedule,
              'Hora',
              DateFormat('HH:mm').format(e.fechaHora),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.place_outlined, 'Lugar', e.lugar),
            if (e.ubicacion != null && e.ubicacion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.map_outlined, 'Ubicación', e.ubicacion!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeneral() {
    final e = _ensayo!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _detailItem('ID del Ensayo', '#${e.id}'),
            const SizedBox(height: 8),
            _detailItem('Nombre', e.nombre),
            const SizedBox(height: 8),
            _detailItem(
              'Fecha y Hora',
              DateFormat('dd/MM/yyyy - HH:mm').format(e.fechaHora),
            ),
            const SizedBox(height: 8),
            _detailItem('Lugar', e.lugar),
            if (e.ubicacion != null && e.ubicacion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailItem('Ubicación', e.ubicacion!),
            ],
            if (e.createdAt != null) ...[
              const SizedBox(height: 8),
              _detailItem(
                'Fecha de Creación',
                DateFormat('dd/MM/yyyy - HH:mm').format(e.createdAt!),
              ),
            ],
            if (e.updatedAt != null) ...[
              const SizedBox(height: 8),
              _detailItem(
                'Última Actualización',
                DateFormat('dd/MM/yyyy - HH:mm').format(e.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRepertorio() {
    final e = _ensayo!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repertorio (${e.repertorios.length} canción${e.repertorios.length != 1 ? 'es' : ''})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ...e.repertorios.asMap().entries.map(
              (entry) {
                final index = entry.key + 1;
                final rep = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              rep.artista,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (rep.duracion.isNotEmpty)
                        Text(
                          rep.duracion,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
