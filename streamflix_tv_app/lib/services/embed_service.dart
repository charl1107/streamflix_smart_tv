import '../config/api_config.dart';

class EmbedService {
  static String getMovieUrl(dynamic tmdbId) {
    return ApiConfig.movieEmbed(tmdbId);
  }

  static String getTvUrl(dynamic tmdbId, int season, int episode) {
    return ApiConfig.tvEmbed(tmdbId, season, episode);
  }

  static String getAnimeUrl(dynamic id, int season, int episode) {
    return ApiConfig.animeEmbed(id, season, episode);
  }
}
