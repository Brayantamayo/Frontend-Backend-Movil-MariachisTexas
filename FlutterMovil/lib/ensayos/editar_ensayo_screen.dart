import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import 'ensayo_controller.dart';

class EditarEnsayoScreen extends StatefulWidget {
  final Ensayo ensayo;
  const EditarEnsayoScreen({super.key, required this.ensayo});

  @override
  State<EditarEnsayoScreen> createState() => _EditarEnsayoScreenState();
}

class _EditarEnsayoScreenState extends State<EditarEnsayoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _lugarCtrl;
  late final TextEditingController _notasCtrl;
  late DateTime _fecha;
  TimeOfDay? _hora;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.ensayo;
    _tituloCtrl = TextEditingController(text: e.nombre);
    _lugarCtrl = TextEditingController(text: e.lugar);
    _notasCtrl = TextEditingController(text: e.notas ?? '');
    _fecha = e.fechaHora;
    _hora = TimeOfDay(hour: e.fechaHora.hour, minute: e.fechaHora.minute);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _lugarCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (fecha != null) setState(() => _fecha = fecha);
  }

  Future<void> _seleccionarHora() async {
    final horaActual = _hora;
    final horas = <String>[];
    for (int h = 8; h <= 23; h++) {
      horas.add('${h.toString().padLeft(2, '0')}:00');
    }

    final horaSeleccionada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Hora'),
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
      setState(() => _hora = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una hora'),
        backgroundColor: AppColors.primary,
      ));
      return;
    }

    setState(() => _guardando = true);

    final fechaStr =
        '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';

    final controller = context.read<EnsayoController>();
    final success = await controller.actualizarEnsayo(
      widget.ensayo.id,
      titulo: _tituloCtrl.text.trim(),
      lugar: _lugarCtrl.text.trim(),
      fecha: fechaStr,
      hora: _formatTime(_hora!),
      notas: _notasCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ensayo actualizado exitosamente'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(controller.errorMsg),
          backgroundColor: AppColors.primary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Editar Ensayo #${widget.ensayo.id}',
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
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre del Ensayo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lugarCtrl,
              decoration: const InputDecoration(
                  labelText: 'Lugar *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Fecha'),
              subtitle: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}',
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
              title: const Text('Hora'),
              subtitle: Text(
                  _hora != null ? _formatTime(_hora!) : 'Seleccionar',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.edit),
              onTap: _seleccionarHora,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasCtrl,
              decoration: const InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes)),
              maxLines: 3,
            ),
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
}
