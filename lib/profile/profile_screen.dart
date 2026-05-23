// lib/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/controllers/mjengo_auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.white,
      child: Obx(() {
        final user = auth.currentUser;

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: topPad + 16),

              // ── Avatar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF111827),
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? '?',
                          style: GoogleFonts.montserrat(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.fullName ?? user?.firstName ?? 'User',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Info cards ────────────────────────────────────────────
              _InfoCard(
                icon: Icons.verified_user_rounded,
                label: 'Account Status',
                value: user?.isActive == true ? 'Active' : 'Inactive',
                valueColor: user?.isActive == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),

              if (user?.phoneNumber != null &&
                  user!.phoneNumber!.isNotEmpty)
                _InfoCard(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: user.phoneNumber!,
                ),

              if (user?.bio != null && user!.bio!.isNotEmpty)
                _InfoCard(
                  icon: Icons.info_outline_rounded,
                  label: 'Bio',
                  value: user.bio!,
                ),

              if (user?.createdAt != null)
                _InfoCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Member Since',
                  value: _formatDate(user!.createdAt!),
                ),

              const SizedBox(height: 32),

              // ── Sign out ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: auth.signOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF374151), size: 18),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
