// lib/projects/services/projects_service.dart
import 'package:get/get.dart';
import '../../services/base_service.dart';
import '../models/project_model.dart';

class ProjectsService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<Project>> getProjects({
    String? status,
    String? county,
    String? clientSlug,
    String? q,
    bool featured = false,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (county != null && county.isNotEmpty) query['county'] = county;
      if (clientSlug != null && clientSlug.isNotEmpty) query['client'] = clientSlug;
      if (q != null && q.isNotEmpty) query['q'] = q;
      if (featured) query['featured'] = 'true';

      final res = await _api.getRequest('projects', query: query);
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Project.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('ProjectsService.getProjects error: $e');
      return [];
    }
  }

  Future<Project?> getProject(String slug) async {
    try {
      final res = await _api.getRequest('projects/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return Project.fromJson(data);
      }
      return null;
    } catch (e) {
      print('ProjectsService.getProject error: $e');
      return null;
    }
  }

  Future<List<ProjectClient>> getClients() async {
    try {
      final res = await _api.getRequest('clients');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ProjectClient.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('ProjectsService.getClients error: $e');
      return [];
    }
  }

  Future<bool> rateProject(int projectId, int rating) async {
    try {
      final res = await _api.postRequest(
        'projects/$projectId/rate',
        {'rating': rating},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('ProjectsService.rateProject error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> suggestEdit({
    required int projectId,
    required String fieldName,
    required String proposedValue,
    String? submitterName,
    String? submitterEmail,
    String? reason,
  }) async {
    try {
      final res = await _api.postRequest('projects/$projectId/suggest-edit', {
        'field_name': fieldName,
        'proposed_value': proposedValue,
        if (submitterName != null) 'submitter_name': submitterName,
        if (submitterEmail != null) 'submitter_email': submitterEmail,
        if (reason != null) 'reason': reason,
      });
      return res.body as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('ProjectsService.suggestEdit error: $e');
      return {'error': e.toString()};
    }
  }
}
