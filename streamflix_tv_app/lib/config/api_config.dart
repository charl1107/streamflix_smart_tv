class ApiConfig {
  // Backend base URL - deployed Cloudflare Worker
  static const String backendBaseUrl = 'https://streamflix-tv-backend.dominicmariano140.workers.dev/api';
  static const String appSecret = String.fromEnvironment('APP_SECRET', defaultValue: '');
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

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

  // Subtitle tracks endpoint
  static String subtitles(String m3u8Url, {String referer = '', String origin = ''}) {
    return '$backendBaseUrl/subtitles?url=${Uri.encodeComponent(m3u8Url)}&referer=${Uri.encodeComponent(referer)}&origin=${Uri.encodeComponent(origin)}';
  }

  // Image helpers
  static String posterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('https://cdn.anipixcdn.co/')) {
      return '$backendBaseUrl/anime/image?url=${Uri.encodeComponent(path)}';
    }
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }

  static String backdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('https://cdn.anipixcdn.co/')) {
      return '$backendBaseUrl/anime/image?url=${Uri.encodeComponent(path)}';
    }
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }
}
