import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import '../core/services/servicio_service.dart';
import '../core/format/currency.dart';
import '../clientes/cliente_service.dart';
import 'reserva_controller.dart';

class EditarReservaScreen extends StatefulWidget {
  final Reserva reserva;
  const EditarReservaScreen({super.key, required this.reserva});

  @override
  State<EditarReservaScreen> createState() => _EditarReservaScreenState();
}

class _EditarReservaScreenState extends State<EditarReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteNombreCtrl;
  late final TextEditingController _clienteEmailCtrl;
  late final TextEditingController _clienteTelefonoCtrl;
  late final TextEditingController _homenajeadoCtrl;
  late final TextEditingController _ubicacionCtrl;

  late TipoEvento _tipoEvento;
  late DateTime _fechaEvento;
  TimeOfDay? _horaInicio;

  bool _guardando = false;
  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;

  List<Servicio> _serviciosDisponibles = [];
  final Map<int, int> _serviciosSeleccionados = {};
  bool _cargandoServicios = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reserva;
    _clienteNombreCtrl = TextEditingController(text: r.clienteNombre);
    _clienteEmailCtrl = TextEditingController(text: r.clienteEmail);
    _clienteTelefonoCtrl = TextEditingController(text: r.clienteTelefono);
    _homenajeadoCtrl = TextEditingController(text: r.homenajeado);
    _ubicacionCtrl = TextEditingController(text: r.ubicacion);
    _tipoEvento = _tipoEventoFromString(r.tipoEvento);
    _fechaEvento = r.fechaEvento;

    if (r.horaInicio.isNotEmpty) {
      final p = r.horaInicio.split(':');
      if (p.length >= 2) {
        _horaInicio = TimeOfDay(
            hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
      }
    }
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      _clientes = await ClienteService.obtenerClientes();
      final match = _clientes
          .where((c) => c.nombreCompleto == widget.reserva.clienteNombre)
          .firstOrNull;
      if (match != null) setState(() => _clienteSeleccionado = match);
    } catch (_) {}

    setState(() => _cargandoServicios = true);
    try {
      _serviciosDisponibles = await ServicioService.obtenerServicios();
      // Preseleccionar desde serviciosRaw
      for (final raw in widget.reserva.serviciosRaw) {
        final id = int.tryParse(raw['serviceId'].toString()) ?? 0;
        final qty = int.tryParse(raw['quantity'].toString()) ?? 1;
        if (id > 0) _serviciosSeleccionados[id] = qty;
      }
      // Fallback: usar chips
      if (_serviciosSeleccionados.isEmpty) {
        for (final chip in widget.reserva.chips) {
          final match = _serviciosDisponibles
              .where((s) => s.nombre == chip.nombre)
              .firstOrNull;
          if (match != null) _serviciosSeleccionados[match.id] = chip.cantidad;
        }
      }
    } catch (_) {}
    setState(() => _cargandoServicios = false);
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

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  double get _totalCalculado {
    double total = 0;
    for (final entry in _serviciosSeleccionados.entries) {
      final svc =
          _serviciosDisponibles.where((s) => s.id == entry.key).firstOrNull;
      if (svc != null) total += svc.precio * entry.value;
    }
    return total;
  }

  static bool _esUrbana(String nombre) =>
      nombre.toLowerCase().contains('urbana');
  static bool _esRural(String nombre) => nombre.toLowerCase().contains('rural');
  static bool _esHoraExtra(String nombre) =>
      nombre.toLowerCase().contains('hora extra') ||
      nombre.toLowerCase().contains('hora adicional');
  static bool _esSerenata(String nombre) =>
      _esUrbana(nombre) || _esRural(nombre);

  /// Horas extras seleccionadas (suma de cantidades)
  int get _horasExtras {
    int total = 0;
    for (final entry in _serviciosSeleccionados.entries) {
      final svc =
          _serviciosDisponibles.where((s) => s.id == entry.key).firstOrNull;
      if (svc != null && _esHoraExtra(svc.nombre)) total += entry.value;
    }
    return total;
  }

  /// Hora fin = hora inicio + 1h base + horas extras
  TimeOfDay? get _horaFinCalculada {
    if (_horaInicio == null) return null;
    final totalHoras = 1 + _horasExtras;
    return TimeOfDay(
      hour: (_horaInicio!.hour + totalHoras) % 24,
      minute: _horaInicio!.minute,
    );
  }

  bool _estaDeshabilitado(Servicio svc) {
    if (_esUrbana(svc.nombre)) {
      return _serviciosDisponibles
          .where((s) => _esRural(s.nombre))
          .any((s) => _serviciosSeleccionados.containsKey(s.id));
    }
    if (_esRural(svc.nombre)) {
      return _serviciosDisponibles
          .where((s) => _esUrbana(s.nombre))
          .any((s) => _serviciosSeleccionados.containsKey(s.id));
    }
    return false;
  }

  void _toggleServicio(Servicio svc) {
    setState(() {
      if (_serviciosSeleccionados.containsKey(svc.id)) {
        _serviciosSeleccionados.remove(svc.id);
      } else {
        if (_esUrbana(svc.nombre)) {
          _serviciosDisponibles
              .where((s) => _esRural(s.nombre))
              .forEach((s) => _serviciosSeleccionados.remove(s.id));
        } else if (_esRural(svc.nombre)) {
          _serviciosDisponibles
              .where((s) => _esUrbana(s.nombre))
              .forEach((s) => _serviciosSeleccionados.remove(s.id));
        }
        _serviciosSeleccionados[svc.id] = 1;
      }
    });
  }

  TipoEvento _tipoEventoFromString(String s) => switch (s.toUpperCase()) {
        'BODA' => TipoEvento.boda,
        'CUMPLEANOS' => TipoEvento.cumpleanos,
        'QUINCEANIOS' => TipoEvento.quinceanios,
        'FUNERAL' => TipoEvento.funeral,
        'RECONCILIACION' => TipoEvento.reconciliacion,
        'DIA_DE_MADRE' => TipoEvento.diaDeMadre,
        'AMOR' => TipoEvento.amor,
        'ANIVERSARIO' => TipoEvento.aniversario,
        'PADRES' => TipoEvento.padres,
        'FIESTA' => TipoEvento.fiesta,
        _ => TipoEvento.otro,
      };

  String _tipoEventoToString(TipoEvento t) => switch (t) {
        TipoEvento.boda => 'BODA',
        TipoEvento.cumpleanos => 'CUMPLEANOS',
        TipoEvento.quinceanios => 'QUINCEANIOS',
        TipoEvento.funeral => 'FUNERAL',
        TipoEvento.reconciliacion => 'RECONCILIACION',
        TipoEvento.diaDeMadre => 'DIA_DE_MADRE',
        TipoEvento.amor => 'AMOR',
        TipoEvento.aniversario => 'ANIVERSARIO',
        TipoEvento.padres => 'PADRES',
        TipoEvento.fiesta => 'FIESTA',
        TipoEvento.otro => 'OTRO',
      };

  String _tipoEventoLabel(TipoEvento t) => switch (t) {
        TipoEvento.boda => 'Boda',
        TipoEvento.cumpleanos => 'Cumpleaños',
        TipoEvento.quinceanios => 'Quinceaños',
        TipoEvento.funeral => 'Funeral',
        TipoEvento.reconciliacion => 'Reconciliación',
        TipoEvento.diaDeMadre => 'Día de la Madre',
        TipoEvento.amor => 'Amor',
        TipoEvento.aniversario => 'Aniversario',
        TipoEvento.padres => 'Día del Padre',
        TipoEvento.fiesta => 'Fiesta',
        TipoEvento.otro => 'Otro',
      };

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEvento,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha != null) setState(() => _fechaEvento = fecha);
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final horaActual = _horaInicio;
    final horas = <String>[];
    for (int h = 8; h <= 23; h++) {
      horas.add('${h.toString().padLeft(2, '0')}:00');
    }

    final horaSeleccionada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Hora de Inicio'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: horas.length,
                  itemBuilder: (_, i) {
                    final hora = horas[i];
                    final esSeleccionada = horaActual != null &&
                        '${horaActual.hour.toString().padLeft(2, '0')}:${horaActual.minute.toString().padLeft(2, '0')}' ==
                            hora;
                    return ListTile(
                      dense: true,
                      tileColor: esSeleccionada
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: esSeleccionada
                              ? AppColors.primary
                              : const Color(0xFF047857),
                        ),
                      ),
                      title: Text(hora,
                          style: TextStyle(
                            fontWeight: esSeleccionada
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: esSeleccionada
                                ? AppColors.primary
                                : AppColors.text,
                            fontSize: 14,
                          )),
                      trailing: esSeleccionada
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () => Navigator.pop(ctx, hora),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );

    if (horaSeleccionada != null) {
      final parts = horaSeleccionada.split(':');
      setState(() => _horaInicio = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes seleccionar hora de inicio'),
        backgroundColor: AppColors.primary,
      ));
      return;
    }
    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes seleccionar al menos un servicio'),
        backgroundColor: AppColors.primary,
      ));
      return;
    }

    setState(() => _guardando = true);

    final fechaStr =
        '${_fechaEvento.year}-${_fechaEvento.month.toString().padLeft(2, '0')}-${_fechaEvento.day.toString().padLeft(2, '0')}';

    final datos = {
      'clientName': _clienteNombreCtrl.text.trim(),
      'clientEmail': _clienteEmailCtrl.text.trim(),
      'clientPhone': _clienteTelefonoCtrl.text.trim(),
      'homenajeado': _homenajeadoCtrl.text.trim(),
      'eventType': _tipoEventoToString(_tipoEvento),
      'eventDate': fechaStr,
      'startTime': _formatTime(_horaInicio!),
      'endTime': _formatTime(_horaFinCalculada ?? _horaInicio!),
      'location': _ubicacionCtrl.text.trim(),
      'totalAmount': _totalCalculado,
      'selectedServices': _serviciosSeleccionados.entries
          .map((e) => {'serviceId': e.key, 'quantity': e.value})
          .toList(),
    };

    try {
      final controller = context.read<ReservaController>();
      final success =
          await controller.actualizarReserva(widget.reserva.id, datos);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reserva actualizada exitosamente'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(controller.errorMsg),
            backgroundColor: AppColors.primary,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.primary,
        ));
      }
    }

    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Editar Reserva #${widget.reserva.id}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _titulo('Cliente'),
            const SizedBox(height: 12),
            Autocomplete<Cliente>(
              initialValue: TextEditingValue(text: _clienteNombreCtrl.text),
              optionsBuilder: (v) {
                if (v.text.isEmpty) return const [];
                final q = v.text.toLowerCase();
                return _clientes.where((c) =>
                    c.nombreCompleto.toLowerCase().contains(q) ||
                    (c.email?.toLowerCase().contains(q) ?? false) ||
                    (c.telefonoPrincipal?.contains(q) ?? false));
              },
              displayStringForOption: (c) => c.nombreCompleto,
              onSelected: (c) => setState(() {
                _clienteSeleccionado = c;
                _clienteNombreCtrl.text = c.nombreCompleto;
                _clienteEmailCtrl.text = c.email ?? '';
                _clienteTelefonoCtrl.text = c.telefonoPrincipal ?? '';
              }),
              fieldViewBuilder: (ctx, ctrl, focus, _) {
                ctrl.text = _clienteNombreCtrl.text;
                ctrl.addListener(() => _clienteNombreCtrl.text = ctrl.text);
                return TextFormField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _clienteSeleccionado != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 200, maxWidth: 400),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (_, i) {
                        final c = options.elementAt(i);
                        return ListTile(
                          title: Text(c.nombreCompleto),
                          subtitle: Text(c.email ?? ''),
                          onTap: () => onSelected(c),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clienteEmailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clienteTelefonoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 24),
            _titulo('Evento'),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoEvento>(
              initialValue: _tipoEvento,
              decoration: const InputDecoration(
                  labelText: 'Tipo de Evento *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.celebration)),
              items: TipoEvento.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_tipoEventoLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _tipoEvento = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _homenajeadoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Homenajeado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard)),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Fecha del Evento'),
              subtitle: Text(
                  '${_fechaEvento.day}/${_fechaEvento.month}/${_fechaEvento.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.edit),
              onTap: _seleccionarFecha,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Hora de Inicio'),
              subtitle: Text(
                  _horaInicio != null
                      ? _formatTime(_horaInicio!)
                      : 'Seleccionar',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.edit),
              onTap: () => _seleccionarHora(true),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            const SizedBox(height: 12),
            // Hora fin calculada automáticamente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                const Icon(Icons.schedule_outlined,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hora de Fin (automática)',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          _horaFinCalculada != null
                              ? '${_formatTime(_horaInicio!)} → ${_formatTime(_horaFinCalculada!)}  (${1 + _horasExtras}h)'
                              : 'Selecciona hora de inicio primero',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text),
                        ),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacionCtrl,
              decoration: const InputDecoration(
                  labelText: 'Ubicación *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(
                child: Text('Servicios',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
              ),
              if (_cargandoServicios)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 12),
            if (!_cargandoServicios)
              ..._serviciosDisponibles.map((svc) {
                final seleccionado =
                    _serviciosSeleccionados.containsKey(svc.id);
                final cantidad = _serviciosSeleccionados[svc.id] ?? 0;
                final deshabilitado = !seleccionado && _estaDeshabilitado(svc);
                return Opacity(
                  opacity: deshabilitado ? 0.4 : 1.0,
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: seleccionado
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: seleccionado ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: deshabilitado ? null : () => _toggleServicio(svc),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.music_note,
                            color: seleccionado
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 20),
                      ),
                      title: Text(svc.nombre,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: seleccionado
                                  ? AppColors.primary
                                  : AppColors.text)),
                      subtitle: Text(formatCop(svc.precio.round()),
                          style: const TextStyle(fontSize: 12)),
                      trailing: seleccionado
                          ? _esSerenata(svc.nombre)
                              // Serenata: solo botón de quitar
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: AppColors.primary, size: 22),
                                  onPressed: () => setState(() =>
                                      _serviciosSeleccionados.remove(svc.id)),
                                )
                              // Hora extra u otro: +/-
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20),
                                      onPressed: () => setState(() {
                                        final c = cantidad - 1;
                                        if (c <= 0) {
                                          _serviciosSeleccionados
                                              .remove(svc.id);
                                        } else {
                                          _serviciosSeleccionados[svc.id] = c;
                                        }
                                      }),
                                    ),
                                    Text('$cantidad',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 20),
                                      onPressed: () => setState(() =>
                                          _serviciosSeleccionados[svc.id] =
                                              cantidad + 1),
                                    ),
                                  ],
                                )
                          : Icon(
                              deshabilitado
                                  ? Icons.block_outlined
                                  : Icons.add_circle_outline,
                              color: AppColors.textMuted),
                    ),
                  ),
                );
              }),
            if (_serviciosSeleccionados.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      Text(formatCop(_totalCalculado.round()),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primary)),
                    ]),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Guardar Cambios'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) => Text(t,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text));
}
