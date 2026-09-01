// lib/news/controllers/home_news_controller.dart
import 'package:get/get.dart';
import '../../shared/services/demo_seed_data.dart';
import '../models/article_model.dart';
import '../services/news_api_service.dart';

class HomeNewsController extends GetxController {
  final _service = NewsApiService();

  final featuredArticles = <Article>[].obs;
  final breakingNews = <Article>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final featuredIndex = 0.obs;

  /// True when [featuredArticles]/[breakingNews] were populated from
  /// [demoFeaturedArticles]/[demoBreakingArticles] because the live API
  /// returned nothing (network failure, 401/403 from the host firewall,
  /// etc.) rather than from a real response. Screens must show a visible
  /// "preview" indicator whenever this is true.
  final isShowingDemoData = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    isLoading.value = true;
    errorMessage.value = '';
    isShowingDemoData.value = false;
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
      // The service layer swallows request failures (network error, host
      // firewall 403, etc.) and returns [] rather than throwing, so this is
      // also reached when live data simply never arrived. Fill the feed
      // with clearly-labelled preview content instead of an empty screen.
      if (featuredArticles.isEmpty && breakingNews.isEmpty) {
        featuredArticles.value = demoFeaturedArticles();
        breakingNews.value = demoBreakingArticles();
        isShowingDemoData.value = true;
      }
      isLoading.value = false;
    }
  }

  void onPageChanged(int index) => featuredIndex.value = index;
}
