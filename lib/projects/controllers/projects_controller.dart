// lib/projects/controllers/projects_controller.dart
import 'package:get/get.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../../shared/data/kenya_counties.dart';

class ProjectsController extends GetxController {
  final _service = ProjectsService();

  /// 'infrastructure' (Infrastructure Tracker) or 'private_development'
  /// (Private Projects) — fixed per screen instance so the two trackers
  /// never mix rows. See ProjectsScreen's projectType param.
  final String projectType;
  ProjectsController({this.projectType = 'infrastructure'});

  final projects = <Project>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final selectedStatus = ''.obs;
  final selectedCounty = ''.obs;
  final selectedCounties = <String>[].obs;
  final selectedSector = ''.obs;
  final searchQuery = ''.obs;
  final selectedCostTier = ''.obs;

  /// Multi-select status facet (the Filters sheet's "Status" chips) — set
  /// alongside/instead of [selectedStatus] when more than one status is
  /// picked. `GET /projects` does not actually support multi-value status
  /// server-side (repeated `status=` params only keep the first one, and a
  /// comma-joined value matches nothing — confirmed live 2026-09-16), so
  /// more than one selected value is served by fanning out one request per
  /// value and merging (see [_fetchProjects]), the same pragmatic pattern
  /// already used by [_fetchCounts] elsewhere in this file.
  final selectedStatuses = <String>[].obs;

  /// Multi-select tracker-category facet, same fan-out-and-merge treatment
  /// as [selectedStatuses] (category multi-value support is unconfirmed
  /// server-side too, so this doesn't rely on it either).
  final selectedCategories = <String>[].obs;

  /// Free-text stakeholder filters — set when the catalog is opened from a
  /// tapped entity link on ProjectDetailScreen's Info Card (Contractor/
  /// Consultant/Financier are plain strings server-side, see
  /// ProjectsService.getProjects). Distinct from selectedCounty/selectedSector
  /// only in that they stack via the active-filter chip bar rather than a
  /// filter-sheet control.
  final selectedContractor = ''.obs;
  final selectedConsultant = ''.obs;
  final selectedFinancier = ''.obs;

  /// Client filter is keyed by slug server-side (`ProjectsService.clientSlug`)
  /// but the entity header/dismiss-pill need a human label too, so the
  /// display name travels alongside it rather than being re-derived.
  final selectedClient = ''.obs;
  final selectedClientName = ''.obs;

  /// `category` — a real, distinct query param from `sector` on `GET
  /// projects` (see ProjectsService.categorySlug).
  final selectedCategory = ''.obs;

  /// Human display name for [selectedCategory], resolved from the real
  /// `TrackerSectionGroup.displayLabel` at the tap site (see
  /// TrackerDynamicSections) rather than a hardcoded slug->label table, so
  /// new backend categories render correctly with no code change. Falls
  /// back to a generic Title Case conversion of the slug when unset (e.g.
  /// arriving via a route argument that doesn't carry a label).
  final selectedCategoryName = ''.obs;

  /// `submitted_by` — unconfirmed against the live backend (no documented
  /// route for it), added defensively the same way `updated_at`/
  /// `official_project_name` were on the Project model: wired end-to-end so
  /// it works the moment the backend supports it, degrades to an empty
  /// result set (not a crash) if it doesn't yet.
  final selectedUser = ''.obs;
  final selectedUserName = ''.obs;

  /// '' | 'trending' — backs the Portfolio Segmentation tabs' "Trending"
  /// option. Kept separate from [selectedStatus] because trending is a
  /// sort, not a status filter; the "All"/"Ongoing"/"Completed" tabs read
  /// and write [selectedStatus] directly instead.
  final selectedSort = ''.obs;

  /// '' | 'newest' | 'recently_updated' | 'budget_desc' — the "Sort By"
  /// filter-bar control. `GET /projects` has no confirmed server param for
  /// any of these beyond `sort=trending` (see [selectedSort]), so this is
  /// applied as a client-side sort of the already-loaded page in
  /// ProjectsScreen's `_buildProjectsGrid`, same pragmatic pattern as
  /// [selectedTypologies].
  final clientSortBy = ''.obs;

