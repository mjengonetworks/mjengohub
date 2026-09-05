import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmarks_service.dart';
import '../theme/app_theme.dart';
import '../../navigation/app_header.dart';
import '../../news/screens/article_detail_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({Key? key}) : super(key: key);

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  List<BookmarkedItem> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final items = await BookmarksService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const AppHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: const Color(0xFF1A1A2E)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Saved Bookmarks',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_bookmarks.length}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bookmarks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bookmark_outline_rounded,
                                size: 64, color: const Color(0xFF8888AA)),
                            const SizedBox(height: 16),
                            Text(
                              'No saved items yet',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the bookmark icon on any article to save it here.',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13, color: const Color(0xFF8888AA)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookmarks.length,
                        itemBuilder: (ctx, index) {
                          final item = _bookmarks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: item.category != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        item.category!,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: const Color(0xFF2563EB)),
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await BookmarksService.toggleBookmark(item);
                                  _loadBookmarks();
                                },
                              ),
                              onTap: () {
                                if (item.type == 'article') {
                                  Get.to(() => const ArticleDetailScreen(),
                                      arguments: item.slug);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

