import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/embed_service.dart';

class PlayerProvider extends ChangeNotifier {
  MediaItem? currentMedia;
  String? embedUrl;
  int? currentSeason;
  int? currentEpisode;

  void setMovie(MediaItem movie) {
    currentMedia = movie;
    currentSeason = null;
    currentEpisode = null;
    embedUrl = EmbedService.getMovieUrl(movie.id);
    notifyListeners();
  }

  void setTvEpisode(MediaItem show, int season, int episode) {
    currentMedia = show;
    currentSeason = season;
    currentEpisode = episode;
    embedUrl = EmbedService.getTvUrl(show.id, season, episode);
    notifyListeners();
  }
}
