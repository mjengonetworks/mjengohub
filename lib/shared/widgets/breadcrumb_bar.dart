// lib/shared/widgets/breadcrumb_bar.dart
//
// Horizontal breadcrumb trail (`Home > Articles > Counties > ...`), mirroring
// the website's detail-page breadcrumb nav. New to the Flutter app — no prior
// equivalent existed, so this is the canonical widget every detail screen
// (article/project/incident) should use rather than hand-rolling its own.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  const BreadcrumbItem(this.label, {this.onTap});
}

/// Horizontally-scrolling breadcrumb trail — never wraps, never forces
/// viewport overflow. The last item is always the current page (non-tappable,
/// rendered in the heading color); earlier items route back when tapped.
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final EdgeInsetsGeometry padding;
  const BreadcrumbBar({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.captionSlate.withValues(alpha: 0.6),
                ),
              ),
            _Crumb(item: items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isLast;
  const _Crumb({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: 11.5,
        fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
        color: isLast ? AppColors.textDark : AppColors.captionSlate,
      ),
    );
    if (isLast || item.onTap == null) return text;
    return GestureDetector(onTap: item.onTap, child: text);
  }
}
