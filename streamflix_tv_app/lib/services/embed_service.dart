import '../config/api_config.dart';
import 'vidnest_service.dart';

class EmbedProvider {
  final String id;
  final String name;
  final String badge;
  final String description;

  const EmbedProvider({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
  });
}

class EmbedService {
  static const String _vidSrcBaseUrl = 'https://vidsrc.sbs';

  /// Toggle whether to route directly to Vidnest embed or via backend player
  static bool useDirectVidnest = true;

  static const List<EmbedProvider> providers = [
    EmbedProvider(
      id: 'vidnest',
      name: 'Vidnest',
      badge: 'Official',
      description: '9 Fast Server Mirrors with Full HLS Video & Subtitles',
    ),
    EmbedProvider(
      id: 'vidsrc',
      name: 'VidSrc',
      badge: 'Fallback',
      description: 'Movie and TV fallback using TMDB IDs',
    ),
  ];

  static EmbedProvider findProvider(String? id) => providers.firstWhere(
    (provider) => provider.id == id,
    orElse: () => providers.first,
  );

  static String _vidSrcMovieUrl(dynamic tmdbId, int startAt) {
    return Uri.https(
      _vidSrcBaseUrl.replaceFirst('https://', ''),
      '/embed/movie/$tmdbId/',
      {'color': 'e50914', if (startAt > 0) 't': '$startAt'},
    ).toString();
  }

  static String _vidSrcTvUrl(
    dynamic tmdbId,
    int season,
    int episode,
    int startAt,
  ) {
    return Uri.https(
      _vidSrcBaseUrl.replaceFirst('https://', ''),
      '/embed/tv/$tmdbId/$season/$episode/',
      {'color': 'e50914', if (startAt > 0) 't': '$startAt'},
    ).toString();
  }

  static String getMovieUrl(
    dynamic tmdbId, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    if (provider == 'vidsrc') {
      return _vidSrcMovieUrl(tmdbId, startAt);
    }
    if (useDirectVidnest) {
      return VidnestService.buildMovieUrl(
        tmdbId: tmdbId,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.movieEmbed(tmdbId, server: server, startAt: startAt);
  }

  static String getTvUrl(
    dynamic tmdbId,
    int season,
    int episode, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    if (provider == 'vidsrc') {
      return _vidSrcTvUrl(tmdbId, season, episode, startAt);
    }
    if (useDirectVidnest) {
      return VidnestService.buildTvUrl(
        tmdbId: tmdbId,
        season: season,
        episode: episode,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.tvEmbed(
      tmdbId,
      season,
      episode,
      server: server,
      startAt: startAt,
    );
  }

  static String getAnimeUrl(
    dynamic id,
    int season,
    int episode, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    if (useDirectVidnest) {
      return VidnestService.buildAnimeUrl(
        animeId: id,
        episode: episode,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.animeEmbed(
      id,
      season,
      episode,
      server: server,
      startAt: startAt,
    );
  }
}
