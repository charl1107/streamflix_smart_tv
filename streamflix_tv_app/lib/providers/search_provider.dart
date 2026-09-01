import 'dart:async';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';

class SearchProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();

  String query = '';
  List<MediaItem> results = [];
  bool isLoading = false;
  Timer? _debounceTimer;

  List<MediaItem> get searchResults => results;

  void search(String newQuery) {
    query = newQuery.trim();
    
    if (query.isEmpty) {
      clear();
      return;
    }

    isLoading = true;
    notifyListeners();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final tmdbResults = await _tmdbService.search(query);
        results = tmdbResults.where((item) => item.posterPath != null && item.posterPath!.isNotEmpty).toList();
      } catch (e) {
        debugPrint('[SearchProvider] Error searching: $e');
        results = [];
      } finally {
        isLoading = false;
        notifyListeners();
      }
    });
  }

  void searchImmediate(String newQuery) async {
    query = newQuery.trim();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.isEmpty) {
      clear();
      return;
    }
    isLoading = true;
    notifyListeners();
    try {
      final tmdbResults = await _tmdbService.search(query);
      results = tmdbResults.where((item) => item.posterPath != null && item.posterPath!.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[SearchProvider] Error searching: $e');
      results = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    query = '';
    results = [];
    isLoading = false;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    notifyListeners();
  }

  void clearSearch() => clear();
}
