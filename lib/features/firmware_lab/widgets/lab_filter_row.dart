import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../lab_catalog.dart';

class LabFilterRow extends StatelessWidget {
  final String filter;
  final Map<String, int> verdictCounts;
  final ValueChanged<String> onSelectFilter;

  const LabFilterRow({
    super.key,
    required this.filter,
    required this.verdictCounts,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in [
          ('all', 'TODAS (${labCatalog.length})'),
          ('pending', 'PENDIENTES'),
          ('pass', '✅ CORRECTAS (${verdictCounts['pass']})'),
          ('fail', '❌ ERRÓNEAS (${verdictCounts['fail']})'),
        ])
          ChoiceChip(
            label: Text(entry.$2, style: GoogleFonts.spaceGrotesk(fontSize: 11)),
            selected: filter == entry.$1,
            onSelected: (_) => onSelectFilter(entry.$1),
          ),
      ],
    );
  }
}

