import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/services/vidnest_service.dart';
import 'package:streamflix_tv/services/embed_service.dart';

void main() {
  group('VidnestService Tests', () {
    test('Builds basic movie URL with default server', () {
      final url = VidnestService.buildMovieUrl(tmdbId: 324857);
      expect(url, 'https://vidnest.fun/movie/324857?server=lamda');
    });

    test('Builds movie URL with specific server and startAt timestamp', () {
      final url = VidnestService.buildMovieUrl(
        tmdbId: 324857,
        server: 'gama',
        startAt: 145,
      );
      expect(url, 'https://vidnest.fun/movie/324857?server=gama&startAt=145');
    });

    test('Builds TV show URL with season, episode, server and startAt', () {
      final url = VidnestService.buildTvUrl(
        tmdbId: 94997,
        season: 1,
        episode: 1,
        server: 'alfa',
        startAt: 90,
      );
      expect(url, 'https://vidnest.fun/tv/94997/1/1?server=alfa&startAt=90');
    });

    test('Builds anime URL with Anilist ID and sub preference', () {
      final url = VidnestService.buildAnimeUrl(
        anilistId: 154587,
        episode: 1,
        subOrDub: 'sub',
        server: 'primesrc',
        startAt: 30,
      );
      expect(url, 'https://vidnest.fun/anime/154587/1/sub?server=primesrc&startAt=30');
    });

    test('Provides 9 valid streaming servers', () {
      expect(VidnestService.servers.length, 9);
      final serverIds = VidnestService.servers.map((s) => s.id).toList();
      expect(serverIds, containsAll([
        'lamda', 'primesrc', 'gama', 'alfa', 'beta', 'sigma', 'catflix', 'hexa', 'delta'
      ]));
    });

    test('findServer returns correct server or defaults to lamda', () {
      final gama = VidnestService.findServer('gama');
      expect(gama.name, 'Gama');

      final unknown = VidnestService.findServer('non_existent');
      expect(unknown.id, 'lamda');
    });

    test('EmbedService routes to Vidnest by default', () {
      EmbedService.useDirectVidnest = true;
      final movie = EmbedService.getMovieUrl(550, server: 'sigma', startAt: 60);
      expect(movie, 'https://vidnest.fun/movie/550?server=sigma&startAt=60');

      final tv = EmbedService.getTvUrl(1399, 1, 1, server: 'primesrc');
      expect(tv, 'https://vidnest.fun/tv/1399/1/1?server=primesrc');
    });
  });
}
