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

class VidnestService {
  static const String baseUrl = 'https://vidnest.fun';

  /// Supported Vidnest servers
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

  /// Builds a Vidnest embed URL for movies
  static String buildMovieUrl({
    required dynamic tmdbId,
    String? server,
    int startAt = 0,
    bool hideBuiltinControls = false,
  }) {
    final serverParam = server ?? defaultServer.id;
    final buffer = StringBuffer('$baseUrl/movie/$tmdbId?server=$serverParam');
    if (startAt > 0) {
      buffer.write('&startAt=$startAt');
    }
    if (hideBuiltinControls) {
      buffer.write('&servericon=hide');
    }
    return buffer.toString();
  }

  /// Builds a Vidnest embed URL for TV shows
  static String buildTvUrl({
    required dynamic tmdbId,
    required int season,
    required int episode,
    String? server,
    int startAt = 0,
    bool hideBuiltinControls = false,
  }) {
    final serverParam = server ?? defaultServer.id;
    final buffer = StringBuffer('$baseUrl/tv/$tmdbId/$season/$episode?server=$serverParam');
    if (startAt > 0) {
      buffer.write('&startAt=$startAt');
    }
    if (hideBuiltinControls) {
      buffer.write('&servericon=hide');
    }
    return buffer.toString();
  }

  /// Builds a Vidnest embed URL for Anime
  static String buildAnimeUrl({
    required dynamic anilistId,
    required int episode,
    String subOrDub = 'sub',
    String? server,
    int startAt = 0,
  }) {
    final buffer = StringBuffer('$baseUrl/anime/$anilistId/$episode/$subOrDub');
    final queryParams = <String>[];
    if (server != null && server.isNotEmpty) {
      queryParams.add('server=$server');
    }
    if (startAt > 0) {
      queryParams.add('startAt=$startAt');
    }
    if (queryParams.isNotEmpty) {
      buffer.write('?${queryParams.join('&')}');
    }
    return buffer.toString();
  }

  /// Finds a server by its id
  static VidnestServer findServer(String id) {
    return servers.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => defaultServer,
    );
  }
}
