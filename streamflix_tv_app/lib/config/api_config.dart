class ApiConfig {
  // Backend base URL - deployed Cloudflare Worker
  static const String backendBaseUrl = 'https://streamflix-tv-backend.dominicmariano140.workers.dev/api';
  static const String appSecret = 'streamflix_tv_sec_7f9a2e8c1b';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  // Embed URLs routed through backend player proxy
  static String movieEmbed(dynamic tmdbId) => '$backendBaseUrl/player?type=movie&id=$tmdbId';
  static String tvEmbed(dynamic tmdbId, int season, int episode) => '$backendBaseUrl/player?type=tv&id=$tmdbId&s=$season&e=$episode';
  static String animeEmbed(dynamic id, int season, int episode) => '$backendBaseUrl/player?type=anime&id=$id&s=$season&e=$episode';

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
