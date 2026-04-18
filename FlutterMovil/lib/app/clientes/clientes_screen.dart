import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum EstadoCliente { activo, inactivo }

class Cliente {
  final int id;
  final String nombre;
  final String telefono;
  final int eventos;
  final String ultimo;
  EstadoCliente estado;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.eventos,
    required this.ultimo,
    required this.estado,
  });
}

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _search = TextEditingController();

  final List<Cliente> _items = [
    Cliente(id: 1, nombre: 'Familia Martínez', telefono: '555-0123', eventos: 3, ultimo: 'Hace 2 meses', estado: EstadoCliente.activo),
    Cliente(id: 2, nombre: 'Empresa XYZ', telefono: '555-0456', eventos: 5, ultimo: 'Hace 1 mes', estado: EstadoCliente.activo),
    Cliente(id: 3, nombre: 'Juan Pérez', telefono: '555-0789', eventos: 1, ultimo: 'Nuevo', estado: EstadoCliente.inactivo),
    Cliente(id: 4, nombre: 'María González', telefono: '555-0987', eventos: 2, ultimo: 'Hace 6 meses', estado: EstadoCliente.activo),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Cliente> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((c) {
      return c.nombre.toLowerCase().contains(q) || c.telefono.contains(q);
    }).toList();
  }

  void _toggle(Cliente c) {
    setState(() {
      c.estado = c.estado == EstadoCliente.activo ? EstadoCliente.inactivo : EstadoCliente.activo;
    });
  }

  Future<void> _delete(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro de eliminar este cliente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(AppColors.primary)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _items.removeWhere((x) => x.id == c.id));
  }

  Future<void> _detalle(Cliente c) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle del Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Nombre', c.nombre),
            _kv('Estado', c.estado.name),
            _kv('Teléfono', c.telefono),
            _kv('Total Eventos', '${c.eventos}'),
            _kv('Último Evento', c.ultimo),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clientes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar cliente...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No se encontraron clientes.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return _ClienteCard(
                        c: c,
                        onDetalle: () => _detalle(c),
                        onToggle: () => _toggle(c),
                        onDelete: () => _delete(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente c;
  final VoidCallback onDetalle;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ClienteCard({required this.c, required this.onDetalle, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active = c.estado == EstadoCliente.activo;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: active ? const Color(AppColors.primary) : const Color(AppColors.textMuted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: active ? const Color(AppColors.text) : const Color(AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Color(AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(c.telefono, style: const TextStyle(color: Color(AppColors.textMuted))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${c.eventos} eventos', style: const TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w900)),
                Text(c.ultimo, style: const TextStyle(fontSize: 11, color: Color(AppColors.textMuted))),
              ],
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'detalle', child: Text('Ver Detalle')),
                PopupMenuItem(value: 'toggle', child: Text('Activar/Desactivar')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
              onSelected: (v) {
                if (v == 'detalle') onDetalle();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(AppColors.textMuted))),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

