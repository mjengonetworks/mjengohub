// lib/search/widgets/omnibar.dart
//
// Global AI-augmented search modal — distinct from the full-page
// SearchScreen (which hits the confirmed-live `GET /search` covering
// articles/services/reports). The Omnibar targets `GET ai-search`, which is
// not confirmed live (see ai_search_models.dart); it still ships fully
// wired so it lights up the moment the backend adds the route, degrading to
// a clear "not available yet" empty state until then, same as
// MjengoAuthController's `auth/google` handling.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../models/ai_chat_thread_models.dart';
import '../models/ai_search_models.dart';
import '../services/ai_chat_thread_service.dart';
import '../services/search_service.dart';

const _starterChips = [
  'Nairobi Expressway',
  'KeNHA tenders & roads',
  'Affordable Housing Programme',
  'NCA compliance guides',
];

/// One turn in the on-screen conversation thread: the query that was
/// submitted (typed in the main search field, tapped from a starter chip, or
/// typed into the follow-up field) plus its result once it lands. There is
/// no backend conversation/session id — `GET ai-search` is a stateless
/// single-query endpoint (see ai_search_models.dart) — so "threading" here
/// is purely a client-side list of independent queries rendered together,
/// not a real multi-turn context sent to the server.
class _ChatTurn {
  final String query;
  final AISearchResponse? result;
  final bool loading;

  const _ChatTurn({required this.query, this.result, this.loading = true});

  _ChatTurn copyWith({AISearchResponse? result, bool? loading}) => _ChatTurn(
    query: query,
    result: result ?? this.result,
    loading: loading ?? this.loading,
  );
}

/// Opens the Omnibar as a near-fullscreen modal sheet with an autofocus
/// search field.
void showAiSearchSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const _OmnibarSheet(),
  );
}

class _OmnibarSheet extends StatefulWidget {
  const _OmnibarSheet();

  @override
  State<_OmnibarSheet> createState() => _OmnibarSheetState();
}

class _OmnibarSheetState extends State<_OmnibarSheet> {
  final _service = SearchService();
  final _chatService = AiChatThreadService();
  final _controller = TextEditingController();
  final _followUpController = TextEditingController();
  final _focusNode = FocusNode();

  final List<_ChatTurn> _turns = [];

  /// Set once a turn's response carries a `thread_id` (see
  /// [AISearchResponse.threadId]) or a past thread is opened via "My
  /// Chats". While set, further sends go through the persisted
  /// `POST /api/ai/chat/followup` flow instead of `ai-search`.
  String? _activeThreadId;

  MjengoAuthController? get _auth {
    try {
      return Get.find<MjengoAuthController>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _followUpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isAuthenticated => _auth?.isAuthenticated ?? false;

  void _startNewChat() {
    setState(() {
      _turns.clear();
      _activeThreadId = null;
      _controller.clear();
      _followUpController.clear();
    });
  }

  void _openMyChats() {
    if (!_isAuthenticated) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MyChatsSheet(
        service: _chatService,
        onThreadSelected: _loadThread,
      ),
    );
  }

  Future<void> _loadThread(AiChatThread thread) async {
    Navigator.of(context).pop(); // close the My Chats sheet
    setState(() {
      _turns.clear();
      _turns.add(const _ChatTurn(query: '', loading: true));
      _activeThreadId = thread.id;
    });
    final detail = await _chatService.fetchThreadDetail(thread.id);
    if (!mounted) return;
    setState(() {
      _turns.clear();
      if (detail == null) return;
      final messages = detail.messages;
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        if (!msg.isUser) continue;
        final reply = (i + 1 < messages.length && !messages[i + 1].isUser)
            ? messages[i + 1].content
            : null;
        _turns.add(
          _ChatTurn(
            query: msg.content,
            loading: false,
            result: AISearchResponse(query: msg.content, aiSummary: reply),
          ),
        );
      }
    });
  }

