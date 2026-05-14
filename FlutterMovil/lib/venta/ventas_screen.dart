import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/format/time.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../ui/screen_header.dart';
import '../reserva/editar_reserva_screen.dart';
import 'venta_controller.dart';
import 'venta_detalle_screen.dart';
import 'venta_pdf.dart';

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

  Future<void> _descargarPdf(Venta v) async {
    try {
      await descargarVentaPdf(v);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  Future<void> _showDetalle(Venta v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaDetalleScreen(venta: v)),
    );
  }

  Future<void> _editarVenta(Venta v) async {
    // Construir una Reserva temporal desde los datos de la venta para editar
    final reserva = Reserva(
      id: v.id,
      cotizacionId: 0,
      estado: 'CONFIRMADA',
      totalValor: v.totalValor,
      saldoPendiente: v.saldoPendiente,
      clienteNombre: v.clienteNombre,
      clienteEmail: v.clienteEmail,
      clienteTelefono: v.clienteTelefono,
      homenajeado: v.homenajeado ?? '',
      tipoEvento: v.tipoEvento ?? '',
      fechaEvento: v.fechaEvento ?? DateTime.now(),
      horaInicio: v.horaInicio ?? '',
      horaFin: v.horaFin ?? '',
      ubicacion: v.ubicacion ?? '',
      abonos: v.abonos,
      chips: v.servicios
          .map((s) => VentaServicio(
              nombre: s.nombre, cantidad: s.cantidad, precio: s.precio))
          .toList(),
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarReservaScreen(reserva: reserva)),
    );
    if (result == true) _controller.cargar();
  }

  Future<void> _confirmAnular(Venta v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular Venta'),
        content: Text(
            '¿Estás seguro de anular la venta #${v.id}?\n\nCliente: ${v.clienteNombre}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _controller.anularVenta(v.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(success ? 'Venta anulada exitosamente' : _controller.errorMsg),
        backgroundColor: success ? Colors.orange : AppColors.primary,
      ));
    }
  }

  Future<void> _showAbono(Venta v) async {
    final saldo = v.saldoPendiente;
    final pagado = v.totalValor - saldo;
    final esPrimerAbono = pagado == 0;
    final anticipo50 = (v.totalValor / 2).ceilToDouble();
    double? montoSeleccionado;
    String metodo = 'EFECTIVO';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Registrar Abono'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _abonoRow('Total', formatCop(v.totalValor.round())),
                      if (!esPrimerAbono)
                        _abonoRow('Pagado', formatCop(pagado.round()),
                            color: const Color(0xFF047857)),
                      _abonoRow('Saldo pendiente', formatCop(saldo.round()),
                          color: const Color(0xFFB91C1C), bold: true),
                    ]),
              ),
              const SizedBox(height: 16),
              if (esPrimerAbono) ...[
                const Text('Selecciona el monto:',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _montoBtn(
                    label: '50%',
                    sublabel: formatCop(anticipo50.round()),
                    selected: montoSeleccionado == anticipo50,
                    onTap: () => setS(() => montoSeleccionado = anticipo50),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _montoBtn(
                    label: '100%',
                    sublabel: formatCop(saldo.round()),
                    selected: montoSeleccionado == saldo,
                    onTap: () => setS(() => montoSeleccionado = saldo),
                  )),
                ]),
              ] else ...[
                _montoBtn(
                  label: '100% restante',
                  sublabel: formatCop(saldo.round()),
                  selected: true,
                  onTap: () {},
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: metodo,
                decoration: const InputDecoration(
                    labelText: 'Método de pago', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                  DropdownMenuItem(
                      value: 'TRANSFERENCIA', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'NEQUI', child: Text('Nequi')),
                  DropdownMenuItem(
                      value: 'DAVIPLATA', child: Text('Daviplata')),
                  DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                ],
                onChanged: (val) => setS(() => metodo = val ?? 'EFECTIVO'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: (montoSeleccionado != null || !esPrimerAbono)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final monto = esPrimerAbono ? montoSeleccionado! : saldo;
    final success = await _controller.registrarAbono(v.id,
        monto: monto, metodoPago: metodo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Abono registrado exitosamente' : _controller.errorMsg),
        backgroundColor: success ? Colors.green : AppColors.primary,
      ));
    }
  }

  static Widget _abonoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? AppColors.text)),
      ]),
    );
  }

  static Widget _montoBtn({
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.text)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textMuted)),
        ]),
      ),
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
                      label: 'Confirmado',
                      bgColor: const Color(0xFFDCFCE7),
                      fgColor: const Color(0xFF047857),
                      selected:
                          controller.estadoFiltro == EstadoVenta.confirmado,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoVenta.confirmado),
                    ),
                    FilterChipData(
                      label: 'Finalizado',
                      bgColor: const Color(0xFFDBEAFE),
                      fgColor: const Color(0xFF1D4ED8),
                      selected:
                          controller.estadoFiltro == EstadoVenta.finalizado,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoVenta.finalizado),
                    ),
                    FilterChipData(
                      label: 'Anulada',
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
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => controller.cargar(),
              child: ListView.separated(
                itemCount: controller.ventasMostradas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final v = controller.ventasMostradas[i];
                  return _VentaCard(
                    venta: v,
                    onDetalle: () => _showDetalle(v),
                    onPdf: () => _descargarPdf(v),
                    onAbono: v.estadoEnum == EstadoVenta.confirmado &&
                            v.saldoPendiente > 0 &&
                            v.clienteNombre.isNotEmpty
                        ? () => _showAbono(v)
                        : null,
                    onEditar: v.estadoEnum == EstadoVenta.confirmado
                        ? () => _editarVenta(v)
                        : null,
                    onAnular: v.estadoEnum == EstadoVenta.confirmado
                        ? () => _confirmAnular(v)
                        : null,
                  );
                },
              ),
            ),
    };
  }
}

