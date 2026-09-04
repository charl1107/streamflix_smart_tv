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
  /// Toggle whether to route directly to embed providers or via backend player
  static bool useDirectVidnest = true;

  static const List<EmbedProvider> providers = [
    EmbedProvider(
      id: 'vidnest',
      name: 'Vidnest',
      badge: 'Recommended',
      description: '9 Fast Server Mirrors with Full HLS Support',
    ),
    EmbedProvider(
      id: 'zoryva',
      name: 'Zoryva',
      badge: 'Fast',
      description: 'Ultra-Fast Direct CDN Embed',
    ),
    EmbedProvider(
      id: 'vidsrc',
      name: 'VidSrc',
      badge: 'HD',
      description: 'High Definition Multi-Source Mirror',
    ),
    EmbedProvider(
      id: 'autoembed',
      name: 'AutoEmbed',
      badge: 'Multi',
      description: 'Automated Stream Switcher & Redundancy',
    ),
    EmbedProvider(
      id: '2embed',
      name: '2Embed',
      badge: 'Backup',
      description: 'Alternative Global Backup Player',
    ),
  ];

  static EmbedProvider findProvider(String? id) {
    if (id == null || id.isEmpty) return providers.first;
    return providers.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => providers.first,
    );
  }

  static String getMovieUrl(
    dynamic tmdbId, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    final cleanProvider = provider.toLowerCase();
    if (cleanProvider == 'zoryva') {
      return 'https://zoryva.me/embedded/movie/$tmdbId';
    } else if (cleanProvider == 'vidsrc') {
      return 'https://vidsrc.mov/embed/movie/$tmdbId';
    } else if (cleanProvider == 'autoembed') {
      return 'https://player.autoembed.cc/embed/movie/$tmdbId';
    } else if (cleanProvider == '2embed') {
      return 'https://www.2embed.cc/embed/$tmdbId';
    }

    if (useDirectVidnest) {
      return VidnestService.buildMovieUrl(
        tmdbId: tmdbId,
        server: server,
        startAt: startAt,
      );
    }
    return ApiConfig.movieEmbed(tmdbId);
  }

  static String getTvUrl(
    dynamic tmdbId,
    int season,
    int episode, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    final cleanProvider = provider.toLowerCase();
    if (cleanProvider == 'zoryva') {
      return 'https://zoryva.me/embedded/tv/$tmdbId/$season/$episode';
    } else if (cleanProvider == 'vidsrc') {
      return 'https://vidsrc.mov/embed/tv/$tmdbId/$season/$episode';
    } else if (cleanProvider == 'autoembed') {
      return 'https://player.autoembed.cc/embed/tv/$tmdbId/$season/$episode';
    } else if (cleanProvider == '2embed') {
      return 'https://www.2embed.cc/embedtv/$tmdbId&s=$season&e=$episode';
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
    return ApiConfig.tvEmbed(tmdbId, season, episode);
  }

  static String getAnimeUrl(
    dynamic id,
    int season,
    int episode, {
    String provider = 'vidnest',
    String? server,
    int startAt = 0,
  }) {
    final cleanProvider = provider.toLowerCase();
    if (cleanProvider == 'zoryva') {
      return 'https://zoryva.me/embedded/tv/$id/$season/$episode';
    } else if (cleanProvider == 'vidsrc') {
      return 'https://vidsrc.mov/embed/tv/$id/$season/$episode';
    } else if (cleanProvider == 'autoembed') {
      return 'https://player.autoembed.cc/embed/tv/$id/$season/$episode';
    } else if (cleanProvider == '2embed') {
      return 'https://www.2embed.cc/embedtv/$id&s=$season&e=$episode';
    }

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