  Future<void> _submit(String rawValue) async {
    final value = rawValue.trim();
    if (value.length < kMinSearchLength || !_isAuthenticated) return;

    _controller.clear();
    _followUpController.clear();
    _focusNode.unfocus();

    setState(() => _turns.add(_ChatTurn(query: value)));
    final turnIndex = _turns.length - 1;

    final threadId = _activeThreadId;
    if (threadId != null) {
      final followUp = await _chatService.sendFollowUp(
        message: value,
        threadId: threadId,
      );
      if (!mounted) return;
      if (followUp != null) {
        if (followUp.threadId.isNotEmpty) {
          _activeThreadId = followUp.threadId;
        }
        setState(
          () => _turns[turnIndex] = _turns[turnIndex].copyWith(
            result: AISearchResponse(query: value, aiSummary: followUp.reply),
            loading: false,
          ),
        );
        return;
      }
      // Follow-up endpoint not live yet — degrade to a fresh ai-search call
      // rather than leaving the turn stuck loading.
    }

    final result = await _service.fetchAISearch(value);
    if (!mounted) return;
    if (result.threadId != null && result.threadId!.isNotEmpty) {
      _activeThreadId = result.threadId;
    }
    setState(
      () => _turns[turnIndex] = _turns[turnIndex].copyWith(
        result: result,
        loading: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final fieldFill = isDark ? AppColorsDark.card : AppColors.mutedCanvas;
    final divider = isDark ? AppColorsDark.border : AppColors.divider;
    final textColor = isDark ? AppColorsDark.headingText : AppColors.textDark;
    final captionColor = isDark
        ? AppColorsDark.secondaryText
        : AppColors.captionSlate;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height - topPadding - 24,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          final authed = _auth?.isAuthenticated ?? false;
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mjengo Hub AI',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    if (authed && _turns.isNotEmpty)
                      IconButton(
                        tooltip: 'New Chat',
                        icon: Icon(Icons.add_comment_outlined, color: textColor),
                        onPressed: _startNewChat,
                      ),
                    IconButton(
                      tooltip: 'My Chats',
                      icon: Icon(Icons.history_rounded, color: textColor),
                      onPressed: authed ? _openMyChats : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              if (!authed) _SignInToChatBanner(sheetContext: context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: divider),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: authed,
                    autofocus: authed,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submit,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: authed
                          ? 'Search projects, contractors, agencies, or articles...'
                          : 'Sign in to chat with Mjengo Hub AI',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: captionColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: captionColor,
                        size: 20,
                      ),
                      suffixIcon: (!authed || _controller.text.trim().isEmpty)
                          ? null
                          : Padding(
                              padding: const EdgeInsets.all(6),
                              child: Material(
                                color: AppColors.accentBlue,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _submit(_controller.text),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _turns.isEmpty
                    ? _EmptyState(onChipTap: authed ? _submit : (_) {})
                    : _ThreadView(turns: _turns),
              ),
              if (_turns.isNotEmpty)
                _FollowUpBar(
                  controller: _followUpController,
                  fieldFill: fieldFill,
                  divider: divider,
                  textColor: textColor,
                  captionColor: captionColor,
                  enabled: authed,
                  onSubmit: _submit,
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Persistent follow-up input pinned beneath the conversation thread —
/// distinct from the main search field above (which starts a fresh thread);
/// this one keeps appending turns to the same on-screen conversation.
class _FollowUpBar extends StatelessWidget {
  final TextEditingController controller;
  final Color fieldFill;
  final Color divider;
  final Color textColor;
  final Color captionColor;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  const _FollowUpBar({
    required this.controller,
    required this.fieldFill,
    required this.divider,
    required this.textColor,
    required this.captionColor,
    required this.onSubmit,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: fieldFill,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: divider),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.go,
            onSubmitted: onSubmit,
            style: GoogleFonts.montserrat(fontSize: 13.5, color: textColor),
            decoration: InputDecoration(
              hintText: enabled ? 'Ask a follow-up question...' : 'Sign in to chat',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 13,
                color: captionColor,
              ),
              suffixIcon: !enabled
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: AppColors.accentBlue,
                      ),
                      onPressed: () => onSubmit(controller.text),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent inline banner shown in place of an actionable input whenever
/// the viewer isn't signed in — replaces the old click-time "guest gate"
/// bottom sheet with an always-visible state, per the auth-gate spec.
class _SignInToChatBanner extends StatelessWidget {
  final BuildContext sheetContext;
  const _SignInToChatBanner({required this.sheetContext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.accentBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sign in to chat with Mjengo Hub AI and save your threads.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.of(sheetContext).pop();
                Get.toNamed(AppRoutes.login);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "My Chats" thread history sheet — `GET /api/ai-chat/threads`. Not
/// confirmed live (see ai_chat_thread_models.dart); degrades to the empty
/// state below until the backend adds the route.
class _MyChatsSheet extends StatefulWidget {
  final AiChatThreadService service;
  final ValueChanged<AiChatThread> onThreadSelected;

  const _MyChatsSheet({required this.service, required this.onThreadSelected});

  @override
  State<_MyChatsSheet> createState() => _MyChatsSheetState();
}

class _MyChatsSheetState extends State<_MyChatsSheet> {
  late Future<List<AiChatThread>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchThreads();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textColor = isDark ? AppColorsDark.headingText : AppColors.textDark;
    final captionColor = isDark
        ? AppColorsDark.secondaryText
        : AppColors.captionSlate;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    'My Chats',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<AiChatThread>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final threads = snapshot.data ?? const [];
                  if (threads.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Text(
                        'No previous chats found. Start a new conversation!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: captionColor,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) {
                      final thread = threads[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.accentBlue,
                        ),
                        title: Text(
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        subtitle: thread.updatedAt != null
                            ? Text(
                                thread.updatedAt!.toLocal().toString().split(
                                  '.',
                                )[0],
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: captionColor,
                                ),
                              )
                            : null,
                        onTap: () => widget.onThreadSelected(thread),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadView extends StatelessWidget {
  final List<_ChatTurn> turns;
  const _ThreadView({required this.turns});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [for (final turn in turns) _TurnView(turn: turn)],
    );
  }
}

class _TurnView extends StatelessWidget {
  final _ChatTurn turn;
  const _TurnView({required this.turn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                turn.query,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (turn.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            _ResultBody(result: turn.result),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final AISearchResponse? result;
  const _ResultBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final res = result;
    if (res == null) return const SizedBox.shrink();
    if (res.isEmpty) return _NoResults(query: res.query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (res.aiSummary != null) ...[
          _AiAnswerCard(summary: res.aiSummary!),
          const SizedBox(height: 12),
        ],
        for (final category in res.categories)
          if (category.items.isNotEmpty) _CategorySection(category: category),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onChipTap;
  const _EmptyState({required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Try asking',
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.captionSlate,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _starterChips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final chip = _starterChips[i];
              return ActionChip(
                label: Text(
                  chip,
                  style: GoogleFonts.montserrat(fontSize: 12.5),
                ),
                backgroundColor: AppColors.mutedCanvas,
                side: const BorderSide(color: AppColors.divider),
                onPressed: () => onChipTap(chip),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: AppColors.captionSlate,
            ),
            const SizedBox(height: 10),
            Text(
              'No AI results for "$query" yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try the regular search from the Discover tab, or rephrase your question.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                color: AppColors.captionSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAnswerCard extends StatelessWidget {
  final String summary;
  const _AiAnswerCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2E4D), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Mjengo Hub AI Answer',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AISearchCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in category.items) ...[
            _ResultTile(sectionLabel: category.label, item: item),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String sectionLabel;
  final AISearchResultItem item;
  const _ResultTile({required this.sectionLabel, required this.item});

  /// Routes by [AISearchResultItem.type] first ('project'/'article'/
  /// 'agency'/'entity') when the backend sends one; falls back to inferring
  /// from [sectionLabel] otherwise — "Guides & Insights" rows are always
  /// articles, "Projects & Agencies" rows default to a project (the more
  /// common row there) unless [type] says 'agency'/'entity'.
  void _open() {
    final slug = item.slug;
    if (slug == null || slug.isEmpty) return;
    final isGuide = sectionLabel == 'Guides & Insights';
    final type = item.type;
    if (type == 'article' || (type == null && isGuide)) {
      Get.toNamed(AppRoutes.articleDetail, arguments: slug);
    } else if (type == 'agency' || type == 'entity') {
      Get.toNamed(
        AppRoutes.entityProfile,
        arguments: {'slug': slug, 'fallbackName': item.title},
      );
    } else {
      Get.toNamed(AppRoutes.projectDetail, arguments: slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetImage(
                url: item.imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholderColor: AppColors.mutedCanvas,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (item.subtitle != null || item.county != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.subtitle != null)
                          Flexible(
                            child: Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.captionSlate,
                              ),
                            ),
                          ),
                        if (item.county != null) ...[
                          if (item.subtitle != null) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mutedCanvas,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              item.county!,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.captionSlate,
            ),
          ],
        ),
      ),
    );
  }
}
