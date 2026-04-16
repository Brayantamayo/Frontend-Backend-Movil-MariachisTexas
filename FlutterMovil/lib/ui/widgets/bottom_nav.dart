import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  static const _activeColor = Color(0xFFC0392B);
  static const _pillColor = Color(0xFFFEE2E2);
  static const _inactiveColor = Color(0xFF9E9E9E);

  static const _items = [
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Reservas'),
    _NavItem(Icons.description_outlined, Icons.description, 'Cotizaciones'),
    _NavItem(Icons.people_alt_outlined, Icons.people_alt, 'Clientes'),
    _NavItem(Icons.library_music_outlined, Icons.library_music, 'Repertorio'),
    _NavItem(Icons.mic_none_outlined, Icons.mic, 'Ensayos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final isActive = i == widget.currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? _pillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Icon(
                        isActive ? _items[i].activeIcon : _items[i].icon,
                        key: ValueKey(isActive),
                        color: isActive ? _activeColor : _inactiveColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _items[i].label,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.04 * 9.5,
                        color: isActive ? _activeColor : _inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}