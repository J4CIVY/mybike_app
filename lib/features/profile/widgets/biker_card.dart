import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mybike_app/core/models/bskmt_models.dart';
import 'package:mybike_app/features/auth/login_screen.dart';

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
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: isLegend ? const Color(0xFFF59E0B) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'B',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user?.identityVerified == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFF38BDF8), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLegend ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'MEMBRESÍA $membershipLevel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isLegend ? const Color(0xFF0F172A) : Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo local: Inicia sesión para sincronizar tu garaje y telemetría.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'CONECTAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (user?.bloodType != null || user?.emergencyContactPhone != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (user?.bloodType != null)
                    _buildQuickMedical(
                      Icons.bloodtype_rounded,
                      'RH',
                      user!.bloodType!,
                    ),
                  if (user?.eps != null)
                    _buildQuickMedical(
                      Icons.local_hospital_rounded,
                      'EPS',
                      user!.eps!,
                    ),
                  if (user?.emergencyContactPhone != null)
                    _buildQuickMedical(
                      Icons.contact_phone_rounded,
                      'SOS',
                      user!.emergencyContactPhone!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickMedical(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
