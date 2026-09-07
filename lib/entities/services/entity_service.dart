// lib/entities/services/entity_service.dart
//
// Wraps `GET entities/{slug}` — see EntityModel for the verified payload
// shape. Follows the house pattern: try/catch, return null on any failure
// (including the 404 a guessed slug commonly returns today) so screens only
// need a null check.
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/entity_model.dart';

class EntityService {
  BaseService get _api => Get.find<BaseService>();

  Future<EntityModel?> fetchEntity(String slug) async {
    if (slug.isEmpty) return null;
    try {
      final res = await _api.getRequest('entities/$slug');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is Map<String, dynamic>) return EntityModel.fromJson(data);
      }
    } catch (e) {
      print('❌ fetchEntity($slug) failed: $e');
    }
    return null;
  }
}
