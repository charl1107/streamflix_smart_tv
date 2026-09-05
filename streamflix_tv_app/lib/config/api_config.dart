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
  static String movieEmbed(dynamic tmdbId) => '$backendBaseUrl/player?type=movie&id=$tmdbId';
  static String tvEmbed(dynamic tmdbId, int season, int episode) => '$backendBaseUrl/player?type=tv&id=$tmdbId&s=$season&e=$episode';
  static String animeEmbed(dynamic id, int season, int episode) => '$backendBaseUrl/player?type=anime&id=$id&s=$season&e=$episode';

  // Multi-provider Embed API endpoint
  static String embedSources() => '$backendBaseUrl/embed/sources';
  static String embedEndpoint(String type, dynamic id, {int season = 1, int episode = 1, String provider = 'vidnest', String server = 'lamda'}) {
    return '$backendBaseUrl/embed/$type/$id?season=$season&episode=$episode&provider=$provider&server=$server';
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
