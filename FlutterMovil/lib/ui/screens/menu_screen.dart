import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.library_music,
        label: 'Repertorio',
        color: const Color(0xFF7C3AED),
        bg: const Color(0xFFF3E8FF),
      ),
      _MenuItem(
        icon: Icons.mic,
        label: 'Ensayos',
        color: const Color(0xFFEA580C),
        bg: const Color(0xFFFFEDD5),
      ),
      _MenuItem(
        icon: Icons.settings,
        label: 'Configuración',
        color: const Color(0xFF475569),
        bg: const Color(0xFFF1F5F9),
        disabled: true,
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Ayuda',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFDBEAFE),
        disabled: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menú',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.text)),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Column(
                    children: [
                      ListTile(
                        enabled: !items[i].disabled,
                        onTap: items[i].disabled
                            ? null
                            : () {
                                // En esta versión Flutter, estas opciones son "atajos".
                                // La navegación principal está en el bottom nav.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Abre "${items[i].label}" desde la barra inferior.')),
                                );
                              },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: items[i].bg, shape: BoxShape.circle),
                          child: Icon(items[i].icon, color: items[i].color),
                        ),
                        title: Text(items[i].label, style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      if (i != items.length - 1) const Divider(height: 1),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final bool disabled;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    this.disabled = false,
  });
}

