import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../ui/screen_header.dart';
import 'venta_controller.dart';
import 'venta_detalle_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _search = TextEditingController();
  late VentaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<VentaController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cargar();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) => _controller.buscar(query);

  Future<void> _showDetalle(Venta v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaDetalleScreen(venta: v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VentaController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  icono: Icons.shopping_bag_outlined,
                  titulo: 'Ventas',
                  subtitulo: 'Historial de ventas',
                  hintBuscar: 'Buscar venta...',
                  searchController: _search,
                  onSearch: _onSearch,
                  filtros: [
                    FilterChipData(
                      label: 'Todas',
                      bgColor: const Color(0xFFE2E8F0),
                      fgColor: const Color(0xFF475569),
                      selected: controller.estadoFiltro == null,
                      onTap: () => controller.filtrarPorEstado(null),
                    ),
                    FilterChipData(
                      label: 'Pendiente',
                      bgColor: const Color(0xFFFEF3C7),
                      fgColor: const Color(0xFFB45309),
                      selected:
                          controller.estadoFiltro == EstadoVenta.pendiente,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoVenta.pendiente),
                    ),
                    FilterChipData(
                      label: 'Completada',
                      bgColor: const Color(0xFFDCFCE7),
                      fgColor: const Color(0xFF047857),
                      selected:
                          controller.estadoFiltro == EstadoVenta.completada,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoVenta.completada),
                    ),
                    FilterChipData(
                      label: 'Cancelada',
                      bgColor: const Color(0xFFFEE2E2),
                      fgColor: const Color(0xFFB91C1C),
                      selected:
                          controller.estadoFiltro == EstadoVenta.cancelada,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoVenta.cancelada),
                    ),
                  ],
                ),
                Expanded(child: _buildContent(controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(VentaController controller) {
    return switch (controller.status) {
      VentaStatus.inicial =>
        const Center(child: Text('Presiona el botón para cargar ventas')),
      VentaStatus.cargando => const Center(child: CircularProgressIndicator()),
      VentaStatus.error => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(controller.errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: controller.cargar, child: const Text('Reintentar')),
          ]),
        ),
      VentaStatus.listo => controller.ventasMostradas.isEmpty
          ? const Center(child: Text('No se encontraron ventas.'))
          : ListView.separated(
              itemCount: controller.ventasMostradas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _VentaCard(
                venta: controller.ventasMostradas[i],
                onDetalle: () => _showDetalle(controller.ventasMostradas[i]),
              ),
            ),
    };
  }
}

// ─── VENTA CARD ────────────────────────────────────────────────────────────────

class _VentaCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback onDetalle;

  const _VentaCard({required this.venta, required this.onDetalle});

  Color _pillBg() => switch (venta.estadoEnum) {
        EstadoVenta.pendiente => const Color(0xFFFEF3C7),
        EstadoVenta.completada => const Color(0xFFDCFCE7),
        EstadoVenta.cancelada => const Color(0xFFFEE2E2),
      };

  Color _pillFg() => switch (venta.estadoEnum) {
        EstadoVenta.pendiente => const Color(0xFFB45309),
        EstadoVenta.completada => const Color(0xFF047857),
        EstadoVenta.cancelada => const Color(0xFFB91C1C),
      };

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
            // ── Encabezado ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          venta.concepto ?? 'Venta #${venta.idRaw}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(venta.clienteNombre,
                          style: const TextStyle(color: AppColors.textMuted)),
                      if (venta.homenajeado != null &&
                          venta.homenajeado!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Para: ${venta.homenajeado}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
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
                  child: Text(venta.estadoLabel,
                      style: TextStyle(
                        color: _pillFg(),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      )),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'detalle',
                      child: Row(children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Ver Detalle'),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'detalle') onDetalle();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Fecha y datos del evento ────────────────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_outlined,
                    '${venta.fechaVenta.day}/${venta.fechaVenta.month}/${venta.fechaVenta.year}'),
                if (venta.horaInicio != null && venta.horaFin != null)
                  _info(
                      Icons.schedule, '${venta.horaInicio} - ${venta.horaFin}'),
                if (venta.ubicacion != null && venta.ubicacion!.isNotEmpty)
                  _info(Icons.place_outlined, venta.ubicacion!),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Servicios (chips) ──────────────────────────────────────────
            if (venta.servicios.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: venta.servicios
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            s.cantidad > 1
                                ? '${s.nombre} x${s.cantidad}'
                                : s.nombre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],

            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Financiero ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Valor Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(formatCop(venta.totalValor.round()),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.text)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Pendiente',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text(
                          formatCop(venta.saldoPendiente.round()),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: venta.saldoPendiente > 0
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF047857),
                          ),
                        ),
                        if (venta.saldoPendiente == 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('PAGADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                )),
                          ),
                        ],
                      ]),
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
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569))),
        ),
      ],
    );
  }
}
