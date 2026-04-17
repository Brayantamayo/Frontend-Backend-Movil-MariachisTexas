import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'cotizacion.model.dart';
import 'cotizacion_controller.dart';
import 'cotizacion_detalle_screen.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  final _search = TextEditingController();
  late CotizacionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CotizacionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cargar();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    await _controller.buscar(query);
  }

  Future<void> _showDetalle(Cotizacion c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CotizacionDetalleScreen(cotizacionId: c.id),
      ),
    );
  }

  Future<void> _confirmConvertir(Cotizacion c) async {
    if (!c.puedeConvertirse) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convertir a Reserva'),
        content: Text(
          '¿Confirmas convertir la cotización #${c.id} a reserva?\n\n'
          'Total: ${formatCop(c.totalEstimado?.round() ?? 0)}\n'
          'Cliente: ${c.clienteNombre}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(AppColors.primary),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convertir'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await _controller.convertirAReserva(c.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cotización convertida a reserva exitosamente'
                : _controller.errorMsg,
          ),
          backgroundColor:
              success ? Colors.green : const Color(AppColors.primary),
        ),
      );
    }
  }

  Future<void> _confirmAnular(Cotizacion c) async {
    if (!c.puedeAnularse) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular Cotización'),
        content: Text('¿Estás seguro de anular la cotización #${c.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(AppColors.primary),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await _controller.anular(c.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Cotización anulada exitosamente' : _controller.errorMsg,
          ),
          backgroundColor:
              success ? Colors.orange : const Color(AppColors.primary),
        ),
      );
    }
  }

  Future<void> _confirmEliminar(Cotizacion c) async {
    if (!c.puedeEliminarse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar una cotización con reserva'),
          backgroundColor: Color(AppColors.primary),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cotización'),
        content: Text(
          '¿Estás seguro de eliminar la cotización #${c.id}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(AppColors.primary),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await _controller.eliminar(c.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cotización eliminada exitosamente'
                : _controller.errorMsg,
          ),
          backgroundColor:
              success ? Colors.red : const Color(AppColors.primary),
        ),
      );
    }
  }

  Future<void> _verPDF(Cotizacion c) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Descargando PDF...'),
          ],
        ),
      ),
    );

    try {
      final success = await _controller.descargarPDF(c.id);

      // Cerrar indicador de carga
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF descargado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMsg.isNotEmpty
                ? _controller.errorMsg
                : 'Error al descargar PDF'),
            backgroundColor: const Color(AppColors.primary),
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga en caso de error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar PDF: $e'),
            backgroundColor: const Color(AppColors.primary),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CotizacionController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cotizaciones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(AppColors.text),
                  ),
                ),
                const SizedBox(height: 14),

                // Barra de búsqueda
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar cotización...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearch,
                ),

                const SizedBox(height: 14),

                // Contenido principal
                Expanded(
                  child: _buildContent(controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(CotizacionController controller) {
    return switch (controller.status) {
      CotizacionStatus.inicial => const Center(
          child: Text('Presiona el botón para cargar cotizaciones'),
        ),
      CotizacionStatus.cargando => const Center(
          child: CircularProgressIndicator(),
        ),
      CotizacionStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
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
      CotizacionStatus.listo => controller.cotizaciones.isEmpty
          ? const Center(
              child: Text('No se encontraron cotizaciones.'),
            )
          : ListView.separated(
              itemCount: controller.cotizaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _CotizacionCard(
                c: controller.cotizaciones[i],
                onDetalle: () => _showDetalle(controller.cotizaciones[i]),
                onConvertir: controller.cotizaciones[i].puedeConvertirse
                    ? () => _confirmConvertir(controller.cotizaciones[i])
                    : null,
                onAnular: controller.cotizaciones[i].puedeAnularse
                    ? () => _confirmAnular(controller.cotizaciones[i])
                    : null,
                onEliminar: () => _confirmEliminar(controller.cotizaciones[i]),
                onVerPDF: () => _verPDF(controller.cotizaciones[i]),
              ),
            ),
    };
  }
}

class _CotizacionCard extends StatelessWidget {
  final Cotizacion c;
  final VoidCallback onDetalle;
  final VoidCallback? onConvertir;
  final VoidCallback? onAnular;
  final VoidCallback onEliminar;
  final VoidCallback onVerPDF;

  const _CotizacionCard({
    required this.c,
    required this.onDetalle,
    required this.onConvertir,
    required this.onAnular,
    required this.onEliminar,
    required this.onVerPDF,
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
                            '#${c.id}',
                            style: const TextStyle(
                              color: Color(AppColors.textMuted),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.tipoEventoLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(AppColors.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.clienteNombre,
                        style: const TextStyle(
                          color: Color(AppColors.textMuted),
                        ),
                      ),
                      if (c.nombreHomenajeado.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Para: ${c.nombreHomenajeado}',
                          style: const TextStyle(
                            color: Color(AppColors.textMuted),
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
                    c.estadoLabel,
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
                    if (onConvertir != null)
                      const PopupMenuItem(
                        value: 'convertir',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_add_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Convertir a Reserva'),
                          ],
                        ),
                      ),
                    if (onAnular != null)
                      const PopupMenuItem(
                        value: 'anular',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Anular'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ver PDF'),
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
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'detalle':
                        onDetalle();
                        break;
                      case 'convertir':
                        onConvertir?.call();
                        break;
                      case 'anular':
                        onAnular?.call();
                        break;
                      case 'pdf':
                        onVerPDF();
                        break;
                      case 'eliminar':
                        onEliminar();
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información del evento
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_outlined,
                    '${c.fechaEvento.day}/${c.fechaEvento.month}/${c.fechaEvento.year}'),
                _info(Icons.schedule,
                    '${c.horaInicio.hour.toString().padLeft(2, '0')}:${c.horaInicio.minute.toString().padLeft(2, '0')}'),
                _info(Icons.place_outlined, c.direccionEvento),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Total y servicios
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Estimado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(AppColors.textMuted),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.totalEstimado != null
                            ? formatCop(c.totalEstimado!.round())
                            : 'No calculado',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(AppColors.text),
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
                        'Servicios',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(AppColors.textMuted),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.servicios.length} servicio${c.servicios.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.text),
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
        Icon(icon, size: 16, color: const Color(AppColors.textMuted)),
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
