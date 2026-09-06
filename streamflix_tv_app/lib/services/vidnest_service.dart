/// Server definition for Vidnest streaming
class VidnestServer {
  final String id;
  final String name;
  final String description;
  final String badge;

  const VidnestServer({
    required this.id,
    required this.name,
    required this.description,
    this.badge = 'HD',
  });
}

/// Official Vidnest Embed API Service
/// Exclusively handles Vidnest embeds for Movies, TV Shows, Anime, and AnimePahe
class VidnestService {
  static const String baseUrl = 'https://vidnest.fun';

  /// Supported Vidnest servers as per API documentation
  static const List<VidnestServer> servers = [
    VidnestServer(id: 'lamda', name: 'Lamda', description: 'Primary High-Speed CDN', badge: 'Fast'),
    VidnestServer(id: 'primesrc', name: 'PrimeSrc', description: 'Multi-Bitrate Stream', badge: '1080p'),
    VidnestServer(id: 'gama', name: 'Gama', description: 'Ultra-Low Latency', badge: 'HD'),
    VidnestServer(id: 'alfa', name: 'Alfa', description: 'Global Edge Mirror', badge: 'Stable'),
    VidnestServer(id: 'beta', name: 'Beta', description: 'High Compatibility', badge: 'HD'),
    VidnestServer(id: 'sigma', name: 'Sigma', description: 'Multi-Source Backup', badge: 'Mirror'),
    VidnestServer(id: 'catflix', name: 'Catflix', description: 'Fast Content Stream', badge: 'Fast'),
    VidnestServer(id: 'hexa', name: 'Hexa', description: 'Alternative Server 1', badge: 'HD'),
    VidnestServer(id: 'delta', name: 'Delta', description: 'Alternative Server 2', badge: 'Backup'),
  ];

  static VidnestServer defaultServer = servers[0];

  /// Builds a Vidnest embed URL for movies:
  /// https://vidnest.fun/movie/[TMDB_ID]
  static String buildMovieUrl({
    required dynamic tmdbId,
    String? server,
    int startAt = 0,
    Map<String, dynamic>? hideControls,
  }) {
    final serverParam = server ?? defaultServer.id;
    final queryParams = <String>['server=$serverParam'];
    if (startAt > 0) {
      queryParams.add('startAt=$startAt');
    }
    if (hideControls != null) {
      hideControls.forEach((key, value) {
        queryParams.add('$key=$value');
      });
    }
    return '$baseUrl/movie/$tmdbId?${queryParams.join('&')}';
  }

  /// Builds a Vidnest embed URL for TV shows:
  /// https://vidnest.fun/tv/[TMDB_ID]/[SEASON]/[EPISODE]
  static String buildTvUrl({
    required dynamic tmdbId,
    required int season,
    required int episode,
    String? server,
    int startAt = 0,
    Map<String, dynamic>? hideControls,
  }) {
    final serverParam = server ?? defaultServer.id;
    final queryParams = <String>['server=$serverParam'];
    if (startAt > 0) {
      queryParams.add('startAt=$startAt');
    }
    if (hideControls != null) {
      hideControls.forEach((key, value) {
        queryParams.add('$key=$value');
      });
    }
    return '$baseUrl/tv/$tmdbId/$season/$episode?${queryParams.join('&')}';
  }

  /// Builds a Vidnest embed URL for Anime:
  /// https://vidnest.fun/anime/[ANIME_ID]/[EPISODE]/[SUB_OR_DUB]
  static String buildAnimeUrl({
    required dynamic animeId,
    required int episode,
    String subOrDub = 'sub',
    String? server,
    int startAt = 0,
    Map<String, dynamic>? hideControls,
  }) {
    final serverParam = server ?? defaultServer.id;
    final queryParams = <String>['server=$serverParam'];
    if (startAt > 0) {
      queryParams.add('startAt=$startAt');
    }
    if (hideControls != null) {
      hideControls.forEach((key, value) {
        queryParams.add('$key=$value');
      });
    }
    return '$baseUrl/anime/$animeId/$episode/$subOrDub?${queryParams.join('&')}';
  }

  /// Builds a Vidnest embed URL for AnimePahe:
  /// https://vidnest.fun/animepahe/[ANIME_ID]/[EPISODE]/[SUB_OR_DUB]
  static String buildAnimePaheUrl({
    required dynamic animeId,
    required int episode,
    String subOrDub = 'sub',
    String? server,
    int startAt = 0,
    Map<String, dynamic>? hideControls,
  }) {
    final serverParam = server ?? defaultServer.id;
    final queryParams = <String>['server=$serverParam'];
    if (startAt > 0) {
      queryParams.add('startAt=$startAt');
    }
    if (hideControls != null) {
      hideControls.forEach((key, value) {
        queryParams.add('$key=$value');
      });
    }
    return '$baseUrl/animepahe/$animeId/$episode/$subOrDub?${queryParams.join('&')}';
  }

  /// Generates the standard HTML <iframe> code snippet per documentation:
  /// <iframe src="..." frameBorder="0" scrolling="no" allowFullScreen></iframe>
  static String buildIframeCode(String embedUrl) {
    return '<iframe src="$embedUrl" frameBorder="0" scrolling="no" allowFullScreen></iframe>';
  }

  /// Finds a server by its id
  static VidnestServer findServer(String id) {
    return servers.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => defaultServer,
    );
  }
}
