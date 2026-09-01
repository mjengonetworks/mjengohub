import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class SocialShareModal {
  static void show(BuildContext context, {required String title, required String url}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share to',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final waUrl = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent('$title $url')}');
                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _ShareOption(
                    label: 'X / Twitter',
                    icon: Icons.tag_rounded,
                    color: const Color(0xFF1DA1F2),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final xUrl = Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(url)}');
                      if (await canLaunchUrl(xUrl)) {
                        await launchUrl(xUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _ShareOption(
                    label: 'LinkedIn',
                    icon: Icons.business_center_rounded,
                    color: const Color(0xFF0077B5),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final inUrl = Uri.parse('https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(url)}');
                      if (await canLaunchUrl(inUrl)) {
                        await launchUrl(inUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  _ShareOption(
                    label: 'Copy Link',
                    icon: Icons.link_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
