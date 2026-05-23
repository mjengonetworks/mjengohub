// lib/videos/controllers/videos_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/video_model.dart';
import '../services/video_api_service.dart';

class VideosController extends GetxController {
  final _service = VideoApiService();

  // ── Observable state ────────────────────────────────────────────────────────
  final videos         = <Video>[].obs;
  final featuredVideos = <Video>[].obs;
  final playlists      = <VideoPlaylist>[].obs;
  final categories     = <VideoCategory>[].obs;

  final isLoading     = true.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;
  final errorMessage  = ''.obs;

  // ── Filters ─────────────────────────────────────────────────────────────────
  final selectedCategoryId = Rxn<int>();
  final selectedPlaylistId = RxnString();

  // ── Search ──────────────────────────────────────────────────────────────────
  final searchController = TextEditingController();
  String _searchQuery = '';

  // ── Pagination ───────────────────────────────────────────────────────────────
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _initialLoad();
    ever(selectedCategoryId, (_) => _resetAndFetch());
    ever(selectedPlaylistId,  (_) => _resetAndFetch());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  @override
  Future<void> refresh() => _initialLoad();

  void selectCategory(int? id) {
    selectedCategoryId.value = (selectedCategoryId.value == id) ? null : id;
    selectedPlaylistId.value = null;
  }

  void selectPlaylist(String? id) {
    selectedPlaylistId.value = (selectedPlaylistId.value == id) ? null : id;
    selectedCategoryId.value = null;
  }

  void onSearchSubmit(String q) {
    _searchQuery = q.trim();
    _resetAndFetch();
  }

  void clearSearch() {
    searchController.clear();
    _searchQuery = '';
    _resetAndFetch();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final more = await _service.getVideos(
        page:       _page + 1,
        categoryId: selectedCategoryId.value,
        playlistId: selectedPlaylistId.value,
        q:          _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (more.isEmpty) {
        hasMore.value = false;
      } else {
        _page++;
        videos.addAll(more);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<void> _initialLoad() async {
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _service.getVideos(featuredOnly: true, perPage: 5),
        _service.getVideos(perPage: 20),
        _service.getPlaylists(),
        _service.getCategories(),
      ]);
      featuredVideos.value = results[0] as List<Video>;
      videos.value         = results[1] as List<Video>;
      playlists.value      = results[2] as List<VideoPlaylist>;
      categories.value     = results[3] as List<VideoCategory>;
      _page     = 1;
      hasMore.value = (results[1] as List<Video>).length >= 20;
    } catch (e) {
      errorMessage.value = 'Failed to load videos. Pull to refresh.';
      print('VideosController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _resetAndFetch() async {
    _page = 1;
    hasMore.value   = true;
    isLoading.value = true;
    try {
      final fresh = await _service.getVideos(
        page:       1,
        categoryId: selectedCategoryId.value,
        playlistId: selectedPlaylistId.value,
        q:          _searchQuery.isEmpty ? null : _searchQuery,
      );
      videos.value  = fresh;
      hasMore.value = fresh.length >= 20;
    } finally {
      isLoading.value = false;
    }
  }
}
