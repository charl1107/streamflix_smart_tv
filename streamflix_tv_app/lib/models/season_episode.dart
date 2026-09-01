class Season {
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final String? overview;

  Season({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.posterPath,
    this.overview,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'] ?? '',
      episodeCount: json['episode_count'] ?? 0,
      posterPath: json['poster_path'],
      overview: json['overview'],
    );
  }
}

class Episode {
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;

  Episode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
  });

  String get title => name;
  int get episode => episodeNumber;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episode_number'] ?? json['number'] ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      overview: json['overview'] ?? json['description'],
      stillPath: json['still_path'] ?? json['image'],
      airDate: json['air_date'],
      runtime: json['runtime'],
    );
  }
}
