import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/models/app_models.dart';
import '../ui/screen_header.dart';
import 'ensayo_controller.dart';
import 'ensayo_detalle_screen.dart';

class EnsayosScreen extends StatefulWidget {
  const EnsayosScreen({super.key});

  @override
  State<EnsayosScreen> createState() => _EnsayosScreenState();
}

class _EnsayosScreenState extends State<EnsayosScreen> {
  late EnsayoController _controller;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Primer día de la semana del primer día del mes
  DateTime get _startOfCalendar {
    final firstOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    // weekday: 1=lunes … 7=domingo → retroceder (weekday-1) días
    return firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
  }

  // Cuántas filas necesita el mes (4, 5 o 6)
  int get _calendarRows {
    final firstOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startOffset = firstOfMonth.weekday - 1; // días antes del 1
    final totalCells = startOffset + lastOfMonth.day;
    return (totalCells / 7).ceil();
  }

  @override
  void initState() {
    super.initState();
    _controller = context.read<EnsayoController>();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cargar();
    });
  }

  List<Ensayo> _getEnsayosForDay(DateTime day) {
    return _controller.ensayos.where((ensayo) {
      return _isSameDay(ensayo.fechaHora, day);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
                ScreenHeader(
                  icono: Icons.music_note_outlined,
                  titulo: 'Ensayos',
                  subtitulo: 'Calendario de ensayos',
                  hintBuscar: '',
                  searchController: TextEditingController(),
                  onSearch: (_) {},
                  mostrarBuscar: false,
                  filtros: [
                    FilterChipData(
                      label: 'Todos',
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
                          controller.estadoFiltro == EstadoEnsayo.pendiente,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoEnsayo.pendiente),
                    ),
                    FilterChipData(
                      label: 'Listo',
                      bgColor: const Color(0xFFDCFCE7),
                      fgColor: const Color(0xFF047857),
                      selected: controller.estadoFiltro == EstadoEnsayo.listo,
                      onTap: () =>
                          controller.filtrarPorEstado(EstadoEnsayo.listo),
                    ),
                  ],
                ),
                _buildCalendar(controller),
                const SizedBox(height: 10),
                Expanded(child: _buildEnsayosList(controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(EnsayoController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 4),
            _buildWeekDaysHeader(),
            const SizedBox(height: 2),
            _buildThreeWeeksGrid(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.chevron_left,
              color: AppColors.primary, size: 18),
        ),
        Text(
          DateFormat('MMMM yyyy', 'es').format(_focusedDay),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
            });
          },
          icon: const Icon(Icons.chevron_right,
              color: AppColors.primary, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: weekDays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildThreeWeeksGrid(EnsayoController controller) {
    final startDate = _startOfCalendar;
    final rows = _calendarRows;
    final weeks = <Widget>[];

    for (int week = 0; week < rows; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      weeks.add(_buildWeekRow(weekStart, controller));
    }

    return Column(children: weeks);
  }

  Widget _buildWeekRow(DateTime weekStart, EnsayoController controller) {
    final days = <Widget>[];
    final currentMonth = _focusedDay.month;

    for (int day = 0; day < 7; day++) {
      final currentDay = weekStart.add(Duration(days: day));
      final ensayosDelDia = _getEnsayosForDay(currentDay);
      final isSelected =
          _selectedDay != null && _isSameDay(_selectedDay!, currentDay);
      final isToday = _isSameDay(currentDay, DateTime.now());
      final isCurrentMonth = currentDay.month == currentMonth;

      days.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = currentDay;
              });
            },
            child: Container(
              height: 26,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      currentDay.day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrentMonth
                                ? AppColors.text
                                : AppColors.textMuted.withValues(alpha: 0.4),
                        fontWeight: isToday || isSelected
                            ? FontWeight.w900
                            : FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (ensayosDelDia.isNotEmpty)
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ensayosDelDia.take(3).map((ensayo) {
                            final color = isSelected
                                ? Colors.white
                                : ensayo.estado == EstadoEnsayo.listo
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309);
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: days);
  }

  Widget _buildEnsayosList(EnsayoController controller) {
    if (controller.status == EnsayoStatus.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.status == EnsayoStatus.error) {
      return Center(
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
      );
    }

    final ensayosDelDia =
        _selectedDay != null ? _getEnsayosForDay(_selectedDay!) : <Ensayo>[];

    if (ensayosDelDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDay != null
                  ? 'No hay ensayos programados para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'
                  : 'Selecciona una fecha para ver los ensayos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ensayos del ${DateFormat('EEEE d \'de\' MMMM', 'es').format(_selectedDay!)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: ensayosDelDia.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _EnsayoCard(
              e: ensayosDelDia[i],
              onDetalle: () => _showDetalle(ensayosDelDia[i]),
              onToggle: () => _toggleEstado(ensayosDelDia[i]),
              onEliminar: () => _confirmEliminar(ensayosDelDia[i]),
            ),
          ),
        ),
      ],
    );
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
    final horaFormato = DateFormat('HH:mm').format(e.fechaHora);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        e.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: listo ? AppColors.textMuted : AppColors.text,
                          decoration: listo
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            horaFormato,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.place,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e.lugar,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pillBg(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    e.estadoLabel.toUpperCase(),
                    style: TextStyle(
                      color: _pillFg(),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
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
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
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
            if (e.repertorios.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.repertorios.length} canción${e.repertorios.length != 1 ? 'es' : ''}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