  /// Private Projects' "Typology / Category" filter facet — multi-select
  /// (OR-matched). There is no server-side typology column on `Project`
  /// (only the free-text `project_type`), so — same as `BuildingsTaxonomy`
  /// — this is matched client-side against already-loaded rows rather than
  /// sent as a query param. See ProjectsScreen's `_buildProjectsGrid`.
  final selectedTypologies = <String>[].obs;

  static const sectorOptions = <String>[
    'Transport',
    'Energy',
    'Water',
    'Ports',
    'Rail',
    'Housing',
    'ICT',
    'Other',
  ];

  /// Explicit KES range set by tapping the Budget quick-fact chip on
  /// ProjectDetailScreen (see `_openBudgetFilter`) — a dynamic bracket
  /// computed around one project's actual `contractValue`, distinct from
  /// the four fixed [selectedCostTier] presets below. Takes priority over
  /// [selectedCostTier] whenever set; setting a tier clears this and vice
  /// versa (see [applyBudgetFilter]/[applyFilters]) so the two never both
  /// constrain the query at once.
  final budgetRangeMin = Rxn<double>();
  final budgetRangeMax = Rxn<double>();

  double? get costMin =>
      budgetRangeMin.value ??
      switch (selectedCostTier.value) {
        '100M-500M' => 100000000,
        '500M-1B' => 500000000,
        '1B-5B' => 1000000000,
        '5B+' => 5000000000,
        _ => selectedCostTier.value == '<100M' ? 0 : null,
      };
  double? get costMax =>
      budgetRangeMax.value ??
      switch (selectedCostTier.value) {
        '<100M' => 100000000,
        '100M-500M' => 500000000,
        '500M-1B' => 1000000000,
        '1B-5B' => 5000000000,
        _ => null,
      };

  double? get costUsdMin => switch (selectedCostTier.value) {
    'usd_under_1m' => 0,
    'usd_1m_5m' => 1000000,
    'usd_5m_10m' => 5000000,
    'usd_10m_plus' => 10000000,
    _ => null,
  };

  double? get costUsdMax => switch (selectedCostTier.value) {
    'usd_under_1m' => 1000000,
    'usd_1m_5m' => 5000000,
    'usd_5m_10m' => 10000000,
    _ => null,
  };

  int get activeFilterCount => [
    selectedCounties.isNotEmpty,
    selectedSector.value.isNotEmpty,
    selectedStatus.value.isNotEmpty || selectedStatuses.isNotEmpty,
    selectedCostTier.value.isNotEmpty,
    budgetRangeMin.value != null || budgetRangeMax.value != null,
    selectedContractor.value.isNotEmpty,
    selectedConsultant.value.isNotEmpty,
    selectedFinancier.value.isNotEmpty,
    selectedClient.value.isNotEmpty,
    selectedCategory.value.isNotEmpty || selectedCategories.isNotEmpty,
    selectedUser.value.isNotEmpty,
    selectedTypologies.isNotEmpty,
  ].where((active) => active).length;

  /// True once any *entity* filter (as opposed to a plain display filter
  /// like status/cost tier) is active — drives the contextual header,
  /// featured-carousel bypass, and Portfolio Segmentation tabs on
  /// ProjectsScreen.
  bool get hasEntityFilter =>
      selectedClient.value.isNotEmpty ||
      selectedContractor.value.isNotEmpty ||
      selectedConsultant.value.isNotEmpty ||
      selectedFinancier.value.isNotEmpty ||
      selectedCounty.value.isNotEmpty ||
      selectedCategory.value.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedUser.value.isNotEmpty;

  /// Broader than [hasEntityFilter] — also true for a status or budget
  /// bracket filter (status tab/status sheet, the fixed [BudgetTier] chips,
  /// or the free "Cost Tier" dropdown). Drives hiding the generic discovery
  /// content (global featured carousel/strip) on a filtered archive view —
  /// see ProjectsScreen's hero banner/featured strip.
  bool get hasArchiveFilter =>
      hasEntityFilter ||
      selectedStatus.value.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      selectedCostTier.value.isNotEmpty ||
      budgetRangeMin.value != null ||
      budgetRangeMax.value != null;

  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  /// There is no `/api/v1/counties` endpoint — the county list on the
  /// website is only queryable server-side. Derive it from whatever
  /// projects are already loaded instead of hardcoding Kenya's 47 counties.
  List<String> get availableCounties {
    return List<String>.from(kKenyaCounties);
  }

