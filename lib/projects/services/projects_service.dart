// lib/projects/services/projects_service.dart
import 'package:get/get.dart';
import '../../services/base_service.dart';
import '../models/project_model.dart';
import '../models/tracker_sections_model.dart';

class ProjectsService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<Project>> getProjects({
    String? status,
    String? county,
    String? clientSlug,
    String? q,
    bool featured = false,
    /// 'infrastructure' or 'private_development' — matches `Project.project_type`.
    /// Left unset to fetch across both (used nowhere in-app today; every
    /// caller passes one explicitly so the two trackers never mix rows).
    String? projectType,
    /// True for the Built History archive (`Project.is_built_history`).
    bool? isBuiltHistory,
    /// 'global' for the Africa & World showcase (`Project.geo_scope`).
    String? geoScope,
    /// East Africa/Africa/Europe/Asia/North America/South America/Oceania —
    /// Africa & World's category dimension (there's no separate "sector"
    /// taxonomy for this tracker server-side, only region).
    String? region,
    String? heritageCategory,
    String? ownershipType,
    String? completionDecade,
    String? categorySlug,
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
      if (projectType != null && projectType.isNotEmpty) query['project_type'] = projectType;
      if (isBuiltHistory != null) query['is_built_history'] = '$isBuiltHistory';
      if (geoScope != null && geoScope.isNotEmpty) query['geo_scope'] = geoScope;
      if (region != null && region.isNotEmpty) query['region'] = region;
      if (heritageCategory != null && heritageCategory.isNotEmpty) query['heritage_category'] = heritageCategory;
      if (ownershipType != null && ownershipType.isNotEmpty) query['ownership_type'] = ownershipType;
      if (completionDecade != null && completionDecade.isNotEmpty) query['completion_decade'] = completionDecade;
      if (categorySlug != null && categorySlug.isNotEmpty) query['category'] = categorySlug;

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

  /// [name] is required — api.py's `suggest_project_edit` 400s without it,
  /// and reads it (and [email]) under the keys `name`/`email`. This method
  /// previously sent `submitter_name`/`submitter_email`, which the backend
  /// never reads, and treated `name` as optional — every suggestion silently
  /// 400'd. Fixed to match the real contract.
  Future<Map<String, dynamic>> suggestEdit({
    required int projectId,
    required String fieldName,
    required String proposedValue,
    required String name,
    String? email,
    String? reason,
  }) async {
    try {
      final res = await _api.postRequest('projects/$projectId/suggest-edit', {
        'field_name': fieldName,
        'proposed_value': proposedValue,
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return res.body as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('ProjectsService.suggestEdit error: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> suggestProgress({
    required int projectId,
    required int proposedPercent,
    String? name,
    String? email,
    String? reason,
  }) async {
    try {
      final res = await _api.postRequest('projects/$projectId/suggest-progress', {
        'proposed_percent': proposedPercent,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (reason != null) 'reason': reason,
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('ProjectsService.suggestProgress error: $e');
      return false;
    }
  }

  /// Submits a new project directly (`POST /projects`), landing unapproved
  /// pending admin review — the native replacement for the old
  /// in-app-browser redirect to mjengohub.co.ke/projects/submit.
  /// [data] matches the backend's payload schema exactly: `title` required,
  /// `status`/`project_type` are enum strings, `latitude`/`longitude` optional.
  Future<Map<String, dynamic>> submitProject(Map<String, dynamic> data) async {
    try {
      final res = await _api.postRequest('projects', data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = res.body?['data'];
        return {
          'success': true,
          'id': body is Map ? body['id'] : null,
          'message': (body is Map ? body['message'] as String? : null) ??
              'Project submitted for admin review',
        };
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('ProjectsService.submitProject error: $e');
      return {'success': false, 'message': 'Could not submit project. Check your connection.'};
    }
  }

  /// Every project the signed-in user submitted (any type/status, including
  /// still-pending review) — `GET /auth/me/projects`, distinct from the
  /// public `getProjects()` above.
  Future<List<Project>> getMyProjects({int page = 1, int perPage = 20}) async {
    try {
      final res = await _api.getRequest('auth/me/projects', query: {'page': '$page', 'per_page': '$perPage'});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
      }
      return [];
    } catch (e) {
      print('ProjectsService.getMyProjects error: $e');
      return [];
    }
  }

  /// Projects the signed-in user follows — `GET /auth/me/followed-projects`.
  Future<List<Project>> getFollowedProjects({int page = 1, int perPage = 20}) async {
    try {
      final res = await _api.getRequest('auth/me/followed-projects', query: {'page': '$page', 'per_page': '$perPage'});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().map(Project.fromJson).toList();
      }
      return [];
    } catch (e) {
      print('ProjectsService.getFollowedProjects error: $e');
      return [];
    }
  }

  /// Toggles follow state for a project. Returns the new `following` value,
  /// or null on failure (caller should leave UI state unchanged).
  Future<bool?> setFollowing(int projectId, bool follow) async {
    try {
      final res = follow
          ? await _api.postRequest('projects/$projectId/follow', {})
          : await _api.deleteRequest('projects/$projectId/follow');
      if (res.statusCode == 200 && res.body != null) {
        return res.body['data']?['following'] as bool? ?? follow;
      }
      return null;
    } catch (e) {
      print('ProjectsService.setFollowing error: $e');
      return null;
    }
  }

  /// Full project edit — MODERATOR/EDITOR/ADMIN only server-side
  /// (`PUT /projects/{id}`), distinct from the user-facing suggest-edit
  /// review queue above.
  Future<Map<String, dynamic>> updateProject(int projectId, Map<String, dynamic> data) async {
    try {
      final res = await _api.putRequest('projects/$projectId', data);
      if (res.statusCode == 200) {
        return {'success': true, 'data': res.body?['data']};
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('ProjectsService.updateProject error: $e');
      return {'success': false, 'message': 'Could not update project. Check your connection.'};
    }
  }

  /// Toggles is_published — MODERATOR/EDITOR/ADMIN only server-side.
  Future<bool?> togglePublish(int projectId) async {
    try {
      final res = await _api.putRequest('projects/$projectId/publish-toggle', {});
      if (res.statusCode == 200) return res.body?['data']?['is_published'] as bool?;
      return null;
    } catch (e) {
      print('ProjectsService.togglePublish error: $e');
      return null;
    }
  }

  /// Posts a progress update — MODERATOR/EDITOR/ADMIN land auto-approved
  /// (published immediately), everyone else lands in the review queue
  /// (server-enforced, `POST /projects/{id}/updates`). [content] is capped
  /// at 300 words server-side.
  Future<Map<String, dynamic>> postProjectUpdate({
    required int projectId,
    required String content,
    String? externalVideoUrl,
  }) async {
    try {
      final res = await _api.postRequest('projects/$projectId/updates', {
        'content': content,
        if (externalVideoUrl != null && externalVideoUrl.isNotEmpty) 'external_video_url': externalVideoUrl,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': res.body?['message'] as String?};
      }
      return {'success': false, 'message': _errorMessage(res.body)};
    } catch (e) {
      print('ProjectsService.postProjectUpdate error: $e');
      return {'success': false, 'message': 'Could not submit update. Check your connection.'};
    }
  }

  /// Approved progress updates for a project — `GET /projects/{id}/updates`.
  Future<List<ProjectUpdate>> getProjectUpdates(int projectId, {int page = 1, int perPage = 20}) async {
    try {
      final res = await _api.getRequest('projects/$projectId/updates', query: {'page': '$page', 'per_page': '$perPage'});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().map(ProjectUpdate.fromJson).toList();
      }
      return [];
    } catch (e) {
      print('ProjectsService.getProjectUpdates error: $e');
      return [];
    }
  }

  /// Approves a pending update — MODERATOR/EDITOR/ADMIN only server-side.
  Future<bool> approveProjectUpdate(int projectId, int updateId) async {
    try {
      final res = await _api.postRequest('projects/$projectId/updates/$updateId/approve', {});
      return res.statusCode == 200;
    } catch (e) {
      print('ProjectsService.approveProjectUpdate error: $e');
      return false;
    }
  }

  /// Uploads one photo/video to a project — `mediaKind` is 'progress'
  /// (default), 'render' (the dedicated Project Renders picker), or
  /// 'archival' (Built History only). Media compression/EXIF-strip happens
  /// client-side before this is called (see media_pipeline.dart).
  Future<bool> uploadProjectMedia({
    required int projectId,
    required List<int> bytes,
    required String filename,
    String mediaKind = 'progress',
  }) async {
    try {
      final status = await _api.uploadFile(
        'projects/$projectId/media',
        bytes,
        filename,
        fields: {'media_kind': mediaKind},
      );
      return status == 200 || status == 201;
    } catch (e) {
      print('ProjectsService.uploadProjectMedia error: $e');
      return false;
    }
  }

  /// Browse-by-Category / Most-Viewed / By-Status modules for one tracker —
  /// pass exactly one of [projectType], [isBuiltHistory]=true, or
  /// [geoScope]='global', matching `GET /projects/tracker-sections`.
  Future<TrackerSections> getTrackerSections({
    String? projectType,
    bool? isBuiltHistory,
    String? geoScope,
    /// Raises the Most Viewed section's per-window cap above the default 3
    /// — used for that section's "View More" (Category/Status "View More"
    /// use a normal paginated `getProjects` call instead; only Most Viewed
    /// lacks a paginated backend path, see api.py's comment).
    int mostViewedLimit = 3,
  }) async {
    try {
      final query = <String, dynamic>{'most_viewed_limit': '$mostViewedLimit'};
      if (projectType != null) query['project_type'] = projectType;
      if (isBuiltHistory == true) query['is_built_history'] = 'true';
      if (geoScope != null) query['geo_scope'] = geoScope;

      final res = await _api.getRequest('projects/tracker-sections', query: query);
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return TrackerSections.fromJson(data);
      }
      return TrackerSections.empty;
    } catch (e) {
      print('ProjectsService.getTrackerSections error: $e');
      return TrackerSections.empty;
    }
  }

  String _errorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Could not submit project. Please try again.';
  }

  /// Single client with `description` + `project_count` (`full=True`).
  Future<ProjectClientDetail?> getClient(String slug) async {
    try {
      final res = await _api.getRequest('clients/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return ProjectClientDetail.fromJson(data);
      }
      return null;
    } catch (e) {
      print('ProjectsService.getClient error: $e');
      return null;
    }
  }

  /// Milestones for a project, ordered by `milestone_date` ascending.
  /// `GET projects/{slug}` already embeds these, so this is only needed when
  /// refreshing the timeline without refetching the whole project.
  Future<List<ProjectMilestone>> getMilestones(int projectId) async {
    try {
      final res = await _api.getRequest('projects/$projectId/milestones');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ProjectMilestone.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('ProjectsService.getMilestones error: $e');
      return [];
    }
  }

  /// Project gallery, with the backend's own filters. Unlike the media
  /// embedded in `GET projects/{slug}` (capped at 60) this returns everything
  /// matching, so it suits "view all photos" / month-by-month browsing.
  ///
  /// [monthYear] matches the admin's `month_year` label (e.g. '2025-03'),
  /// [mediaType] is 'image' or 'video'.
  Future<List<ProjectMedia>> getProjectMedia(
    int projectId, {
    String? monthYear,
    int? milestoneId,
    String? mediaType,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (monthYear != null && monthYear.isNotEmpty) query['month_year'] = monthYear;
      if (milestoneId != null) query['milestone_id'] = '$milestoneId';
      if (mediaType != null && mediaType.isNotEmpty) query['type'] = mediaType;

      final res = await _api.getRequest(
        'projects/$projectId/media',
        query: query.isEmpty ? null : query,
      );
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ProjectMedia.fromJson)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('ProjectsService.getProjectMedia error: $e');
      return [];
    }
  }
}
