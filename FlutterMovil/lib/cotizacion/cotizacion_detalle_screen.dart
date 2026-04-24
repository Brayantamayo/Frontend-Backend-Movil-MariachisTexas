import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'cotizacion_controller.dart';

class CotizacionDetalleScreen extends StatefulWidget {
  final int cotizacionId;

  const CotizacionDetalleScreen({
    super.key,
    required this.cotizacionId,
  });

  @override
  State<CotizacionDetalleScreen> createState() =>
      _CotizacionDetalleScreenState();
}

class _CotizacionDetalleScreenState extends State<CotizacionDetalleScreen> {
  Cotizacion? _cotizacion;
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

    final controller = context.read<CotizacionController>();
    final cotizacion = await controller.getDetalle(widget.cotizacionId);

    setState(() {
      _loading = false;
      if (cotizacion != null) {
        _cotizacion = cotizacion;
      } else {
        _error = controller.errorMsg.isNotEmpty
            ? controller.errorMsg
            : 'Error al cargar el detalle';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_cotizacion != null
            ? 'Cotización #${_cotizacion!.id}'
            : 'Detalle de Cotización'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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

    if (_cotizacion == null) {
      return const Center(child: Text('Cotización no encontrada'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInfoGeneral(),
          const SizedBox(height: 16),
          _buildContacto(),
          const SizedBox(height: 16),
          _buildServicios(),
          const SizedBox(height: 16),
          _buildRepertorio(),
          const SizedBox(height: 16),
          _buildTotal(),
          if (_cotizacion!.reserva != null) ...[
            const SizedBox(height: 16),
            _buildReserva(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final c = _cotizacion!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.tipoEventoLabel,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para: ${c.homenajeado}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(c.estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getEstadoColor(c.estado).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    c.estadoLabel,
                    style: TextStyle(
                      color: _getEstadoColor(c.estado),
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
            _infoRow(Icons.person_outline, 'Cliente', c.clienteNombre),
            const SizedBox(height: 8),
            _infoRow(
              Icons.calendar_month_outlined,
              'Fecha del Evento',
              '${c.fechaEvento.day}/${c.fechaEvento.month}/${c.fechaEvento.year}',
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.schedule, 'Horario', '${c.horaInicio} - ${c.horaFin}'),
            const SizedBox(height: 8),
            _infoRow(Icons.place_outlined, 'Lugar', c.ubicacion),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeneral() {
    final c = _cotizacion!;
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
            if (c.notas != null && c.notas!.isNotEmpty) ...[
              _detailItem('Notas Adicionales', c.notas!),
              const SizedBox(height: 12),
            ],
            _detailItem(
              'Fecha de Creación',
              '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
            ),
            const SizedBox(height: 8),
            _detailItem('Reserva Directa', c.esReservaDirecta ? 'Sí' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildContacto() {
    final c = _cotizacion!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _detailItem('Nombre', c.clienteNombre),
            const SizedBox(height: 8),
            _detailItem('Email', c.clienteEmail),
            const SizedBox(height: 8),
            _detailItem('Teléfono', c.clienteTelefono),
          ],
        ),
      ),
    );
  }

  Widget _buildServicios() {
    final c = _cotizacion!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicios (${c.servicios.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ...c.servicios.map(
              (servicio) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.servicio.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (servicio.servicio.descripcion != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              servicio.servicio.descripcion!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cant: ${servicio.cantidad}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          formatCop(servicio.subtotal.round()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepertorio() {
    final c = _cotizacion!;
    if (c.repertorios.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repertorio (${c.repertorios.length} canciones)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ...c.repertorios.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.orden}',
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
                            item.repertorio.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            item.repertorio.artista,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // duracion is non-nullable String, show if not empty
                    if (item.repertorio.duracion.isNotEmpty)
                      Text(
                        item.repertorio.duracion,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotal() {
    final c = _cotizacion!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen Financiero',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL ESTIMADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.totalEstimado != null
                        ? formatCop(c.totalEstimado!.round())
                        : 'No calculado',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReserva() {
    final reserva = _cotizacion!.reserva!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bookmark_added, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Reserva Asociada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailItem('ID de Reserva', '#${reserva.id}'),
            const SizedBox(height: 8),
            _detailItem('Estado', reserva.estadoLabel),
            const SizedBox(height: 8),
            _detailItem('Valor Total', formatCop(reserva.totalValor.round())),
            const SizedBox(height: 8),
            _detailItem('Saldo Pendiente', formatCop(reserva.saldoPendiente.round())),
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

  Color _getEstadoColor(EstadoCotizacion estado) {
    return switch (estado) {
      EstadoCotizacion.enEspera   => const Color(0xFFB45309),
      EstadoCotizacion.convertida => const Color(0xFF047857),
      EstadoCotizacion.anulada    => const Color(0xFFB91C1C),
    };
  }
}