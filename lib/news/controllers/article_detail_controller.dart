// lib/news/controllers/article_detail_controller.dart
import 'package:get/get.dart';
import '../models/article_model.dart';
import '../services/news_api_service.dart';

class ArticleDetailController extends GetxController {
  final _service = NewsApiService();

  final article = Rxn<Article>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  void loadArticle(String slug) {
    if (slug.isEmpty) {
      errorMessage.value = 'Invalid article.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    _service.getArticle(slug).then((a) {
      article.value = a;
      if (a == null) errorMessage.value = 'Article not found.';
    }).catchError((e) {
      errorMessage.value = 'Failed to load article.';
      print('ArticleDetailController error: $e');
    }).whenComplete(() => isLoading.value = false);
  }
}