  /// Whichever of status/county/category has more than one value selected —
  /// only ever one at a time drives fan-out (see [_fetchPage]); a
  /// simultaneous multi-select on a second facet falls back to that facet's
  /// first value for that fetch rather than a combinatorial cross-product of
  /// requests.
  String? get _fanOutDimension {
    if (selectedStatuses.length > 1) return 'status';
    if (selectedCounties.length > 1) return 'county';
    if (selectedCategories.length > 1) return 'category';
    return null;
  }

  /// Backend `GET /projects` reality check (2026-09-16): `status`/`county`
  /// only ever take a single value — repeated params keep just the first,
  /// and a comma-joined value matches nothing. So a multi-select facet here
  /// is served by firing one request per selected value and merging
  /// (deduped by id), same pragmatic "best effort, capped rows" pattern
  /// [_fetchCounts]-style helpers already use elsewhere in this app. Only
  /// page 1 is real for a fanned-out fetch — there's no way to page a merged
  /// multi-request result set against this backend, so [loadMore] simply
  /// stops after it (matching `_MostViewedSection`'s "single window, no
  /// further pages" precedent in tracker_dynamic_sections.dart).
  Future<List<Project>> _fetchPage(int page, {required int perPage}) async {
    final dimension = _fanOutDimension;
    if (dimension == null) {
      return _service.getProjects(
        projectType: projectType,
        status: selectedStatus.value,
        county: selectedCounty.value,
        sector: selectedSector.value,
        contractor: selectedContractor.value,
        consultant: selectedConsultant.value,
        financier: selectedFinancier.value,
        clientSlug: selectedClient.value,
        categorySlug: selectedCategory.value,
        submittedBy: selectedUser.value,
        costMin: costMin,
        costMax: costMax,
        costUsdMin: costUsdMin,
        costUsdMax: costUsdMax,
        q: searchQuery.value,
        sort: selectedSort.value.isEmpty ? null : selectedSort.value,
        page: page,
        perPage: perPage,
      );
    }
    if (page > 1) return const [];

    final values = switch (dimension) {
      'status' => selectedStatuses,
      'county' => selectedCounties,
      _ => selectedCategories,
    };
    final perValue = (200 ~/ values.length).clamp(20, 200);
    final merged = <Project>[];
    final seenIds = <int>{};
    for (final value in values) {
      final batch = await _service.getProjects(
        projectType: projectType,
        status: dimension == 'status'
            ? value
            : (selectedStatus.value.isEmpty ? null : selectedStatus.value),
        county: dimension == 'county'
            ? value
            : (selectedCounty.value.isEmpty ? null : selectedCounty.value),
        sector: selectedSector.value,
        contractor: selectedContractor.value,
        consultant: selectedConsultant.value,
        financier: selectedFinancier.value,
        clientSlug: selectedClient.value,
        categorySlug: dimension == 'category'
            ? value
            : (selectedCategory.value.isEmpty ? null : selectedCategory.value),
        submittedBy: selectedUser.value,
        costMin: costMin,
        costMax: costMax,
        costUsdMin: costUsdMin,
        costUsdMax: costUsdMax,
        q: searchQuery.value,
        sort: selectedSort.value.isEmpty ? null : selectedSort.value,
        page: 1,
        perPage: perValue,
      );
      for (final p in batch) {
        if (seenIds.add(p.id)) merged.add(p);
      }
    }
    return merged;
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    _page = 1;
    _hasMore = true;

    final result = await _fetchPage(1, perPage: 12);

    projects.value = result;
    _hasMore = _fanOutDimension == null && result.length >= 12;

    isLoading.value = false;
  }

