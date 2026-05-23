// lib/news/widgets/article_list_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article_model.dart';
import 'net_image.dart';

/// Row-style article tile used in the Discover screen list.
class ArticleListTile extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleListTile({Key? key, required this.article, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            NetImage(
              url: article.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 14),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Text(
                        article.timeAgo,
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Text(
                        '${article.formattedViews} views',
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
