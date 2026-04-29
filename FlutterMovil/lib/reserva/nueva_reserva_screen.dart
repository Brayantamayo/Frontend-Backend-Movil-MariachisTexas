import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import '../core/services/servicio_service.dart';
import '../core/format/currency.dart';
import '../clientes/cliente_service.dart';
import '../reserva/reserva_controller.dart';

class NuevaReservaScreen extends StatefulWidget {
  const NuevaReservaScreen({super.key});

  @override
  State<NuevaReservaScreen> createState() => _NuevaReservaScreenState();
}

class _NuevaReservaScreenState extends State<NuevaReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteNombreCtrl = TextEditingController();
  final _clienteEmailCtrl = TextEditingController();
  final _clienteTelefonoCtrl = TextEditingController();
  final _homenajeadoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  TipoEvento _tipoEvento = TipoEvento.otro;
  DateTime _fechaEvento = DateTime.now().add(const Duration(days: 7));
  TimeOfDay? _horaInicio;

  bool _guardando = false;
  List<Cliente> _clientes = [];
  bool _cargandoClientes = false;
  Cliente? _clienteSeleccionado;

  List<Servicio> _serviciosDisponibles = [];
  final Map<int, int> _serviciosSeleccionados = {}; // servicioId -> cantidad
  bool _cargandoServicios = false;

  List<String> _horasDisponibles = [];
  bool _verificandoDisponibilidad = false;

  // ── Getters computados ────────────────────────────────────────────────────

  /// Detecta si un servicio es "hora extra" por su nombre
  bool _esServicioHoraExtra(Servicio s) {
    final nombre = s.nombre.toLowerCase();
    return nombre.contains('hora extra') ||
        nombre.contains('hora adicional') ||
        nombre.contains('hora suplementaria');
  }

  /// Horas extras seleccionadas (suma de cantidades de servicios hora extra)
  int get _horasExtrasSeleccionadas {
    int total = 0;
    for (final entry in _serviciosSeleccionados.entries) {
      final svc =
          _serviciosDisponibles.where((s) => s.id == entry.key).firstOrNull;
      if (svc != null && _esServicioHoraExtra(svc)) {
        total += entry.value;
      }
    }
    return total;
  }

  /// Duración total = 1h base + horas extras seleccionadas
  int get _duracionHoras => 1 + _horasExtrasSeleccionadas;

  /// Hora fin calculada
  TimeOfDay? get _horaFinCalculada {
    if (_horaInicio == null) return null;
    return TimeOfDay(
      hour: (_horaInicio!.hour + _duracionHoras) % 24,
      minute: _horaInicio!.minute,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _cargarServicios();
    _verificarDisponibilidad();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargandoClientes = true);
    try {
      _clientes = await ClienteService.obtenerClientes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    setState(() => _cargandoClientes = false);
  }

  Future<void> _cargarServicios() async {
    setState(() => _cargandoServicios = true);
    try {
      _serviciosDisponibles = await ServicioService.obtenerServicios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    setState(() => _cargandoServicios = false);
  }

  Future<void> _verificarDisponibilidad() async {
    setState(() => _verificandoDisponibilidad = true);
    try {
      final controller = context.read<ReservaController>();
      _horasDisponibles =
          await controller.obtenerHorasDisponibles(_fechaEvento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar disponibilidad: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Si hay error, generar horas por defecto
      _horasDisponibles = _generarHorasPorDefecto();
    }
    setState(() => _verificandoDisponibilidad = false);
  }

  List<String> _generarHorasPorDefecto() {
    // Generar horas de 8:00 AM a 11:00 PM cada hora
    final horas = <String>[];
    for (int h = 8; h <= 23; h++) {
      horas.add('${h.toString().padLeft(2, '0')}:00');
    }
    return horas;
  }

  void _seleccionarCliente(Cliente cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteNombreCtrl.text = cliente.nombreCompleto;
      _clienteEmailCtrl.text = cliente.email ?? '';
      _clienteTelefonoCtrl.text = cliente.telefonoPrincipal ?? '';
    });
  }

  // Servicios mutuamente excluyentes por nombre
  static bool _esSerenataUrbana(String nombre) =>
      nombre.toLowerCase().contains('urbana');

  static bool _esSerenataRural(String nombre) =>
      nombre.toLowerCase().contains('rural');

  void _toggleServicio(Servicio servicio) {
    setState(() {
      if (_serviciosSeleccionados.containsKey(servicio.id)) {
        // Deseleccionar
        _serviciosSeleccionados.remove(servicio.id);
      } else {
        // Seleccionar — quitar el opuesto si aplica
        if (_esSerenataUrbana(servicio.nombre)) {
          // Quitar cualquier serenata rural seleccionada
          _serviciosDisponibles
              .where((s) => _esSerenataRural(s.nombre))
              .forEach((s) => _serviciosSeleccionados.remove(s.id));
        } else if (_esSerenataRural(servicio.nombre)) {
          // Quitar cualquier serenata urbana seleccionada
          _serviciosDisponibles
              .where((s) => _esSerenataUrbana(s.nombre))
              .forEach((s) => _serviciosSeleccionados.remove(s.id));
        }
        _serviciosSeleccionados[servicio.id] = 1;
      }
    });
  }

  void _actualizarCantidad(int servicioId, int cantidad) {
    setState(() {
      if (cantidad <= 0) {
        _serviciosSeleccionados.remove(servicioId);
        return;
      }
      // Serenata urbana y rural: máximo 1
      final svc =
          _serviciosDisponibles.where((s) => s.id == servicioId).firstOrNull;
      if (svc != null &&
          (_esSerenataUrbana(svc.nombre) || _esSerenataRural(svc.nombre))) {
        _serviciosSeleccionados[servicioId] = 1;
        return;
      }
      _serviciosSeleccionados[servicioId] = cantidad;
    });
  }

  double get _totalCalculado {
    double total = 0;
    for (final entry in _serviciosSeleccionados.entries) {
      final servicio =
          _serviciosDisponibles.firstWhere((s) => s.id == entry.key);
      total += servicio.precio * entry.value;
    }
    return total;
  }

  @override
  void dispose() {
    _clienteNombreCtrl.dispose();
    _clienteEmailCtrl.dispose();
    _clienteTelefonoCtrl.dispose();
    _homenajeadoCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEvento,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha != null) {
      setState(() {
        _fechaEvento = fecha;
        _horaInicio = null; // Limpiar hora seleccionada
      });
      // Verificar disponibilidad para la nueva fecha
      await _verificarDisponibilidad();
    }
  }

  Future<void> _seleccionarHoraInicio() async {
    // Todas las horas posibles 08:00 – 23:00
    final todasLasHoras = <String>[];
    for (int h = 8; h <= 23; h++) {
      todasLasHoras.add('${h.toString().padLeft(2, '0')}:00');
    }

    final horaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Hora de Inicio'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leyenda
              Row(children: [
                _leyendaDot(const Color(0xFF047857)),
                const SizedBox(width: 6),
                const Text('Disponible', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                _leyendaDot(const Color(0xFFB45309)),
                const SizedBox(width: 6),
                const Text('Hora extra', style: TextStyle(fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: todasLasHoras.length,
                  itemBuilder: (context, index) {
                    final hora = todasLasHoras[index];
                    final esDisponible = _horasDisponibles.contains(hora);
                    final esSeleccionada = _horaInicio != null &&
                        '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}' ==
                            hora;

                    final Color bgColor = esSeleccionada
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent;
                    final Color textColor = esSeleccionada
                        ? AppColors.primary
                        : esDisponible
                            ? AppColors.text
                            : const Color(0xFFB45309);

                    return ListTile(
                      dense: true,
                      tileColor: bgColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: esSeleccionada
                              ? AppColors.primary
                              : esDisponible
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                        ),
                      ),
                      title: Text(
                        hora,
                        style: TextStyle(
                          fontWeight: esSeleccionada
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: !esDisponible
                          ? const Text(
                              'Hora extra',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFB45309)),
                            )
                          : null,
                      trailing: esSeleccionada
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, hora),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (horaSeleccionada != null) {
      final parts = horaSeleccionada.split(':');
      setState(() {
        _horaInicio = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      });
    }
  }

  static Widget _leyendaDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_horaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una hora de inicio'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un servicio'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    // Validar que se haya seleccionado un cliente existente
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un cliente existente de la lista'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    // Validar que haya al menos un servicio seleccionado
    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un tipo de serenata'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final controller = context.read<ReservaController>();

    // Preparar lista de servicios en diferentes formatos
    final servicios = _serviciosSeleccionados.entries.map((entry) {
      return {
        'serviceId': entry.key,
        'quantity': entry.value,
      };
    }).toList();

    // También preparar un array simple de IDs por si el backend lo espera así
    final serviciosIds = _serviciosSeleccionados.keys.toList();

    print('=== DEBUG: Servicios seleccionados ===');
    print('Cantidad de servicios: ${servicios.length}');
    print('Servicios con cantidad: $servicios');
    print('Solo IDs: $serviciosIds');

    // Calcular hora fin según servicios de hora extra seleccionados
    // duración = 1h base + N horas extras
    final horaFin = _horaFinCalculada!;

    final success = await controller.crearReserva(
      clienteId: _clienteSeleccionado!.id,
      clienteNombre: _clienteNombreCtrl.text.trim(),
      clienteEmail: _clienteEmailCtrl.text.trim(),
      clienteTelefono: _clienteTelefonoCtrl.text.trim(),
      homenajeado: _homenajeadoCtrl.text.trim(),
      tipoEvento: _tipoEvento,
      fechaEvento: _fechaEvento,
      horaInicio: _formatTimeOfDay(_horaInicio!),
      horaFin: _formatTimeOfDay(horaFin),
      ubicacion: _ubicacionCtrl.text.trim(),
      totalValor: _totalCalculado,
      servicios: servicios,
    );

    setState(() => _guardando = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = controller.errorMsg;
        final esConflicto = msg.toLowerCase().contains('conflicto') ||
            msg.toLowerCase().contains('ocupad') ||
            msg.toLowerCase().contains('activa');

        if (esConflicto) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              icon: const Icon(Icons.schedule_outlined,
                  color: Color(0xFFB45309), size: 40),
              title: const Text('Conflicto de Horario',
                  textAlign: TextAlign.center),
              content: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(context);
                    // Recargar disponibilidad para reflejar el conflicto
                    _verificarDisponibilidad();
                  },
                  child: const Text('Cambiar hora'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Reserva'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información del Cliente
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Información del Cliente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (_cargandoClientes)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Autocompletado de clientes
            Autocomplete<Cliente>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Cliente>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return _clientes.where((cliente) {
                  return cliente.nombreCompleto.toLowerCase().contains(query) ||
                      (cliente.email?.toLowerCase().contains(query) ?? false) ||
                      (cliente.telefonoPrincipal?.contains(query) ?? false);
                });
              },
              displayStringForOption: (Cliente cliente) =>
                  cliente.nombreCompleto,
              onSelected: _seleccionarCliente,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                // Sincronizar con nuestro controlador
                if (_clienteNombreCtrl.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text = _clienteNombreCtrl.text;
                }
                _clienteNombreCtrl.addListener(() {
                  if (_clienteNombreCtrl.text != controller.text) {
                    controller.text = _clienteNombreCtrl.text;
                  }
                });
                controller.addListener(() {
                  if (_clienteNombreCtrl.text != controller.text) {
                    _clienteNombreCtrl.text = controller.text;
                    // Limpiar selección si el usuario modifica el texto
                    if (_clienteSeleccionado != null &&
                        controller.text !=
                            _clienteSeleccionado!.nombreCompleto) {
                      setState(() => _clienteSeleccionado = null);
                    }
                  }
                });

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _clienteSeleccionado != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    hintText: 'Buscar y seleccionar cliente',
                    helperText: 'Debes seleccionar un cliente de la lista',
                    helperStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (_clienteSeleccionado == null) {
                      return 'Debes seleccionar un cliente de la lista';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 400,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final cliente = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                cliente.nombreCompleto[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              cliente.nombreCompleto,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                if (cliente.email != null) cliente.email!,
                                if (cliente.telefonoPrincipal != null)
                                  cliente.telefonoPrincipal!,
                              ].join(' • '),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => onSelected(cliente),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _clienteEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _clienteTelefonoCtrl,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 24),

            // Información del Evento
            const Text(
              'Información del Evento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<TipoEvento>(
              initialValue: _tipoEvento,
              decoration: const InputDecoration(
                labelText: 'Tipo de Evento *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.celebration),
              ),
              items: TipoEvento.values.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(_tipoEventoLabel(tipo)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _tipoEvento = v!),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _homenajeadoCtrl,
              decoration: const InputDecoration(
                labelText: 'Homenajeado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Fecha del Evento'),
              subtitle: Text(
                '${_fechaEvento.day}/${_fechaEvento.month}/${_fechaEvento.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.edit),
              onTap: _seleccionarFecha,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Hora de Inicio'),
              subtitle: _horaInicio != null
                  ? Row(children: [
                      Text(
                        _horaInicio!.format(context),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        _horaFinCalculada != null
                            ? _formatTimeOfDay(_horaFinCalculada!)
                            : '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _horasExtrasSeleccionadas > 0
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _horasExtrasSeleccionadas > 0
                              ? '${_duracionHoras}h · $_horasExtrasSeleccionadas extra'
                              : '${_duracionHoras}h',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _horasExtrasSeleccionadas > 0
                                ? const Color(0xFFB45309)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ])
                  : Text(
                      _verificandoDisponibilidad
                          ? 'Verificando disponibilidad...'
                          : 'Seleccionar hora',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
              trailing: _verificandoDisponibilidad
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _horaInicio != null ? Icons.check_circle : Icons.edit,
                      color: _horaInicio != null ? Colors.green : null,
                    ),
              onTap: _seleccionarHoraInicio,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _horaInicio != null
                      ? Colors.green
                      : const Color(0xFFE2E8F0),
                  width: _horaInicio != null ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ubicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Ubicación *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: 24),

            // Servicios
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Servicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (_cargandoServicios)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_serviciosDisponibles.isEmpty && !_cargandoServicios)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay servicios disponibles',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ..._serviciosDisponibles.map((servicio) {
                final seleccionado =
                    _serviciosSeleccionados.containsKey(servicio.id);
                final cantidad = _serviciosSeleccionados[servicio.id] ?? 1;

                // Determinar si está bloqueado por exclusión mutua
                final bool bloqueado;
                String? motivoBloqueo;
                if (!seleccionado) {
                  if (_esSerenataUrbana(servicio.nombre) &&
                      _serviciosDisponibles.any((s) =>
                          _esSerenataRural(s.nombre) &&
                          _serviciosSeleccionados.containsKey(s.id))) {
                    bloqueado = true;
                    motivoBloqueo = 'No compatible con Serenata Rural';
                  } else if (_esSerenataRural(servicio.nombre) &&
                      _serviciosDisponibles.any((s) =>
                          _esSerenataUrbana(s.nombre) &&
                          _serviciosSeleccionados.containsKey(s.id))) {
                    bloqueado = true;
                    motivoBloqueo = 'No compatible con Serenata Urbana';
                  } else {
                    bloqueado = false;
                  }
                } else {
                  bloqueado = false;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: seleccionado ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: seleccionado
                          ? AppColors.primary
                          : bloqueado
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFFE2E8F0),
                      width: seleccionado ? 2 : 1,
                    ),
                  ),
                  child: Opacity(
                    opacity: bloqueado ? 0.45 : 1.0,
                    child: InkWell(
                      onTap: bloqueado ? null : () => _toggleServicio(servicio),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: seleccionado,
                              onChanged: bloqueado
                                  ? null
                                  : (_) => _toggleServicio(servicio),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    servicio.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: seleccionado
                                          ? AppColors.primary
                                          : bloqueado
                                              ? AppColors.textMuted
                                              : AppColors.text,
                                    ),
                                  ),
                                  if (motivoBloqueo != null) ...[
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      const Icon(Icons.block,
                                          size: 11, color: Color(0xFFB91C1C)),
                                      const SizedBox(width: 4),
                                      Text(
                                        motivoBloqueo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFB91C1C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ]),
                                  ] else if (servicio.descripcion != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      servicio.descripcion!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCop(servicio.precio.round()),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: seleccionado
                                          ? AppColors.primary
                                          : AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (seleccionado) ...[
                              const SizedBox(width: 8),
                              // Urbana y rural: cantidad fija en 1, sin controles
                              if (_esSerenataUrbana(servicio.nombre) ||
                                  _esSerenataRural(servicio.nombre))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('x1',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.primary)),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.remove, size: 18),
                                        onPressed: () => _actualizarCantidad(
                                            servicio.id, cantidad - 1),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                      Text(
                                        '$cantidad',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () => _actualizarCantidad(
                                            servicio.id, cantidad + 1),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ), // Opacity
                );
              }),

            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    formatCop(_totalCalculado.round()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Crear Reserva',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tipoEventoLabel(TipoEvento tipo) {
    const map = {
      TipoEvento.boda: 'Boda',
      TipoEvento.cumpleanos: 'Cumpleaños',
      TipoEvento.quinceanios: 'Quinceaños',
      TipoEvento.funeral: 'Funeral',
      TipoEvento.reconciliacion: 'Reconciliación',
      TipoEvento.diaDeMadre: 'Día de la Madre',
      TipoEvento.amor: 'Amor',
      TipoEvento.aniversario: 'Aniversario',
      TipoEvento.padres: 'Día del Padre',
      TipoEvento.fiesta: 'Fiesta',
      TipoEvento.otro: 'Otro',
    };
    return map[tipo] ?? 'Otro';
  }
}
