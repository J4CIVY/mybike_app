import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bike_trip_summary_stat.dart';

class BikeTripWeeklySummary extends StatelessWidget {
  final double weekDist;
  final int weekCount;
  final int savedMoney;
  final double savedCo2;

  const BikeTripWeeklySummary({
    super.key,
    required this.weekDist,
    required this.weekCount,
    required this.savedMoney,
    required this.savedCo2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTA SEMANA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      '-${savedCo2.toStringAsFixed(1)} kg CO₂',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BikeTripSummaryStat(label: 'Distancia total', value: weekDist.toStringAsFixed(1), unit: 'km'),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: BikeTripSummaryStat(label: 'Total viajes', value: '$weekCount', unit: 'rutas'),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: BikeTripSummaryStat(
                  label: 'Ahorro aprox.',
                  value: savedMoney >= 1000
                      ? '\$${savedMoney ~/ 1000}.${(savedMoney % 1000).toString().padLeft(3, '0')}'
                      : '\$$savedMoney',
                  unit: 'COP',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

