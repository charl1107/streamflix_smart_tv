import '../config/api_config.dart';
import 'vidnest_service.dart';

class EmbedService {
  /// Toggle whether to route directly to Vidnest embed or via backend player
  static bool useDirectVidnest = true;

  static String getMovieUrl(dynamic tmdbId, {String? server, int startAt = 0}) {
    if (useDirectVidnest) {
      return VidnestService.buildMovieUrl(
        tmdbId: tmdbId,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.movieEmbed(tmdbId);
  }

  static String getTvUrl(dynamic tmdbId, int season, int episode, {String? server, int startAt = 0}) {
    if (useDirectVidnest) {
      return VidnestService.buildTvUrl(
        tmdbId: tmdbId,
        season: season,
        episode: episode,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.tvEmbed(tmdbId, season, episode);
  }

  static String getAnimeUrl(dynamic id, int season, int episode, {String? server, int startAt = 0}) {
    if (useDirectVidnest) {
      return VidnestService.buildAnimeUrl(
        anilistId: id,
        episode: episode,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.animeEmbed(id, season, episode);
  }
}
