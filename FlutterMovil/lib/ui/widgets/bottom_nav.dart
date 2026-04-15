import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      indicatorColor: const Color(0xFFFEE2E2),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Cotizaciones',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Menú',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: 'Repertorio',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic_none_outlined),
          selectedIcon: Icon(Icons.mic),
          label: 'Ensayos',
        ),
      ],
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor: const Color(AppColors.surface),
    );
  }
}

