class ApiConfig {
  // Backend base URL - deployed Cloudflare Worker
  static const String backendBaseUrl = 'https://streamflix-tv-backend.dominicmariano140.workers.dev/api';
  static const String appSecret = String.fromEnvironment('APP_SECRET', defaultValue: '');
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  // AniList OAuth / API Credentials (Passed securely via --dart-define or .env, never exposed on push)
  static const String anilistClientId = String.fromEnvironment('ANILIST_CLIENT_ID', defaultValue: '50147');
  static const String anilistClientSecret = String.fromEnvironment('ANILIST_CLIENT_SECRET', defaultValue: '');
  static const String anilistRedirectUrl = String.fromEnvironment('ANILIST_REDIRECT_URL', defaultValue: 'https://cineko-frontend.vercel.app');

  // Embed URLs routed through backend player proxy or multi-source embed
  static String movieEmbed(dynamic tmdbId, {String? server, int startAt = 0}) {
    final buffer = StringBuffer('$backendBaseUrl/player?type=movie&id=$tmdbId');
    if (server != null && server.isNotEmpty) buffer.write('&server=$server');
    if (startAt > 0) buffer.write('&startAt=$startAt');
    return buffer.toString();
  }

  static String tvEmbed(dynamic tmdbId, int season, int episode, {String? server, int startAt = 0}) {
    final buffer = StringBuffer('$backendBaseUrl/player?type=tv&id=$tmdbId&s=$season&e=$episode');
    if (server != null && server.isNotEmpty) buffer.write('&server=$server');
    if (startAt > 0) buffer.write('&startAt=$startAt');
    return buffer.toString();
  }

  static String animeEmbed(dynamic id, int season, int episode, {String? server, int startAt = 0}) {
    final buffer = StringBuffer('$backendBaseUrl/player?type=anime&id=$id&s=$season&e=$episode');
    if (server != null && server.isNotEmpty) buffer.write('&server=$server');
    if (startAt > 0) buffer.write('&startAt=$startAt');
    return buffer.toString();
  }

  // Vidnest embed API endpoints. The backend returns an official Vidnest URL
  // and supports the documented server, startAt/progress, and control params.
  static String embedServers() => '$backendBaseUrl/embed/servers';
  static String embedEndpoint(
    String type,
    dynamic id, {
    int season = 1,
    int episode = 1,
    String server = 'lamda',
    int startAt = 0,
    String subOrDub = 'sub',
    bool animePahe = false,
  }) {
    final params = <String, String>{
      'season': '$season',
      'episode': '$episode',
      'server': server,
      'sub': subOrDub,
    };
    if (startAt > 0) params['startAt'] = '$startAt';
    if (animePahe) params['source'] = 'animepahe';
    return Uri.parse('$backendBaseUrl/embed/$type/$id')
        .replace(queryParameters: params)
        .toString();
  }

  // JSON streams endpoint for native player
  static String movieStreams(dynamic tmdbId) => '$backendBaseUrl/streams?type=movie&id=$tmdbId';
  static String tvStreams(dynamic tmdbId, int season, int episode) => '$backendBaseUrl/streams?type=tv&id=$tmdbId&s=$season&e=$episode';
  static String animeStreams(dynamic id, int season, int episode) => '$backendBaseUrl/streams?type=anime&id=$id&s=$season&e=$episode';

  // Subtitle tracks endpoint
  static String subtitles(String m3u8Url, {String referer = '', String origin = ''}) {
    return '$backendBaseUrl/subtitles?url=${Uri.encodeComponent(m3u8Url)}&referer=${Uri.encodeComponent(referer)}&origin=${Uri.encodeComponent(origin)}';
  }

  // Image helpers
  static String posterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }

  static String backdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }
}
