import '../models/media_item.dart';
import '../models/genre.dart';
import '../models/season_episode.dart';
import 'api_service.dart';

class TmdbService {
  final ApiService _api = ApiService();

  Future<List<MediaItem>> getTrending({String type = 'movie', String window = 'week'}) async {
    final data = await _api.get('/trending', queryParameters: {
      'type': type,
      'window': window,
    });
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => MediaItem.fromTmdbJson(Map<String, dynamic>.from(json), defaultMediaType: type)).toList();
  }

  Future<Map<String, dynamic>> getDiscover({String type = 'movie', String sortBy = 'popularity.desc', int? genre, int page = 1}) async {
    final queryParams = <String, dynamic>{
      'type': type,
      'sort_by': sortBy,
      'page': page,
    };
    if (genre != null) {
      queryParams['genre'] = genre;
    }
    final data = await _api.get('/discover', queryParameters: queryParams);
    final results = data['results'] as List<dynamic>? ?? [];
    return {
      'results': results.map((json) => MediaItem.fromTmdbJson(Map<String, dynamic>.from(json), defaultMediaType: type)).toList(),
      'totalPages': data['total_pages'] ?? 1,
    };
  }

  Future<List<MediaItem>> search(String query, {String type = 'multi', int page = 1}) async {
    final data = await _api.get('/search', queryParameters: {'q': query, 'type': type, 'page': page});
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => MediaItem.fromTmdbJson(Map<String, dynamic>.from(json), defaultMediaType: type)).toList();
  }

  Future<MediaItem> getMovieDetails(int id) async {
    final data = await _api.get('/movie/$id', queryParameters: {'append_to_response': 'credits,recommendations,videos'});
    return MediaItem.fromTmdbJson(Map<String, dynamic>.from(data), defaultMediaType: 'movie');
  }

  Future<MediaItem> getTvDetails(int id) async {
    final data = await _api.get('/tv/$id', queryParameters: {'append_to_response': 'credits,recommendations,videos'});
    return MediaItem.fromTmdbJson(Map<String, dynamic>.from(data), defaultMediaType: 'tv');
  }

  Future<List<Episode>> getTvSeason(int seriesId, int seasonNumber) async {
    final data = await _api.get('/tv/$seriesId/season/$seasonNumber');
    final episodes = data['episodes'] as List<dynamic>? ?? [];
    return episodes.map((json) => Episode.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<List<Genre>> getGenres({String type = 'movie'}) async {
    final data = await _api.get('/genres', queryParameters: {'type': type});
    final genres = data['genres'] as List<dynamic>? ?? [];
    return genres.map((json) => Genre.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
