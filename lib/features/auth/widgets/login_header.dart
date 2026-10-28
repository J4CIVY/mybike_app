import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ui/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3ADC2626),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenido a BSKMT',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión con tu cuenta de bskmt.com para sincronizar tu Garaje Virtual, SOAT, tecnomecánica y telemetría.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textDim,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

