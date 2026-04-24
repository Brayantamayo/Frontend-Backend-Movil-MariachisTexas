import 'package:flutter/material.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../core/theme/app_colors.dart';

class ClienteDetalleScreen extends StatelessWidget {
  final Cliente cliente;
  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cliente.nombreCompleto),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + nombre
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cliente.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cliente #${cliente.id}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Información de contacto'),
            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.phone,
              label: 'Teléfono principal',
              value: cliente.telefonoPrincipal ?? 'No registrado',
            ),
            _InfoTile(
              icon: Icons.phone_android,
              label: 'Teléfono alternativo',
              value: cliente.telefonoAlternativo ?? 'No registrado',
            ),
            _InfoTile(
              icon: Icons.email,
              label: 'Correo electrónico',
              value: cliente.email ?? 'No registrado',
            ),

            const SizedBox(height: 20),
            const _SectionTitle('Ubicación'),
            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.location_on,
              label: 'Dirección',
              value: cliente.direccion ?? 'No registrada',
            ),
            _InfoTile(
              icon: Icons.location_city,
              label: 'Ciudad',
              value: cliente.ciudad ?? 'No registrada',
            ),

            if (cliente.usuario != null) ...[
              const SizedBox(height: 20),
              const _SectionTitle('Usuario del sistema'),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Nombre',
                value: cliente.usuario!.nombre,
              ),
              _InfoTile(
                icon: Icons.alternate_email,
                label: 'Email de acceso',
                value: cliente.usuario!.email,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
