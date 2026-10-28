import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/login_screen.dart';
import '../../../core/services/bskmt_models.dart';

class BikerCard extends StatelessWidget {
  final BskmtUser? user;
  final String fallbackName;
  final bool isAuthenticated;

  const BikerCard({
    super.key,
    required this.user,
    required this.fallbackName,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? fallbackName;
    final userEmail = user?.email ?? 'Sin cuenta BSKMT vinculada';
    final membershipLevel = user?.membershipLevel ?? 'ESTÁNDAR';
    final isLegend = membershipLevel == 'LEGEND';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isLegend
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isLegend ? const Color(0x3DF59E0B) : const Color(0x3DDC2626),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'B',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLegend ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  membershipLevel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isLegend ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bikerInfoItem(label: 'TIPO DE SANGRE', value: user?.bloodType ?? 'O+'),
                _bikerInfoItem(label: 'EPS / SEGURO', value: user?.eps ?? 'Al día'),
                _bikerInfoItem(
                  label: 'CONTACTO SOS',
                  value: user?.emergencyContactPhone != null ? 'Configurado' : 'Pendiente',
                ),
              ],
            ),
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  'Iniciar Sesión con Cuenta BSKMT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bikerInfoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

