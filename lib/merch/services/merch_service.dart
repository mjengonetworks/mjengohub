// lib/merch/services/merch_service.dart
import 'package:get/get.dart';

import '../../services/base_service.dart';
import '../models/merch_model.dart';

class MerchService {
  BaseService get _api => Get.find<BaseService>();

  Future<List<MerchProduct>> getProducts() async {
    try {
      final res = await _api.getRequest('merch/products');
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().map(MerchProduct.fromJson).toList();
      }
      return [];
    } catch (e) {
      print('MerchService.getProducts error: $e');
      return [];
    }
  }

  Future<List<MerchShoutout>> getShoutouts({int limit = 20}) async {
    try {
      final res = await _api.getRequest('merch/shoutouts', query: {'limit': '$limit'});
      if (res.statusCode == 200 && res.body != null) {
        final data = res.body['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().map(MerchShoutout.fromJson).toList();
      }
      return [];
    } catch (e) {
      print('MerchService.getShoutouts error: $e');
      return [];
    }
  }
}
