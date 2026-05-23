// lib/news/controllers/home_news_controller.dart
import 'package:get/get.dart';
import '../models/article_model.dart';
import '../services/news_api_service.dart';

class HomeNewsController extends GetxController {
  final _service = NewsApiService();

  final featuredArticles = <Article>[].obs;
  final breakingNews = <Article>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final featuredIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _service.getFeaturedArticles(perPage: 5),
        _service.getBreakingNews(perPage: 10),
      ]);
      featuredArticles.value = results[0];
      breakingNews.value = results[1];

      // Fallback: if no featured, use latest articles as featured hero
      if (featuredArticles.isEmpty) {
        final latest = await _service.getArticles(perPage: 5);
        featuredArticles.value = latest;
      }
    } catch (e) {
      errorMessage.value = 'Failed to load news. Pull to refresh.';
      print('HomeNewsController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onPageChanged(int index) => featuredIndex.value = index;
}
