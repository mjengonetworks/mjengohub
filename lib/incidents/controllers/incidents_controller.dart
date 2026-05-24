// lib/incidents/controllers/incidents_controller.dart
import 'package:get/get.dart';
import '../models/incident_model.dart';
import '../services/incidents_service.dart';

class IncidentsController extends GetxController {
  final _service = IncidentsService();
  final String incidentType;

  IncidentsController(this.incidentType);

  final incidents = <Incident>[].obs;
  final featuredIncidents = <Incident>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final selectedSeverity = ''.obs;
  final searchQuery = ''.obs;
  final countyFilter = ''.obs;

  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    _page = 1;
    _hasMore = true;

    final results = await Future.wait([
      _service.getIncidents(type: incidentType, featured: true, perPage: 3),
      _service.getIncidents(
        type: incidentType,
        severity: selectedSeverity.value,
        county: countyFilter.value,
        q: searchQuery.value,
        page: 1,
      ),
    ]);

    featuredIncidents.value = results[0];
    incidents.value = results[1];
    _hasMore = results[1].length >= 12;
    isLoading.value = false;
  }

  Future<void> applyFilters({
    String? severity,
    String? county,
    String? q,
  }) async {
    // Only update values that were explicitly passed — preserves other filters
    if (severity != null) selectedSeverity.value = severity;
    if (county != null)   countyFilter.value     = county;
    if (q != null)        searchQuery.value       = q;
    await fetchAll();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetchingMore) return;
    _isFetchingMore = true;
    _page++;
    final more = await _service.getIncidents(
      type: incidentType,
      severity: selectedSeverity.value,
      county: countyFilter.value,
      q: searchQuery.value,
      page: _page,
    );
    incidents.addAll(more);
    _hasMore = more.length >= 12;
    _isFetchingMore = false;
  }
}

class IncidentDetailController extends GetxController {
  final _service = IncidentsService();

  final incident = Rxn<Incident>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final commentSubmitting = false.obs;

  final String slug;
  IncidentDetailController(this.slug);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    final i = await _service.getIncident(slug);
    if (i != null) {
      incident.value = i;
    } else {
      errorMessage.value = 'Could not load incident details.';
    }
    isLoading.value = false;
  }

  Future<void> submitComment({
    required String name,
    required String content,
    String? email,
    int? parentId,
  }) async {
    if (incident.value == null) return;
    commentSubmitting.value = true;
    final ok = await _service.addComment(
      incidentId: incident.value!.id,
      name: name,
      content: content,
      email: email,
      parentId: parentId,
    );
    commentSubmitting.value = false;
    if (ok) {
      Get.snackbar(
        'Comment submitted',
        'Your comment is pending review.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not submit comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