// ─── VENTA CARD ────────────────────────────────────────────────────────────────

class _VentaCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback onDetalle;
  final VoidCallback onPdf;
  final VoidCallback? onAbono;
  final VoidCallback? onEditar;
  final VoidCallback? onAnular;

  const _VentaCard({
    required this.venta,
    required this.onDetalle,
    required this.onPdf,
    required this.onAbono,
    required this.onEditar,
    required this.onAnular,
  });

  Color _pillBg() => switch (venta.estadoEnum) {
        EstadoVenta.confirmado => const Color(0xFFDCFCE7),
        EstadoVenta.finalizado => const Color(0xFFDBEAFE),
        EstadoVenta.cancelada => const Color(0xFFFEE2E2),
      };

  Color _pillFg() => switch (venta.estadoEnum) {
        EstadoVenta.confirmado => const Color(0xFF047857),
        EstadoVenta.finalizado => const Color(0xFF1D4ED8),
        EstadoVenta.cancelada => const Color(0xFFB91C1C),
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetalle,
      borderRadius: BorderRadius.circular(18),
      child: Card(
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
                          Text(
                            '#${venta.id}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Venta',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
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
                    itemBuilder: (_) {
                      final items = <PopupMenuEntry<String>>[];
                      // 1. Ver detalle — siempre
                      items.add(const PopupMenuItem(
                        value: 'detalle',
                        child: Row(children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ver Detalle'),
                        ]),
                      ));
                      // Solo Confirmado
                      if (venta.estadoEnum == EstadoVenta.confirmado) {
                        // 2. Registrar abono
                        if (onAbono != null)
                          items.add(const PopupMenuItem(
                            value: 'abono',
                            child: Row(children: [
                              Icon(Icons.payments_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Registrar Abono'),
                            ]),
                          ));
                        // 3. Descargar PDF
                        items.add(const PopupMenuItem(
                          value: 'pdf',
                          child: Row(children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                size: 18, color: Color(0xFFB91C1C)),
                            SizedBox(width: 8),
                            Text('Descargar PDF',
                                style: TextStyle(color: Color(0xFFB91C1C))),
                          ]),
                        ));
                        // 4. Editar
                        if (onEditar != null)
                          items.add(const PopupMenuItem(
                            value: 'editar',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ]),
                          ));
                        // 5. Anular
                        if (onAnular != null) {
                          items.add(const PopupMenuDivider());
                          items.add(const PopupMenuItem(
                            value: 'anular',
                            child: Row(children: [
                              Icon(Icons.cancel_outlined,
                                  size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Anular',
                                  style: TextStyle(color: Colors.orange)),
                            ]),
                          ));
                        }
                      } else {
                        // Finalizado y Anulada: solo PDF
                        items.add(const PopupMenuItem(
                          value: 'pdf',
                          child: Row(children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                size: 18, color: Color(0xFFB91C1C)),
                            SizedBox(width: 8),
                            Text('Descargar PDF',
                                style: TextStyle(color: Color(0xFFB91C1C))),
                          ]),
                        ));
                      }
                      return items;
                    },
                    onSelected: (v) {
                      switch (v) {
                        case 'detalle':
                          onDetalle();
                        case 'abono':
                          onAbono?.call();
                        case 'editar':
                          onEditar?.call();
                        case 'anular':
                          onAnular?.call();
                        case 'pdf':
                          onPdf();
                      }
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
                  _info(
                      Icons.calendar_month_outlined,
                      venta.fechaEvento != null
                          ? '${venta.fechaEvento!.day}/${venta.fechaEvento!.month}/${venta.fechaEvento!.year}'
                          : '${venta.fechaVenta.day}/${venta.fechaVenta.month}/${venta.fechaVenta.year}'),
                  if (venta.horaInicio != null && venta.horaFin != null)
                    _info(Icons.schedule,
                        '${formatHora24a12(venta.horaInicio!)} - ${formatHora24a12(venta.horaFin!)}'),
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
                            formatCop(venta.saldoMostrado.round()),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: venta.saldoMostrado > 0
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF047857),
                            ),
                          ),
                          if (venta.saldoMostrado == 0) ...[
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
