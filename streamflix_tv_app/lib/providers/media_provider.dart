import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../models/genre.dart';
import '../services/tmdb_service.dart';

class MediaProvider extends ChangeNotifier {
  final TmdbService _tmdbService = TmdbService();

  List<MediaItem> trendingMovies = [];
  List<MediaItem> trendingTv = [];
  List<MediaItem> popularMovies = [];
  List<MediaItem> popularTv = [];
  List<MediaItem> topRatedMovies = [];
  List<MediaItem> topRatedTv = [];

  List<Genre> movieGenres = [];
  List<Genre> tvGenres = [];

  List<MediaItem> genreFilteredMovies = [];
  List<MediaItem> genreFilteredShows = [];

  bool isHomeLoading = true;
  bool isMoviesLoading = true;
  bool isShowsLoading = true;
  bool isFiltering = false;

  // Compatibility aliases
  List<MediaItem> get trendingShows => trendingTv;
  List<MediaItem> get popularShows => popularTv;
  List<MediaItem> get topRatedShows => topRatedTv;
  List<Genre> get showGenres => tvGenres;
  bool get isLoading => isHomeLoading || isMoviesLoading || isShowsLoading;

  Future<void> loadHome() async {
    isHomeLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _tmdbService.getTrending(type: 'movie'),
        _tmdbService.getTrending(type: 'tv'),
        _tmdbService.getDiscover(type: 'tv', sortBy: 'popularity.desc'),
        _tmdbService.getDiscover(type: 'movie', sortBy: 'vote_average.desc'),
      ]);

      trendingMovies = futures[0] as List<MediaItem>;
      trendingTv = futures[1] as List<MediaItem>;
      popularTv = (futures[2] as Map<String, dynamic>)['results'] ?? [];
      topRatedMovies = (futures[3] as Map<String, dynamic>)['results'] ?? [];
    } catch (e) {
      debugPrint('[MediaProvider] Error loading home: $e');
    } finally {
      isHomeLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMovies() async {
    isMoviesLoading = true;
    notifyListeners();

    try {
      final discoverFutures = await Future.wait([
        _tmdbService.getTrending(type: 'movie'),
        _tmdbService.getDiscover(type: 'movie', sortBy: 'popularity.desc'),
        _tmdbService.getDiscover(type: 'movie', sortBy: 'vote_average.desc'),
      ]);

      trendingMovies = discoverFutures[0] as List<MediaItem>;
      popularMovies = (discoverFutures[1] as Map<String, dynamic>)['results'] ?? [];
      topRatedMovies = (discoverFutures[2] as Map<String, dynamic>)['results'] ?? [];

      if (movieGenres.isEmpty) {
        movieGenres = await _tmdbService.getGenres(type: 'movie');
      }
    } catch (e) {
      debugPrint('[MediaProvider] Error loading movies: $e');
    } finally {
      isMoviesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoviesByGenre(int genreId) async {
    isFiltering = true;
    notifyListeners();

    try {
      final res = await _tmdbService.getDiscover(type: 'movie', genre: genreId);
      genreFilteredMovies = res['results'] ?? [];
    } catch (e) {
      genreFilteredMovies = [];
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }

  Future<void> loadShows() async {
    isShowsLoading = true;
    notifyListeners();

    try {
      final discoverFutures = await Future.wait([
        _tmdbService.getTrending(type: 'tv'),
        _tmdbService.getDiscover(type: 'tv', sortBy: 'popularity.desc'),
        _tmdbService.getDiscover(type: 'tv', sortBy: 'vote_average.desc'),
      ]);

      trendingTv = discoverFutures[0] as List<MediaItem>;
      popularTv = (discoverFutures[1] as Map<String, dynamic>)['results'] ?? [];
      topRatedTv = (discoverFutures[2] as Map<String, dynamic>)['results'] ?? [];

      if (tvGenres.isEmpty) {
        tvGenres = await _tmdbService.getGenres(type: 'tv');
      }
    } catch (e) {
      debugPrint('[MediaProvider] Error loading shows: $e');
    } finally {
      isShowsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShowsByGenre(int genreId) async {
    isFiltering = true;
    notifyListeners();

    try {
      final res = await _tmdbService.getDiscover(type: 'tv', genre: genreId);
      genreFilteredShows = res['results'] ?? [];
    } catch (e) {
      genreFilteredShows = [];
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }
}
