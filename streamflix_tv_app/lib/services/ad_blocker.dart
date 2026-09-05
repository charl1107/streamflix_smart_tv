import 'package:flutter/foundation.dart';

class AdBlocker {
  /// Known malicious ad networks, popunder brokers, and ad-serving domains
  static const List<String> blockedDomains = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com', 'google-analytics.com',
    'adservice.google.com', 'pagead2.googlesyndication.com', 'popads.net', 'popcash.net',
    'propellerads.com', 'adsterra.com', 'exoclick.com', 'juicyads.com', 'trafficjunky.com',
    'adnxs.com', 'adsrvr.org', 'rubiconproject.com', 'pubmatic.com', 'openx.net',
    'casalemedia.com', 'sharethrough.com', 'outbrain.com', 'taboola.com', 'mgid.com',
    'revcontent.com', 'amazon-adsystem.com', 'moatads.com', '2mdn.net', 'serving-sys.com',
    'exponential.com', 'undertone.com', 'yieldmo.com', 'indexexchange.com', 'triplelift.com',
    'smartadserver.com', 'adcolony.com', 'unity3d.com', 'vungle.com', 'applovin.com',
    'chartboost.com', 'inmobi.com', 'mopub.com', 'smaato.com', 'flurry.com', 'millennialmedia.com',
    'leadbolt.com', 'startapp.com', 'tapjoy.com', 'supersonic.com', 'ironsrc.com', 'fyber.com',
    'digitalturbine.com', 'liftoff.com', 'appreciate.mobi', 'applift.com', 'avazu.net',
    'clickadu.com', 'hilltopads.com', 'bidvertiser.com', 'adf.ly', 'ouo.io', 'bc.vc', 'sh.st',
    'adbooth.com', 'adcash.com', 'admaven.co', 'adtng.com', 'aueou.com', 'betweendigital.com',
    'bongacams.com', 'chaturbate.com', 'cpm.biz', 'cpx24.com', 'crpusle.com', 'darrfrede.com',
    'dolohen.com', 'elasticbeanstalk.com', 'ero-advertising.com', 'f4ir.com', 'fraudfighter.in',
    'goldenmous.com', 'gogoads.com', 'gothamads.com', 'hilltopads.net', 'hot-potatoes.com',
    'incrivel.club', 'j8sz.com', 'jaleco.com', 'juicyscores.com', 'kiosked.com', 'livejasmin.com',
    'mnad.co', 'mobvista.com', 'mopuboost.com', 'mythings.com', 'onclicads.com', 'onclickads.net',
    'onclickads2.com', 'onclickmega.com', 'onclicktop.com', 'onclickuds.com', 'peelcleanstatic.com',
    'pluggd.in', 'popcss.com', 'prmtracking.com', 'propellerclick.com', 'puserving.com',
    'qualitymediaserving.com', 'revdepo.com', 'richpush.com', 'rndcdn.com', 'roller-ads.com',
    'rtmark.net', 's-static.innovid.com', 'servedby-buysellads.com', 'serving-sys.com',
    'smaato.net', 'smartyads.com', 'speakol.com', 'spoutable.com', 'springserve.com',
    'static-doubleclick.net', 'steepto.com', 'stickyadstv.com', 'strmclk.com', 'terraclicks.com',
    'titsmovies.com', 'trafficstars.com', 'trk-analytics.com', 'trustx.org', 'uselnk.com',
    'vidoomy.com', 'webeyemob.com', 'whiteclick.info', 'xusspb.com', 'yieldkit.com',
    'yieldmanager.com', 'yieldpartners.com', 'zergnet.com', 'adkeeper.co', 'monetag.com',
    'coinhive.com', 'coin-hive.com', 'crypto-loot.com', 'adx.adform.net', 'scorecardresearch.com',
    'adblade.com', 'bidswitch.net', 'contextweb.com', 'sovrn.com', 'spotxchange.com', 'spotx.tv',
    'teads.tv', 'vibrantmedia.com', 'adikteev.com', 'adkernel.com', 'admatic.com', 'adotmob.com'
  ];

  /// Common telemetry and analytics domains that should never be loaded in embedded media players
  static const List<String> blockedTrackerDomains = [
    'googletagmanager.com', 'google-analytics.com', 'analytics.google.com', 'doubleclick.net',
    'googletagservices.com', 'gtm.js', 'gtag/js', 'segment.io', 'segment.com', 'mixpanel.com',
    'amplitude.com', 'hotjar.com', 'intercom.io', 'sentry.io', 'newrelic.com', 'datadoghq.com',
    'quantserve.com', 'scorecardresearch.com', 'crazyegg.com', 'mouseflow.com', 'fullstory.com',
    'clarity.ms', 'pingdom.net', 'matomo.org', 'plausible.io', 'pendo.io', 'optimizely.com',
    'appmetrica.com', 'branch.io', 'posthog.com', 'fbclid.com', 'facebook.net', 'connect.facebook.net',
    'linkedin.com', 'linkedin.com/li', 'stats.g.doubleclick.net', 'ads.doubleclick.net',
    'cdn.segment.com', 'api.segment.io', 'beam.pro', 'swrve.com', 'onesignal.com', 'pixel.facebook.com',
    'akamaihd.net', 'cdn.amplitude.com', 'www.google-analytics.com', 'www.googletagmanager.com',
    'adblock', 'adblockplus', 'adguard', 'ublock', 'ublockorigin', 'adblocker', 'adblockers',
    'antiadblock', 'easylist', 'fanboy', 'adguarddns', 'adblockanalytics',
    'obiitpudent.shop', 'xl.obiitpudent.shop'
  ];

  /// Trusted domains permitted for video playback and essential assets
  static const List<String> allowedDomainKeywords = [
    'vidnest.fun',
    'vidnest',
    'wyzie.io',
    'vdrk.site',
    'streaming-1.workers.dev',
    'streamflix',
    'workers.dev',
    'cloudflare',
    'cloudflareinsights.com',
    'tmdb.org',
    'themoviedb.org',
    'gstatic.com',
    'googleapis.com',
    'jsdelivr.net',
    'm3u8',
    'hls',
    'mp4',
    'blob:',
  ];

  /// Checks if a URL points to a known ad or tracking domain
  static bool isAdUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    for (final domain in blockedDomains) {
      if (lowerUrl.contains(domain)) {
        return true;
      }
    }
    return isTrackerUrl(lowerUrl);
  }

  static bool isTrackerUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    for (final tracker in blockedTrackerDomains) {
      if (lowerUrl.contains(tracker)) {
        return true;
      }
    }
    return false;
  }

  /// Evaluates whether a top-level navigation should be permitted
  static bool shouldAllowNavigation(String currentUrl, String targetUrl) {
    if (targetUrl.isEmpty) return false;
    final lowerTarget = targetUrl.toLowerCase();

    // 1. Immediately reject any known ad or tracker domain
    if (isAdUrl(lowerTarget)) {
      debugPrint('[AdBlock] Blocked navigation to ad/tracker domain: $targetUrl');
      return false;
    }

    // 2. Allow blank / initial pages
    if (lowerTarget == 'about:blank' || lowerTarget.startsWith('data:')) {
      return true;
    }

    // 3. Allow legitimate media stream protocols and destinations
    if (lowerTarget.endsWith('.m3u8') || lowerTarget.endsWith('.mp4') || lowerTarget.contains('.m3u8?')) {
      return true;
    }

    // 4. Verify against allowed domain whitelist
    for (final keyword in allowedDomainKeywords) {
      if (lowerTarget.contains(keyword)) {
        return true;
      }
    }

    // Block unknown third-party redirect hops
    debugPrint('[AdBlock] Blocked unauthorized redirect: $targetUrl');
    return false;
  }

  /// Injected JavaScript protecting the WebView environment
  static String get adBlockScript => '''
    (function() {
      // 1. Permanently neutralize window popup and alert APIs
      const noop = function() { return null; };
      window.open = noop;
      window.alert = noop;
      window.confirm = function() { return true; };
      window.prompt = noop;

      try {
        Object.defineProperty(window, 'open', { value: noop, writable: false });
      } catch(e) {}

      // 2. Intercept click events targeting external ad tabs or unknown links
      document.addEventListener('click', function(e) {
        let target = e.target;
        while (target && target !== document.body) {
          if (target.tagName === 'A') {
            const href = target.getAttribute('href') || '';
            const targetAttr = target.getAttribute('target');
            const hrefLower = href.toLowerCase();
            const isTrackerLink = [
              'googletagmanager.com', 'google-analytics.com', 'segment.io', 'doubleclick.net',
              'mixpanel.com', 'amplitude.com', 'hotjar.com', 'sentry.io', 'intercom.io', 'facebook.net'
            ].some(domain => hrefLower.includes(domain));
            if (targetAttr === '_blank' || isTrackerLink || (href.startsWith('http') && !href.includes('vidnest.fun'))) {
              e.preventDefault();
              e.stopPropagation();
              console.log('[AdBlock JS] Blocked clickjack navigation to: ' + href);
              return false;
            }
          }
          target = target.parentElement;
        }
      }, true);

      // 3. Clean up existing ad overlays, tracker scripts, and deceptive transparency divs
      function cleanAdOverlays() {
        const adSelectors = [
          '.adsbygoogle', '.banner-ad', '.popunder',
          'div[id*="ad-"]', 'div[class*="ad-"]',
          'div[id*="player-ad-overlay"]',
          'iframe[src*="doubleclick"]', 'iframe[src*="popads"]', 'iframe[src*="popcash"]',
          'iframe[src*="propeller"]', 'iframe[src*="adsterra"]', 'iframe[src*="exoclick"]',
          'iframe[src*="juicyads"]', 'iframe[src*="monetag"]',
          'div[style*="z-index: 99999"]',
          'div[style*="z-index: 2147483647"]'
        ];
        
        adSelectors.forEach(selector => {
          try {
            document.querySelectorAll(selector).forEach(el => {
              // Never remove the main video player or trusted streaming iframes
              const src = (el.getAttribute('src') || '').toLowerCase();
              if (src.includes('vidnest') || src.includes('wyzie') || src.includes('vdrk') || src.includes('workers.dev')) {
                return;
              }
              if (!el.querySelector('video')) {
                el.remove();
              }
            });
          } catch(e) {}
        });
      }

      cleanAdOverlays();

      // 4. Observe DOM mutations to remove dynamically injected ads
      const observer = new MutationObserver(() => {
        cleanAdOverlays();
      });

      if (document.body) {
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
      }
    })();
  ''';

  /// Injected CSS to prevent ad elements from rendering or accepting pointer clicks
  static String get adBlockCss => '''
    .adsbygoogle, 
    .banner-ad, 
    .popunder,
    #player-ad-overlay,
    #ad-popup-modal,
    div[id*="ad-popup"],
    div[class*="ad-container"] {
      display: none !important;
      opacity: 0 !important;
      pointer-events: none !important;
      z-index: -9999 !important;
    }
  ''';
}
