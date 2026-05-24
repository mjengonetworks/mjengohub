// lib/mental_health/controllers/mental_health_controller.dart
import 'package:get/get.dart';
import '../models/mental_health_model.dart';
import '../services/mental_health_service.dart';

class MentalHealthController extends GetxController {
  final _service = MentalHealthService();

  final posts = <MentalHealthPost>[].obs;
  final videos = <MentalHealthVideo>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final submitting = false.obs;
  final submitted = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    final results = await Future.wait([
      _service.getPosts(),
      _service.getVideos(),
    ]);
    posts.value = results[0] as List<MentalHealthPost>;
    videos.value = results[1] as List<MentalHealthVideo>;
    isLoading.value = false;
  }

  Future<void> submitPost({
    required String message,
    String? authorName,
    bool isAnonymous = true,
  }) async {
    if (message.trim().length < 10) {
      Get.snackbar(
        'Too short',
        'Please write at least 10 characters.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    submitting.value = true;
    final ok = await _service.submitPost(
      message: message.trim(),
      authorName: isAnonymous ? 'Anonymous' : authorName,
      isAnonymous: isAnonymous,
    );
    submitting.value = false;
    if (ok) {
      submitted.value = true;
      Get.snackbar(
        'Message submitted',
        'Your message is pending review and will appear on the wall once approved.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Error',
        'Could not submit message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
