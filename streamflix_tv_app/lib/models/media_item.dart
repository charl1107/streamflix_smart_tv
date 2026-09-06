class MediaItem {
  final dynamic id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double rating;
  final int? year;
  final String mediaType;
  /// The identifier family used by the playback provider.  The Anime screen is
  /// a catalogue category, not an identifier family: its TMDB results must use
  /// Vidnest's movie or TV endpoints rather than its dedicated anime route.
  final String playbackType;
  final List<int> genreIds;
  final List<String> genreNames;
  final int? runtime;
  final int? totalEpisodes;
  final int? numberOfSeasons;
  final String? status;
  final String? trailer;
  final List<Map<String, dynamic>> cast;
  final List<MediaItem> recommendations;
  final List<dynamic> seasons;

  MediaItem({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    required this.rating,
    this.year,
    required this.mediaType,
    String? playbackType,
    this.genreIds = const [],
    this.genreNames = const [],
    this.runtime,
    this.totalEpisodes,
    this.numberOfSeasons,
    this.status,
    this.trailer,
    this.cast = const [],
    this.recommendations = const [],
    this.seasons = const [],
  }) : playbackType = playbackType ?? mediaType;

  // Compatibility aliases
  String get name => title;
  double get voteAverage => rating;
  String? get releaseDate => year?.toString();
  String? get firstAirDate => year?.toString();

  factory MediaItem.fromTmdbJson(
    Map<String, dynamic> json, {
    String defaultMediaType = 'movie',
    String? playbackType,
  }) {
    final mediaType = json['media_type'] ?? defaultMediaType;
    final title = json['title'] ?? json['name'] ?? 'Unknown';
    final releaseDate = json['release_date'] ?? json['first_air_date'];
    int? year;
    if (releaseDate != null && releaseDate.toString().isNotEmpty) {
      try {
        year = DateTime.parse(releaseDate.toString()).year;
      } catch (e) {
        year = null;
      }
    }

    return MediaItem(
      id: json['id'],
      title: title,
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'],
      rating: (json['vote_average'] ?? 0).toDouble(),
      year: year,
      mediaType: mediaType,
      playbackType: playbackType ?? (mediaType == 'anime' ? 'tv' : mediaType),
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      genreNames: (json['genres'] as List<dynamic>?)?.map((g) => g['name'].toString()).toList() ?? [],
      runtime: json['runtime'] ?? (json['episode_run_time'] is List && (json['episode_run_time'] as List).isNotEmpty ? json['episode_run_time'][0] : null),
      totalEpisodes: json['number_of_episodes'],
      numberOfSeasons: json['number_of_seasons'],
      status: json['status'],
      seasons: json['seasons'] ?? [],
      cast: (json['credits']?['cast'] as List<dynamic>?)?.map((c) => Map<String, dynamic>.from(c)).toList() ?? [],
      recommendations: (json['recommendations']?['results'] as List<dynamic>?)?.map((r) => MediaItem.fromTmdbJson(Map<String, dynamic>.from(r))).toList() ?? [],
    );
  }

  MediaItem copyWith({
    dynamic id,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? rating,
    int? year,
    String? mediaType,
    String? playbackType,
    List<int>? genreIds,
    List<String>? genreNames,
    int? runtime,
    int? totalEpisodes,
    int? numberOfSeasons,
    String? status,
    String? trailer,
    List<Map<String, dynamic>>? cast,
    List<MediaItem>? recommendations,
    List<dynamic>? seasons,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      mediaType: mediaType ?? this.mediaType,
      playbackType: playbackType ?? this.playbackType,
      genreIds: genreIds ?? this.genreIds,
      genreNames: genreNames ?? this.genreNames,
      runtime: runtime ?? this.runtime,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      status: status ?? this.status,
      trailer: trailer ?? this.trailer,
      cast: cast ?? this.cast,
      recommendations: recommendations ?? this.recommendations,
      seasons: seasons ?? this.seasons,
    );
  }
}
