class ApiConfig {
  // Backend base URL - deployed Cloudflare Worker
  static const String backendBaseUrl = 'https://streamflix-tv-backend.dominicmariano140.workers.dev/api';
  static const String appSecret = 'streamflix_tv_sec_7f9a2e8c1b';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  // Embed URLs routed through backend player proxy
  static String movieEmbed(dynamic tmdbId) => '$backendBaseUrl/player?type=movie&id=$tmdbId';
  static String tvEmbed(dynamic tmdbId, int season, int episode) => '$backendBaseUrl/player?type=tv&id=$tmdbId&s=$season&e=$episode';
  static String animeEmbed(dynamic id, int season, int episode) => '$backendBaseUrl/player?type=anime&id=$id&s=$season&e=$episode';

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
