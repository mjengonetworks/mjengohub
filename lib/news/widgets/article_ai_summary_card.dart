import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact presentation for the public article micro-summary.
///
/// Request state and authentication remain owned by the article detail screen;
/// this widget only renders the supplied state and invokes callbacks.
class ArticleAiSummaryCard extends StatelessWidget {
  final String? summary;
  final bool loading;
  final bool requested;
  final String? error;
  final bool cached;
  final bool signedIn;
  final VoidCallback onRequest;
  final VoidCallback onSignIn;

  const ArticleAiSummaryCard({
    super.key,
    this.summary,
    this.loading = false,
    this.requested = false,
    this.error,
    this.cached = false,
    this.signedIn = false,
    required this.onRequest,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary?.trim().isNotEmpty == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        border: Border.all(color: const Color(0x5238BDF8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFF7DD3FC),
              ),
              const SizedBox(width: 6),
              Text(
                'MJENGO HUB AI',
                style: GoogleFonts.montserrat(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFF0F9FF),
                ),
              ),
              if (cached) ...[
                const Spacer(),
                Text(
                  'CACHED',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7DD3FC),
                  ),
                ),
              ],
            ],
          ),
          if (hasSummary) ...[
            const SizedBox(height: 8),
            Text(
              summary!,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFFE2E8F0),
              ),
            ),
            if (!signedIn) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSignIn,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0EA5E9),
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Sign in to Chat'),
                ),
              ),
            ],
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                height: 1.4,
                color: const Color(0xFFFECACA),
              ),
            ),
          ],
          if (!hasSummary || error != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBAE6FD),
                    side: const BorderSide(color: Color(0x7338BDF8)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: Text(
                    loading
                        ? 'Summarizing…'
                        : requested
                        ? 'Retry AI Summary'
                        : 'Quick AI Summary',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
