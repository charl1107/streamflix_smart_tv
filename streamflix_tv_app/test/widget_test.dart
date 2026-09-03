import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/models/genre.dart';
import 'package:streamflix_tv/models/season_episode.dart';
import 'package:streamflix_tv/services/embed_service.dart';
import 'package:streamflix_tv/services/ad_blocker.dart';

void main() {
  group('Streamflix Models & Services Test', () {
    test('MediaItem factory from TMDB JSON', () {
      final json = {
        'id': 12345,
        'title': 'Test Movie',
        'poster_path': '/test.jpg',
        'backdrop_path': '/backdrop.jpg',
        'overview': 'Test overview',
        'vote_average': 8.5,
        'release_date': '2024-05-10',
        'media_type': 'movie',
      };

      final item = MediaItem.fromTmdbJson(json);
      expect(item.id, 12345);
      expect(item.title, 'Test Movie');
      expect(item.rating, 8.5);
      expect(item.year, 2024);
      expect(item.mediaType, 'movie');
    });

    test('Genre model from JSON', () {
      final genre = Genre.fromJson({'id': 28, 'name': 'Action'});
      expect(genre.id, 28);
      expect(genre.name, 'Action');
    });

    test('Season and Episode models from JSON', () {
      final season = Season.fromJson({
        'season_number': 1,
        'name': 'Season 1',
        'episode_count': 10,
      });
      expect(season.seasonNumber, 1);
      expect(season.name, 'Season 1');

      final episode = Episode.fromJson({
        'episode_number': 1,
        'name': 'Pilot',
        'overview': 'The beginning',
      });
      expect(episode.episodeNumber, 1);
      expect(episode.title, 'Pilot');
    });

    test('Vidnest Embed URL generator', () {
      final movieUrl = EmbedService.getMovieUrl(123, server: 'lamda');
      expect(movieUrl, 'https://vidnest.fun/movie/123?server=lamda');

      final tvUrl = EmbedService.getTvUrl(456, 2, 5, server: 'gama');
      expect(tvUrl, 'https://vidnest.fun/tv/456/2/5?server=gama');
    });

    test('AdBlocker blocks known ad domains', () {
      expect(AdBlocker.isAdUrl('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'), true);
      expect(AdBlocker.isAdUrl('https://popads.net/serve'), true);
      expect(AdBlocker.isAdUrl('https://doubleclick.net/ad'), true);
      expect(AdBlocker.isAdUrl('https://vidnest.fun/movie/123'), false);
    });
  });
}
