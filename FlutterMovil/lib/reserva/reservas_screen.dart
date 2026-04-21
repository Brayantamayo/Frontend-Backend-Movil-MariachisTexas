import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format/currency.dart';
import '../core/theme/app_colors.dart';
import 'reserva.model.dart';
import 'reserva_controller.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _search = TextEditingController();
  late ReservaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ReservaController>();
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

  void _mostrarDetalle(BuildContext context, Reserva reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetalleReservaModal(reserva: reserva),
    );
  }

  void _mostrarDialogoAbono(BuildContext context, Reserva reserva) {
    final montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Abono'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo pendiente: ${formatCop(reserva.saldoPendiente?.round() ?? 0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto del abono',
                hintText: 'Ingresa el monto',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              //TODO: Implementar lógica de abono
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abono registrado')),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _anularReserva(BuildContext context, Reserva reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular Reserva'),
        content: const Text(
          '¿Estás seguro de que deseas anular esta reserva? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reserva anulada')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservaController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: (AppColors.text),
                  ),
                ),
                const SizedBox(height: 14),

                // Barra de búsqueda
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar reserva...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearch,
                ),

                const SizedBox(height: 14),

                // Contenido principal
                Expanded(
                  child: _buildContent(context, controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ReservaController controller) {
    return switch (controller.status) {
      ReservaStatus.inicial => const Center(
          child: Text('Presiona el botón para cargar reservas'),
        ),
      ReservaStatus.cargando => const Center(
          child: CircularProgressIndicator(),
        ),
      ReservaStatus.error => Center(
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
      ReservaStatus.listo => controller.reservas.isEmpty
          ? const Center(
              child: Text('No se encontraron reservas.'),
            )
          : ListView.separated(
              itemCount: controller.reservas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ReservaCard(
                reserva: controller.reservas[i],
                onVerDetalle: () =>
                    _mostrarDetalle(context, controller.reservas[i]),
                onAnular: () => _anularReserva(context, controller.reservas[i]),
                onAbono: () =>
                    _mostrarDialogoAbono(context, controller.reservas[i]),
              ),
            ),
    };
  }
}

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onVerDetalle;
  final VoidCallback onAnular;
  final VoidCallback onAbono;

  const _ReservaCard({
    required this.reserva,
    required this.onVerDetalle,
    required this.onAnular,
    required this.onAbono,
  });

  Color _getEstadoColor() {
    return const Color(0xFF047857); // Verde para reservas confirmadas
  }

  String _getTipoEvento(String tipo) {
    const tiposEvento = {
      'BODA': '💒 Boda',
      'CUMPLEANOS': '🎂 Cumpleaños',
      'QUINCEANIOS': '👗 Quinceaños',
      'FUNERAL': '⚫ Funeral',
      'RECONCILIACION': '💕 Reconciliación',
      'DIA_DE_MADRE': '👩 Día de Madre',
      'AMOR': '❤️ Amor',
      'ANIVERSARIO': '💍 Aniversario',
      'PADRES': '👨‍👩‍👧 Padres',
      'FIESTA': '🎉 Fiesta',
      'OTRO': '📌 Otro',
    };
    return tiposEvento[tipo] ?? tipo;
  }

  @override
  Widget build(BuildContext context) {
    final cotizacion = reserva.cotizacion;

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
            // Botón de abono en la parte superior
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAbono,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Hacer Abono'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header con ID y estado
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${reserva.id}',
                            style: const TextStyle(
                              color: (AppColors.textMuted),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cotizacion?.nombreHomenajeado ?? 'Reserva',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: (AppColors.text),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cotización #${reserva.cotizacionId}',
                        style: const TextStyle(
                          color: (AppColors.textMuted),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    reserva.estadoLabel,
                    style: TextStyle(
                      color: _getEstadoColor(),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Información del evento
            if (cotizacion != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de Evento',
                          style: TextStyle(
                            fontSize: 11,
                            color: (AppColors.textMuted),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTipoEvento(cotizacion.tipoEvento),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: (AppColors.text),
                            fontSize: 13,
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
                          'Fecha del Evento',
                          style: TextStyle(
                            fontSize: 11,
                            color: (AppColors.textMuted),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cotizacion.fechaEvento.day}/${cotizacion.fechaEvento.month}/${cotizacion.fechaEvento.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: (AppColors.text),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Ubicación: ${cotizacion.direccionEvento}',
                style: const TextStyle(
                  fontSize: 12,
                  color: (AppColors.textMuted),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
            ],

            // Información financiera
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valor Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: (AppColors.textMuted),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reserva.totalValor != null
                            ? formatCop(reserva.totalValor!.round())
                            : 'No especificado',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: (AppColors.text),
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
                        'Saldo Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          color: (AppColors.textMuted),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reserva.saldoPendiente != null
                            ? formatCop(reserva.saldoPendiente!.round())
                            : 'No especificado',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Información del cliente
            if (cotizacion?.cliente != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 12,
                      color: (AppColors.textMuted),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cotizacion!.cliente!.apellido,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (AppColors.text),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cotizacion.cliente!.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: (AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cotizacion.cliente!.telefonoPrincipal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: (AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],

            // Botones de acción
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVerDetalle,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver Detalle'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAnular,
                    icon: const Icon(Icons.close_outlined, size: 18),
                    label: const Text('Anular'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleReservaModal extends StatelessWidget {
  final Reserva reserva;

  const _DetalleReservaModal({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final cotizacion = reserva.cotizacion;

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detalle de Reserva',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              if (cotizacion != null) ...[
                _buildSection('Información del Evento', [
                  _buildRow('Homenajeado', cotizacion.nombreHomenajeado),
                  _buildRow('Tipo', cotizacion.tipoEvento),
                  _buildRow(
                    'Fecha',
                    '${cotizacion.fechaEvento.day}/${cotizacion.fechaEvento.month}/${cotizacion.fechaEvento.year}',
                  ),
                  _buildRow('Ubicación', cotizacion.direccionEvento),
                ]),
                const SizedBox(height: 16),
                _buildSection('Información Financiera', [
                  _buildRow(
                    'Valor Total',
                    formatCop(reserva.totalValor?.round() ?? 0),
                  ),
                  _buildRow(
                    'Saldo Pendiente',
                    formatCop(reserva.saldoPendiente?.round() ?? 0),
                  ),
                  _buildRow('Estado', reserva.estadoLabel),
                ]),
                const SizedBox(height: 16),
                if (cotizacion.cliente != null)
                  _buildSection('Información del Cliente', [
                    _buildRow('Nombre', cotizacion.cliente!.apellido),
                    _buildRow('Email', cotizacion.cliente!.email),
                    _buildRow(
                        'Teléfono', cotizacion.cliente!.telefonoPrincipal),
                  ]),
                const SizedBox(height: 16),
                if (cotizacion.repertorios.isNotEmpty)
                  _buildSection('Repertorio', [
                    ...cotizacion.repertorios.map((r) => _buildRow(
                          r.titulo,
                          '${r.artista} - ${r.genero}',
                        )),
                  ]),
                const SizedBox(height: 16),
                if (cotizacion.servicios.isNotEmpty)
                  _buildSection('Servicios', [
                    ...cotizacion.servicios.map((s) => _buildRow(
                          s.nombre,
                          '${s.cantidad}x - ${formatCop(s.precio.round())}',
                        )),
                  ]),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: (AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: (AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: (AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