  /// Each param is applied only when explicitly passed (a null default
  /// means "leave as-is") — an explicit `''` clears that specific filter.
  /// This lets one filter change (e.g. a stakeholder chip's `[x]`) stack
  /// with whatever else is already selected instead of resetting the rest.
  Future<void> applyFilters({
    String? status,
    String? county,
    String? sector,
    String? contractor,
    String? consultant,
    String? financier,
    String? client,
    String? clientName,
    String? category,
    String? categoryName,
    String? user,
    String? userName,
    String? sort,
    String? q,
  }) async {
    if (status != null) selectedStatus.value = status;
    if (county != null) selectedCounty.value = county;
    if (sector != null) selectedSector.value = sector;
    if (contractor != null) selectedContractor.value = contractor;
    if (consultant != null) selectedConsultant.value = consultant;
    if (financier != null) selectedFinancier.value = financier;
    if (client != null) selectedClient.value = client;
    if (clientName != null) selectedClientName.value = clientName;
    if (category != null) selectedCategory.value = category;
    if (categoryName != null) selectedCategoryName.value = categoryName;
    if (user != null) selectedUser.value = user;
    if (userName != null) selectedUserName.value = userName;
    if (sort != null) selectedSort.value = sort;
    if (q != null) searchQuery.value = q;
    await fetchAll();
  }

  /// Sets the dynamic KES budget bracket from the Budget quick-fact chip on
  /// ProjectDetailScreen (`min`/`max` — either end may be null for an
  /// open-ended bracket, e.g. "10B+"). Clears [selectedCostTier] since the
  /// two are mutually exclusive (see [costMin]/[costMax]).
  Future<void> applyBudgetFilter(double? min, double? max) async {
    selectedCostTier.value = '';
    budgetRangeMin.value = min;
    budgetRangeMax.value = max;
    await fetchAll();
  }

  /// Portfolio Segmentation tab selector — All/Ongoing/Completed/Trending.
  /// Preserves every other active filter (entity chips, county, etc.) since
  /// it only ever touches [selectedStatus]/[selectedSort].
  Future<void> selectTab(String tab) async {
    switch (tab) {
      case 'ongoing':
        await applyFilters(status: 'ongoing', sort: '');
        break;
      case 'completed':
        await applyFilters(status: 'completed', sort: '');
        break;
      case 'trending':
        await applyFilters(status: '', sort: 'trending');
        break;
      default:
        await applyFilters(status: '', sort: '');
    }
  }

  /// County multi-select sheet — [counties].length == 1 keeps using the
  /// plain (confirmed-working) `county` param via [selectedCounty];
  /// length > 1 clears it and fans out via [selectedCounties] instead (see
  /// [_fetchPage] — `GET /projects?counties=` is not actually a real
  /// server-side filter, confirmed 2026-09-16).
  Future<void> applyCountySelection(List<String> counties) async {
    selectedCounties.assignAll(counties);
    await applyFilters(county: counties.length == 1 ? counties.first : '');
  }

  /// Status multi-select sheet — same length==1-vs->1 split as
  /// [applyCountySelection], against [selectedStatus]/[selectedStatuses].
  Future<void> applyStatusSelection(List<String> statuses) async {
    selectedStatuses.assignAll(statuses);
    await applyFilters(status: statuses.length == 1 ? statuses.first : '');
  }

  /// Tracker-category multi-select sheet — same pattern again, against
  /// [selectedCategory]/[selectedCategories]. [names] are the matching
  /// display labels (same order as [categories]) for the archive header.
  Future<void> applyCategorySelection(
    List<String> categories,
    List<String> names,
  ) async {
    selectedCategories.assignAll(categories);
    await applyFilters(
      category: categories.length == 1 ? categories.first : '',
      categoryName: names.length == 1 ? names.first : '',
    );
  }

  Future<void> clearFilters() async {
    selectedStatus.value = '';
    selectedStatuses.clear();
    selectedCounty.value = '';
    selectedCounties.clear();
    selectedSector.value = '';
    selectedCostTier.value = '';
    budgetRangeMin.value = null;
    budgetRangeMax.value = null;
    selectedContractor.value = '';
    selectedConsultant.value = '';
    selectedFinancier.value = '';
    selectedClient.value = '';
    selectedClientName.value = '';
    selectedCategory.value = '';
    selectedCategories.clear();
    selectedCategoryName.value = '';
    selectedUser.value = '';
    selectedUserName.value = '';
    selectedSort.value = '';
    selectedTypologies.clear();
    searchQuery.value = '';
    await fetchAll();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;
    _isFetchingMore = true;
    _page++;
    final more = await _fetchPage(_page, perPage: 12);
    projects.addAll(more);
    _hasMore = _fanOutDimension == null && more.length >= 12;
    _isFetchingMore = false;
  }
}

class ProjectDetailController extends GetxController {
  final _service = ProjectsService();

