// lib/news/controllers/discover_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/article_model.dart';
import '../models/category_model.dart';
import '../services/news_api_service.dart';

class DiscoverController extends GetxController {
  final _service = NewsApiService();

  final categories = <Category>[].obs;
  final articles = <Article>[].obs;
  final selectedSlug = ''.obs;      // '' means "All"
  final isLoadingCats = false.obs;
  final isLoadingArticles = false.obs;
  final hasMore = true.obs;
  final searchController = TextEditingController();

  int _page = 1;
  String _searchQuery = '';

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _loadAll() async {
    await Future.wait([fetchCategories(), fetchArticles(reset: true)]);
  }

  Future<void> fetchCategories() async {
    isLoadingCats.value = true;
    categories.value = await _service.getCategories();
    isLoadingCats.value = false;
  }

  void selectCategory(String slug) {
    if (selectedSlug.value == slug) return;
    selectedSlug.value = slug;
    fetchArticles(reset: true);
  }

  void onSearchSubmit(String q) {
    _searchQuery = q.trim();
    fetchArticles(reset: true);
  }

  void clearSearch() {
    searchController.clear();
    _searchQuery = '';
    fetchArticles(reset: true);
  }

  Future<void> fetchArticles({bool reset = false}) async {
    if (reset) {
      _page = 1;
      articles.clear();
      hasMore.value = true;
    }
    if (!hasMore.value || isLoadingArticles.value) return;

    isLoadingArticles.value = true;
    final result = await _service.getArticles(
      categorySlug: selectedSlug.value.isEmpty ? null : selectedSlug.value,
      q: _searchQuery.isEmpty ? null : _searchQuery,
      page: _page,
    );
    if (result.isEmpty) {
      hasMore.value = false;
    } else {
      articles.addAll(result);
      _page++;
    }
    isLoadingArticles.value = false;
  }

  Future<void> refresh() => _loadAll();
}
