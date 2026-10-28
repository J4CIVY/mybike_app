import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ble/ble_controller.dart' show TripRecord;
import '../../../ui/app_theme.dart';

class TripRouteSearchModal {
  static void show({
    required BuildContext context,
    required List<TripRecord> tripsToDisplay,
    required TripRecord currentTrip,
    required void Function(TripRecord selectedTrip, int selectedIndex) onSelectTrip,
  }) {
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filteredTrips = tripsToDisplay.asMap().entries.where((entry) {
              if (query.isEmpty) return true;
              final idx = tripsToDisplay.length - entry.key;
              final trip = entry.value;
              final dateStr = '${trip.startTime.day}/${trip.startTime.month}';
              final distStr = '${trip.distanceKm.toStringAsFixed(1)} km';
              return '#$idx'.contains(query) ||
                  dateStr.contains(query) ||
                  distStr.contains(query) ||
                  'viaje $idx'.contains(query);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              decoration: const BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.panelBorderBright)),
                boxShadow: AppColors.modalShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.route_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'HISTORIAL DE VIAJES',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textDim),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por #1, fecha 27/10, km…',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.panelSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.panelBorderBright),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.panelBorderBright),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.panelBorder, height: 1),
                  Expanded(
                    child: filteredTrips.isEmpty
                        ? Center(
                            child: Text(
                              'No se encontraron viajes',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textDim, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTrips.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (itemCtx, index) {
                              final entry = filteredTrips[index];
                              final tripItem = entry.value;
                              final tripNum = tripsToDisplay.length - entry.key;
                              final isSelected = tripItem.startTime == currentTrip.startTime &&
                                  tripItem.distanceKm == currentTrip.distanceKm;

                              final durMin = tripItem.durationSec ~/ 60;
                              final durText = '$durMin min';

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  onSelectTrip(tripItem, tripNum);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF6FF) : AppColors.panel,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.panelBorderBright,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.primary.withValues(alpha: 0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.two_wheeler_rounded,
                                          size: 16,
                                          color: isSelected ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Viaje #$tripNum',
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (tripItem.route.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.tertiary.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'GPS Real',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.tertiary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${tripItem.distanceKm.toStringAsFixed(1)} km · $durText · ${tripItem.startTime.day.toString().padLeft(2, '0')}/${tripItem.startTime.month.toString().padLeft(2, '0')}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: AppColors.textDim,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