  final project = Rxn<Project>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final userRating = 0.obs;
  final ratingSubmitted = false.obs;
  final ratingLoading = false.obs;

  // Drives the persistent bottom nav's scroll-hide behavior on
  // ProjectDetailScreen (see PersistentBottomNav in main_navigation.dart).
  final navVisible = true.obs;

  final String slug;
  ProjectDetailController(this.slug);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    final p = await _service.getProject(slug);
    if (p != null) {
      project.value = p;
    } else {
      errorMessage.value = 'Could not load project details.';
    }
    isLoading.value = false;
  }

  final followLoading = false.obs;

  /// Optimistic follow/unfollow toggle — flips local state immediately,
  /// reverts if the request fails.
  Future<void> toggleFollow() async {
    final current = project.value;
    if (current == null || followLoading.value) return;
    final next = !current.isFollowing;
    followLoading.value = true;
    project.value = current.copyWith(isFollowing: next);
    final result = await _service.setFollowing(current.id, next);
    if (result == null) {
      project.value = current.copyWith(isFollowing: current.isFollowing);
      Get.snackbar(
        'Error',
        'Could not update follow status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    followLoading.value = false;
  }

  final publishToggling = false.obs;

  /// `GET /projects/{slug}` only ever returns published rows, so flipping
  /// to unpublished would 404 on a re-fetch here — this deliberately
  /// doesn't reload the project afterward (there's also no `is_published`
  /// field on the mobile Project model to reflect either way); it just
  /// confirms the action via snackbar. Managing already-unpublished
  /// projects is an admin-panel (web) task, not this screen's job.
  Future<void> togglePublish() async {
    final current = project.value;
    if (current == null || publishToggling.value) return;
    publishToggling.value = true;
    final result = await _service.togglePublish(current.id);
    publishToggling.value = false;
    if (result != null) {
      Get.snackbar(
        'Done',
        result ? 'Project published' : 'Project unpublished',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not update publish status.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> submitRating(int rating) async {
    if (project.value == null) return;
    ratingLoading.value = true;
    final ok = await _service.rateProject(project.value!.id, rating);
    if (ok) {
      userRating.value = rating;
      ratingSubmitted.value = true;
      Get.snackbar(
        'Thanks!',
        'Your rating has been recorded.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not submit rating. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    ratingLoading.value = false;
  }

  /// Locally tracked active vote direction ('up'/'down'/null) — the backend
  /// envelope has no per-user vote field to restore this from on reload, so
  /// it only reflects votes cast in this session, same as [userRating].
  final activeVote = Rxn<String>();
  final voteLoading = false.obs;

  /// Optimistic up/down vote — flips the local counts and active state
  /// immediately, rolls back and snackbars on failure. Tapping the
  /// already-active direction again is treated as a no-op (there's no
  /// unvote route), matching the fire-once behavior of [submitRating].
  Future<void> vote(String direction) async {
    final current = project.value;
    if (current == null || voteLoading.value) return;
    if (activeVote.value == direction) return;

    final prevVote = activeVote.value;
    final prevUpvotes = current.upvoteCount;
    final prevDownvotes = current.downvoteCount;

    var nextUpvotes = prevUpvotes;
    var nextDownvotes = prevDownvotes;
    if (prevVote == 'up') nextUpvotes--;
    if (prevVote == 'down') nextDownvotes--;
    if (direction == 'up') nextUpvotes++;
    if (direction == 'down') nextDownvotes++;

    voteLoading.value = true;
    activeVote.value = direction;
    project.value = current.copyWith(
      upvoteCount: nextUpvotes,
      downvoteCount: nextDownvotes,
    );

    final result = await _service.voteProject(current.id, direction);
    if (result['success'] == true) {
      final upvotes = (result['upvotes'] as num?)?.toInt();
      final downvotes = (result['downvotes'] as num?)?.toInt();
      if (upvotes != null && downvotes != null) {
        project.value = project.value?.copyWith(
          upvoteCount: upvotes,
          downvoteCount: downvotes,
        );
      }
    } else {
      activeVote.value = prevVote;
      project.value = project.value?.copyWith(
        upvoteCount: prevUpvotes,
        downvoteCount: prevDownvotes,
      );
      Get.snackbar(
        'Error',
        'Could not record your vote. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    voteLoading.value = false;
  }
}
