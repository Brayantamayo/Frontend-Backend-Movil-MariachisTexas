import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mariachi_admin/auth/auth_controller.dart';
import 'package:mariachi_admin/clientes/clientes_controller.dart';
import 'package:mariachi_admin/clientes/cliente_model.dart';
import '../core/theme/app_colors.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().token ?? '';
      context.read<ClientesController>().cargarClientes(token);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Cliente> _filtered(List<Cliente> clientes) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return clientes;
    return clientes.where((c) {
      return c.nombre.toLowerCase().contains(q) ||
          c.telefono.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClientesController>();
    final items = _filtered(controller.clientes);

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
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null
                    ? Center(child: Text(controller.error!, style: const TextStyle(color: Colors.red)))
                    : items.isEmpty
                        ? const Center(child: Text('No se encontraron clientes.'))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final c = items[i];
                              return _ClienteCard(c: c);
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
  const _ClienteCard({required this.c});

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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(AppColors.text)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Color(AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(c.telefono, style: const TextStyle(color: Color(AppColors.textMuted))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Color(AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(c.email, style: const TextStyle(color: Color(AppColors.textMuted), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}