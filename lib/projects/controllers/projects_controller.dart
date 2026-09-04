// lib/projects/controllers/projects_controller.dart
import 'package:get/get.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';

class ProjectsController extends GetxController {
  final _service = ProjectsService();

  /// 'infrastructure' (Infrastructure Tracker) or 'private_development'
  /// (Private Projects) — fixed per screen instance so the two trackers
  /// never mix rows. See ProjectsScreen's projectType param.
  final String projectType;
  ProjectsController({this.projectType = 'infrastructure'});

  final projects = <Project>[].obs;
  final featuredProjects = <Project>[].obs;
  final clients = <ProjectClient>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final selectedStatus = ''.obs;
  final selectedClientSlug = ''.obs;
  final selectedCounty = ''.obs;
  final searchQuery = ''.obs;

  /// Toggles between the list and the interactive map (ProjectsMapView) on
  /// ProjectsScreen. Kept here rather than as screen-local state so it
  /// survives the screen's own rebuilds.
  final showMap = false.obs;

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
    final set = <String>{};
    for (final p in projects) {
      if (p.county != null && p.county!.isNotEmpty) set.add(p.county!);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    _page = 1;
    _hasMore = true;

    final results = await Future.wait([
      _service.getProjects(projectType: projectType, featured: true, perPage: 4),
      _service.getProjects(
        projectType: projectType,
        status: selectedStatus.value,
        clientSlug: selectedClientSlug.value,
        county: selectedCounty.value,
        q: searchQuery.value,
        page: 1,
      ),
      _service.getClients(),
    ]);

    featuredProjects.value = results[0] as List<Project>;
    projects.value = results[1] as List<Project>;
    clients.value = results[2] as List<ProjectClient>;
    _hasMore = (results[1] as List).length >= 12;

    isLoading.value = false;
  }

  Future<void> applyFilters({
    String? status,
    String? clientSlug,
    String? county,
    String? q,
  }) async {
    selectedStatus.value = status ?? '';
    selectedClientSlug.value = clientSlug ?? '';
    selectedCounty.value = county ?? '';
    searchQuery.value = q ?? '';
    await fetchAll();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;
    _isFetchingMore = true;
    _page++;
    final more = await _service.getProjects(
      projectType: projectType,
      status: selectedStatus.value,
      clientSlug: selectedClientSlug.value,
      county: selectedCounty.value,
      q: searchQuery.value,
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
      Get.snackbar('Error', 'Could not update follow status. Please try again.', snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Done', result ? 'Project published' : 'Project unpublished', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', 'Could not update publish status.', snackPosition: SnackPosition.BOTTOM);
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
