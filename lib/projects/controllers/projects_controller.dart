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

  /// Private Projects' "Typology / Category" filter facet. There is no
  /// server-side typology column on `Project` (only the free-text
  /// `project_type`), so — same as `BuildingsTaxonomy` — this is matched
  /// client-side against already-loaded rows rather than sent as a query
  /// param. See [ProjectsScreen.filteredProjects].
  final selectedTypology = ''.obs;

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

  double? get costMin => switch (selectedCostTier.value) {
    '100M-500M' => 100000000,
    '500M-1B' => 500000000,
    '1B-5B' => 1000000000,
    '5B+' => 5000000000,
    _ => selectedCostTier.value == '<100M' ? 0 : null,
  };
  double? get costMax => switch (selectedCostTier.value) {
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
    selectedStatus.value.isNotEmpty,
    selectedCostTier.value.isNotEmpty,
    selectedContractor.value.isNotEmpty,
    selectedConsultant.value.isNotEmpty,
    selectedFinancier.value.isNotEmpty,
    selectedClient.value.isNotEmpty,
    selectedCategory.value.isNotEmpty,
    selectedUser.value.isNotEmpty,
    selectedTypology.value.isNotEmpty,
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
      selectedUser.value.isNotEmpty;

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

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    _page = 1;
    _hasMore = true;

    final result = await _service.getProjects(
      projectType: projectType,
      status: selectedStatus.value,
      county: selectedCounty.value,
      counties: selectedCounties,
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
      page: 1,
    );

    projects.value = result;
    _hasMore = result.length >= 12;

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
    if (user != null) selectedUser.value = user;
    if (userName != null) selectedUserName.value = userName;
    if (sort != null) selectedSort.value = sort;
    if (q != null) searchQuery.value = q;
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

  Future<void> applyCountySelection(List<String> counties) async {
    selectedCounties.assignAll(counties);
    await applyFilters(county: counties.length == 1 ? counties.first : '');
  }

  Future<void> clearFilters() async {
    selectedStatus.value = '';
    selectedCounty.value = '';
    selectedCounties.clear();
    selectedSector.value = '';
    selectedCostTier.value = '';
    selectedContractor.value = '';
    selectedConsultant.value = '';
    selectedFinancier.value = '';
    selectedClient.value = '';
    selectedClientName.value = '';
    selectedCategory.value = '';
    selectedUser.value = '';
    selectedUserName.value = '';
    selectedSort.value = '';
    selectedTypology.value = '';
    searchQuery.value = '';
    await fetchAll();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;
    _isFetchingMore = true;
    _page++;
    final more = await _service.getProjects(
      projectType: projectType,
      status: selectedStatus.value,
      county: selectedCounty.value,
      counties: selectedCounties,
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
      page: _page,
    );
    projects.addAll(more);
    _hasMore = more.length >= 12;
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
}
