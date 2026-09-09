package com.streamflix.streamflix_tv

import android.content.Intent
import android.os.Bundle
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi
import java.io.ByteArrayInputStream

class MainActivity : FlutterActivity() {
    private val launchChannel = "com.streamflix.streamflix_tv/launch"
    private val adBlockChannel = "com.streamflix.streamflix_tv/ad_blocker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adBlockChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "attachResourceBlocker") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val identifier = (call.arguments as? Number)?.toLong()
                val webView = identifier?.let {
                    WebViewFlutterAndroidExternalApi.getWebView(flutterEngine, it)
                }
                if (webView == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                result.success(attachResourceBlocker(webView))
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleLauncherIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLauncherIntent(intent)
    }

    private fun handleLauncherIntent(intent: Intent) {
        if (intent.action != Intent.ACTION_MAIN) return

        val launchedFromLauncher = intent.hasCategory(Intent.CATEGORY_LAUNCHER) ||
            intent.hasCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
        if (!launchedFromLauncher) return

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, launchChannel).invokeMethod("resetToHome", null)
        }
    }

    private fun attachResourceBlocker(webView: WebView): Boolean {
        val delegate = existingWebViewClient(webView) ?: return false
        if (delegate is ResourceBlockingWebViewClient) return true
        webView.webViewClient = ResourceBlockingWebViewClient(delegate)
        return true
    }

    private fun existingWebViewClient(webView: WebView): WebViewClient? {
        var type: Class<*>? = webView.javaClass
        while (type != null) {
            try {
                val field = type.getDeclaredField("currentWebViewClient")
                field.isAccessible = true
                return field.get(webView) as? WebViewClient
            } catch (_: NoSuchFieldException) {
                type = type.superclass
            }
        }
        return null
    }

    private class ResourceBlockingWebViewClient(
        private val delegate: WebViewClient,
    ) : WebViewClient() {
        override fun shouldInterceptRequest(
            view: WebView,
            request: WebResourceRequest,
        ): WebResourceResponse? {
            if (isBlocked(request.url.toString())) return emptyResponse()
            return delegate.shouldInterceptRequest(view, request)
        }

        @Suppress("DEPRECATION")
        override fun shouldInterceptRequest(view: WebView, url: String): WebResourceResponse? {
            if (isBlocked(url)) return emptyResponse()
            return delegate.shouldInterceptRequest(view, url)
        }

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
            delegate.shouldOverrideUrlLoading(view, request)

        @Suppress("DEPRECATION")
        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean =
            delegate.shouldOverrideUrlLoading(view, url)

        override fun onPageStarted(view: WebView, url: String, favicon: android.graphics.Bitmap?) =
            delegate.onPageStarted(view, url, favicon)

        override fun onPageFinished(view: WebView, url: String) = delegate.onPageFinished(view, url)

        private fun emptyResponse() = WebResourceResponse(
            "text/plain",
            "utf-8",
            204,
            "No Content",
            emptyMap(),
            ByteArrayInputStream(ByteArray(0)),
        )

        private fun isBlocked(url: String): Boolean {
            val value = url.lowercase()
            return blockedHosts.any(value::contains)
        }

        private companion object {
            // Network-level blocklist. This is the strongest ad/tracker layer:
            // matched requests never leave the device, so pop-under brokers and
            // telemetry beacons cannot load even if the page injects them later.
            val blockedHosts = setOf(
                // Ad exchanges & display networks
                "doubleclick.net", "googlesyndication.com", "googleadservices.com",
                "pagead2.googlesyndication.com", "adservice.google.com",
                "googletagservices.com", "2mdn.net", "adnxs.com", "adsrvr.org",
                "rubiconproject.com", "pubmatic.com", "openx.net", "casalemedia.com",
                "sharethrough.com", "amazon-adsystem.com", "moatads.com",
                "serving-sys.com", "exponential.com", "undertone.com", "yieldmo.com",
                "indexexchange.com", "triplelift.com", "smartadserver.com",
                "adblade.com", "bidswitch.net", "contextweb.com", "sovrn.com",
                "spotxchange.com", "spotx.tv", "teads.tv", "vibrantmedia.com",
                "adikteev.com", "adkernel.com", "adotmob.com", "adform.net",
                "yieldmanager.com", "yieldpartners.com", "yieldkit.com",
                "springserve.com", "stickyadstv.com", "smartyads.com",
                "servedby-buysellads.com", "kiosked.com",
                // Pop-under / pop-up / redirect brokers
                "popads.net", "popcash.net", "propellerads.com", "propellerclick.com",
                "adsterra.com", "exoclick.com", "juicyads.com", "juicyscores.com",
                "monetag.com", "clickadu.com", "onclickads.com", "onclickads.net",
                "onclickmega.com", "onclicktop.com", "onclickuds.com", "onclicads.com",
                "hilltopads.com", "hilltopads.net", "bidvertiser.com", "adcash.com",
                "adbooth.com", "admaven.co", "adtng.com", "adf.ly", "ouo.io",
                "bc.vc", "sh.st", "cpx24.com", "cpm.biz", "dolohen.com",
                "roller-ads.com", "richpush.com", "clickaine.com", "admatic.com",
                "trafficstars.com", "trafficjunky.com", "terraclicks.com",
                "adcolony.com", "vungle.com", "applovin.com", "chartboost.com",
                "startapp.com", "tapjoy.com", "mobvista.com", "webeyemob.com",
                "puserving.com", "rtmark.net", "revdepo.com", "gothamads.com",
                "betweendigital.com", "aueou.com", "borrowhourglass.com",
                "obiitpudent.shop", "peelcleanstatic.com", "whiteclick.info",
                "xusspb.com", "darrfrede.com", "goldenmous.com",
                // Native-ad / content-recommendation widgets
                "outbrain.com", "taboola.com", "mgid.com", "revcontent.com",
                "zergnet.com", "speakol.com", "spoutable.com",
                // Analytics / telemetry / trackers
                "google-analytics.com", "googletagmanager.com", "analytics.google.com",
                "stats.g.doubleclick.net", "scorecardresearch.com", "quantserve.com",
                "segment.io", "segment.com", "mixpanel.com", "amplitude.com",
                "hotjar.com", "intercom.io", "sentry.io", "newrelic.com",
                "datadoghq.com", "crazyegg.com", "mouseflow.com", "fullstory.com",
                "clarity.ms", "pingdom.net", "matomo.org", "pendo.io",
                "optimizely.com", "appmetrica.com", "branch.io", "posthog.com",
                "onesignal.com", "swrve.com", "connect.facebook.net",
                // Crypto miners
                "coinhive.com", "coin-hive.com", "crypto-loot.com",
            )
        }
    }
}
