import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Chip de filtro de estado
class FilterChipData {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipData({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.selected,
    required this.onTap,
  });
}

/// Header reutilizable con ícono, título, subtítulo, campo de búsqueda
/// y chips de filtro por estado opcionales.
class ScreenHeader extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String hintBuscar;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final List<FilterChipData> filtros;
  final bool mostrarBuscar;

  const ScreenHeader({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.hintBuscar,
    required this.searchController,
    required this.onSearch,
    this.filtros = const [],
    this.mostrarBuscar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Título con ícono ───────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitulo,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Campo de búsqueda ──────────────────────────────────────────────
        if (mostrarBuscar)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF9CA3AF), size: 20),
                hintText: hintBuscar,
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

        // ── Chips de filtro ────────────────────────────────────────────────
        if (filtros.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in filtros) ...[
                  _FilterBtn(data: f),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final FilterChipData data;
  const _FilterBtn({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: data.selected ? data.bgColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.selected
                ? data.fgColor.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: data.selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          data.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: data.selected ? FontWeight.w800 : FontWeight.w500,
            color: data.selected ? data.fgColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
