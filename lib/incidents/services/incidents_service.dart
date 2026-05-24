// lib/incidents/services/incidents_service.dart
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/base_service.dart';
import '../models/incident_model.dart';

class IncidentsService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<Incident>> getIncidents({
    required String type,
    String? severity,
    String? county,
    String? q,
    bool featured = false,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final query = <String, dynamic>{
        'type': type,
        'page': '$page',
        'per_page': '$perPage',
      };
      if (severity != null && severity.isNotEmpty) query['severity'] = severity;
      if (county != null && county.isNotEmpty) query['county'] = county;
      if (q != null && q.isNotEmpty) query['q'] = q;
      if (featured) query['featured'] = 'true';

      final res = await _api.getRequest('incidents', query: query);
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Incident.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('IncidentsService.getIncidents error: $e');
      return [];
    }
  }

  Future<Incident?> getIncident(String slug) async {
    try {
      final res = await _api.getRequest('incidents/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return Incident.fromJson(data);
      }
      return null;
    } catch (e) {
      print('IncidentsService.getIncident error: $e');
      return null;
    }
  }

  Future<bool> addComment({
    required int incidentId,
    required String name,
    required String content,
    String? email,
    int? parentId,
  }) async {
    try {
      final res = await _api.postRequest('incidents/$incidentId/comment', {
        'name': name,
        'content': content,
        if (email != null) 'email': email,
        if (parentId != null) 'parent_id': parentId,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('IncidentsService.addComment error: $e');
      return false;
    }
  }

  Future<int?> submitNewIncident({
    required String incidentType,
    required String title,
    required String description,
    required String location,
    String? county,
    required String incidentDate,
    required String severity,
    int casualties = 0,
    int injuries = 0,
    String? lessonsLearned,
  }) async {
    try {
      final res = await _api.postRequest('incidents', {
        'incident_type': incidentType,
        'title': title,
        'description': description,
        'location': location,
        if (county != null && county.isNotEmpty) 'county': county,
        'incident_date': incidentDate,
        'severity': severity,
        'casualties': casualties,
        'injuries': injuries,
        if (lessonsLearned != null && lessonsLearned.isNotEmpty)
          'lessons_learned': lessonsLearned,
      });
      if ((res.statusCode == 200 || res.statusCode == 201) && res.body != null) {
        return res.body['id'] as int?;
      }
      return null;
    } catch (e) {
      print('IncidentsService.submitNewIncident error: $e');
      return null;
    }
  }

  Future<bool> uploadIncidentImage({
    required int incidentId,
    required XFile imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final status = await _api.uploadFile(
        'incidents/$incidentId/media',
        bytes,
        imageFile.name,
        fieldName: 'image',
      );
      return status == 200 || status == 201;
    } catch (e) {
      print('IncidentsService.uploadIncidentImage error: $e');
      return false;
    }
  }

  Future<bool> suggestEdit({
    required int incidentId,
    required String fieldName,
    required String proposedValue,
    String? submitterName,
    String? submitterEmail,
    String? reason,
  }) async {
    try {
      final res = await _api.postRequest('incidents/$incidentId/suggest-edit', {
        'field_name': fieldName,
        'proposed_value': proposedValue,
        if (submitterName != null) 'submitter_name': submitterName,
        if (submitterEmail != null) 'submitter_email': submitterEmail,
        if (reason != null) 'reason': reason,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('IncidentsService.suggestEdit error: $e');
      return false;
    }
  }
}
