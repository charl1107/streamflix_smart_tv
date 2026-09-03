import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/services/ad_blocker.dart';

void main() {
  group('AdBlocker Security & Shielding Tests', () {
    test('Detects malicious popunder, redirect and tracking domains', () {
      final sampleAdUrls = [
        'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js',
        'https://popads.net/serve/ad?id=123',
        'https://popcash.net/click/redirect',
        'https://propellerads.com/zone/456',
        'https://adsterra.com/script/overlay.js',
        'https://betweendigital.com/auction',
        'https://clickadu.com/track',
        'https://hilltopads.com/adserver',
        'https://doubleclick.net/gampad/ads',
        'https://exoclick.com/tag.php',
        'https://monetag.com/sdk.js',
        'https://adkeeper.co/widget',
      ];

      for (final url in sampleAdUrls) {
        expect(AdBlocker.isAdUrl(url), true, reason: 'Failed to block ad URL: $url');
      }
    });

    test('Never blocks legitimate Vidnest, streaming CDNs, or assets', () {
      final legitimateUrls = [
        'https://vidnest.fun/movie/324857?server=lamda',
        'https://vidnest.fun/tv/94997/1/1?server=gama',
        'https://streamflix-tv-backend.workers.dev/api/player',
        'https://image.tmdb.org/t/p/w500/poster.jpg',
        'https://cdn.jsdelivr.net/npm/hls.js',
        'https://cloudflare.com/cdn-cgi/trace',
      ];

      for (final url in legitimateUrls) {
        expect(AdBlocker.isAdUrl(url), false, reason: 'Legitimate URL falsely blocked: $url');
      }
    });

    test('shouldAllowNavigation permits internal streaming but traps ad redirects', () {
      const currentUrl = 'https://vidnest.fun/movie/324857';

      // Block external ad network navigation
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'https://popads.net/lander?source=vid'),
        false,
      );
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'https://betweendigital.com/track'),
        false,
      );
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'https://sketchy-reward-scam.xyz/win'),
        false,
      );

      // Allow same-origin or authorized media subresource navigation
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'https://vidnest.fun/movie/324857?server=alfa'),
        true,
      );
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'https://edge-cdn-streaming.com/playlist.m3u8'),
        true,
      );
      expect(
        AdBlocker.shouldAllowNavigation(currentUrl, 'about:blank'),
        true,
      );
    });

    test('Shield scripts contain window.open neutralization and clickjack prevention', () {
      final script = AdBlocker.adBlockScript;
      expect(script, contains('window.open = noop'));
      expect(script, contains('window.alert = noop'));
      expect(script, contains('cleanAdOverlays'));
      expect(script, contains('MutationObserver'));

      final css = AdBlocker.adBlockCss;
      expect(css, contains('display: none !important'));
      expect(css, contains('.adsbygoogle'));
    });
  });
}
