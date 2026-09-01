import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:streamflix_tv/services/ad_blocker.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  String _embedUrl = '';
  String _title = '';
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _embedUrl = args['embedUrl'] ?? '';
        _title = args['title'] ?? 'Player';
        _initWebView();
        _initialized = true;
      }
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(const Color(0x00000000));

    // Enable platform-specific settings required for video playback on Android TV
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnPlatformPermissionRequest((request) => request.grant());
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
      platform.setOnConsoleMessage((message) {
        debugPrint('[WebView Console] ${message.message}');
      });
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('[WebView Resource Error] ${error.description} for ${error.url}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Block known ad popups and malicious ad redirect domains
            if (AdBlocker.isAdUrl(request.url)) {
              debugPrint('[AdBlock] Blocked ad navigation: ${request.url}');
              return NavigationDecision.prevent;
            }

            // Allow all internal and media streaming requests
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) async {
            try {
              final css = AdBlocker.adBlockCss.replaceAll('\n', ' ').replaceAll("'", "\\'");
              final injectCssScript = """
                (function() {
                  const style = document.createElement('style');
                  style.innerHTML = '$css';
                  (document.head || document.documentElement).appendChild(style);
                  document.body.classList.add('is-embedded');

                  // Ensure video player initializes if script loaded after initial call
                  if (typeof initVideoJS === 'function') {
                    try { initVideoJS(); } catch(e) {}
                  }
                })();
              """;
              await _controller.runJavaScript(injectCssScript);
              await _controller.runJavaScript(AdBlocker.adBlockScript);
            } catch (e) {
              debugPrint('Failed to inject script: $e');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_embedUrl),
        headers: {
          'Referer': 'https://streamflix.tv/',
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_embedUrl.isNotEmpty)
              WebViewWidget(controller: _controller),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),

            // Semi-transparent top navigation bar
            Positioned(
              top: 24,
              left: 24,
              child: Row(
                children: [
                  TvFocusWrapper(
                    onTap: () => Navigator.pop(context),
                    autofocus: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                  ),
                  if (_title.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
