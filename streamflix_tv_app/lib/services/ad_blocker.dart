class AdBlocker {
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
    'yieldmanager.com', 'yieldpartners.com', 'zergnet.com'
  ];

  static bool isAdUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    for (final domain in blockedDomains) {
      if (lowerUrl.contains(domain)) {
        return true;
      }
    }
    return false;
  }

  static String get adBlockScript => '''
    (function() {
      // Block window popups
      window.open = function() { return null; };
      window.alert = function() {};
      window.confirm = function() { return true; };
      window.prompt = function() { return null; };

      // Remove obvious ad overlay elements
      function removeAds() {
        const adSelectors = [
          '.adsbygoogle', '.banner-ad', '.popunder',
          'div[id*="ad-popup"]', 'div[id*="player-ad-overlay"]',
          'a[href*="penguinsincequalify.com"]', 'a[href*="doubleclick"]'
        ];
        
        adSelectors.forEach(selector => {
          document.querySelectorAll(selector).forEach(el => el.remove());
        });
      }

      removeAds();

      const observer = new MutationObserver(() => {
        removeAds();
      });

      if (document.body) {
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
      }
    })();
  ''';

  static String get adBlockCss => '''
    .adsbygoogle, 
    .banner-ad, 
    .popunder,
    #player-ad-overlay,
    #ad-popup-modal {
      display: none !important;
      opacity: 0 !important;
      pointer-events: none !important;
      z-index: -1 !important;
    }
  ''';
}
