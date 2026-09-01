import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:streamflix_tv/services/ad_blocker.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

/// Fallback WebView player used when native M3U8 streams are unavailable.
/// Injects a D-pad navigation system into the embed so the TV remote can
/// browse and activate the embed's own controls (settings, cast, etc).
class PlayerWebViewScreen extends StatefulWidget {
  const PlayerWebViewScreen({super.key});

  @override
  State<PlayerWebViewScreen> createState() => _PlayerWebViewScreenState();
}

class _PlayerWebViewScreenState extends State<PlayerWebViewScreen> {
  late final WebViewController _controller;
  final FocusNode _focusNode = FocusNode();
  String _embedUrl = '';
  String _title = '';
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _embedUrl = args['embedUrl'] ?? '';
        _title = args['title'] ?? 'Player';
        _initWebView();
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  WebView setup
  // ──────────────────────────────────────────────────────────────

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(const Color(0xFF000000));

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnPlatformPermissionRequest((request) => request.grant());
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
    }

    _controller.setNavigationDelegate(NavigationDelegate(
      onWebResourceError: (error) {
        debugPrint('[WebView Error] ${error.description}');
      },
      onNavigationRequest: (request) {
        if (AdBlocker.isAdUrl(request.url)) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageFinished: (url) async {
        try {
          final css =
              AdBlocker.adBlockCss.replaceAll('\n', '').replaceAll("'", "\\'");
          await _controller.runJavaScript('''
            (function() {
              const s = document.createElement('style');
              s.innerHTML = '$css';
              (document.head || document.documentElement).appendChild(s);
            })();
          ''');
          await _controller.runJavaScript(AdBlocker.adBlockScript);
        } catch (_) {}

        // Inject D-pad navigation system into the embed
        await _injectDpadNavigation();

        if (mounted) setState(() => _isLoading = false);
      },
    ));

    _controller.loadRequest(Uri.parse(_embedUrl),
        headers: {'Referer': 'https://streamflix.tv/'});
  }

  // ──────────────────────────────────────────────────────────────
  //  D-pad navigation injection
  // ──────────────────────────────────────────────────────────────

  /// Injects a comprehensive D-pad navigation system into the embed page.
  /// This makes all interactive controls (play, settings, cast, download,
  /// fullscreen, etc.) focusable and navigable with the TV remote.
  Future<void> _injectDpadNavigation() async {
    await _controller.runJavaScript('''
      (function() {
        // ── Wait for DOM to settle, then make controls focusable ──
        setTimeout(setupDpadNav, 500);
        setTimeout(setupDpadNav, 2000); // Re-scan in case of lazy-loaded controls

        function setupDpadNav() {
          // 1. Make all interactive elements focusable
          var selectors = [
            'button', 'a', '[role="button"]', '[tabindex]',
            'input[type="range"]',  // sliders / progress bars
            '.settings', '.gear', '[class*="setting"]',
            '[class*="control"]', '[class*="btn"]', '[class*="icon"]',
            '[class*="cast"]', '[class*="download"]', '[class*="fullscreen"]',
            '[class*="quality"]', '[class*="subtitle"]', '[class*="caption"]',
            'video',  // the video element itself
          ];

          var allInteractive = document.querySelectorAll(selectors.join(', '));
          allInteractive.forEach(function(el) {
            if (!el.hasAttribute('tabindex')) {
              el.setAttribute('tabindex', '0');
            }
          });

          // 2. Inject focus styles for TV navigation
          if (!document.getElementById('tv-dpad-styles')) {
            var style = document.createElement('style');
            style.id = 'tv-dpad-styles';
            style.textContent = \`
              [tabindex="0"]:focus {
                outline: 2px solid #3b82f6 !important;
                outline-offset: 2px;
                box-shadow: 0 0 12px rgba(59,130,246,0.6) !important;
                border-radius: 4px;
              }
              [tabindex="0"]:focus-visible {
                outline: 2px solid #3b82f6 !important;
              }
            \`;
            (document.head || document.documentElement).appendChild(style);
          }

          // 3. Build ordered list of all focusable elements for spatial nav
          window._tvFocusables = Array.from(
            document.querySelectorAll('[tabindex="0"], button, a, [role="button"], input[type="range"], video')
          ).filter(function(el) {
            var rect = el.getBoundingClientRect();
            var style = window.getComputedStyle(el);
            return rect.width > 0 && rect.height > 0 &&
                   style.display !== 'none' && style.visibility !== 'hidden' &&
                   style.opacity !== '0';
          });

          // 4. Track which element is focused
          if (typeof window._tvFocusIndex === 'undefined') {
            window._tvFocusIndex = -1;
          }

          // 5. Focus element by index
          window._tvFocusElement = function(idx) {
            var items = window._tvFocusables;
            if (!items || items.length === 0) return;
            idx = Math.max(0, Math.min(idx, items.length - 1));
            window._tvFocusIndex = idx;
            try {
              items[idx].focus({ preventScroll: false });
              items[idx].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            } catch(e) {}
          };

          // 6. Spatial navigation: find nearest element in direction
          window._tvSpatialNav = function(direction) {
            var items = window._tvFocusables;
            if (!items || items.length === 0) return;

            var current = document.activeElement;
            var currentRect = current ? current.getBoundingClientRect() : { left: window.innerWidth/2, top: window.innerHeight/2, right: window.innerWidth/2, bottom: window.innerHeight/2, width: 0, height: 0 };
            var cx = (currentRect.left + currentRect.right) / 2;
            var cy = (currentRect.top + currentRect.bottom) / 2;

            var best = null;
            var bestDist = Infinity;

            for (var i = 0; i < items.length; i++) {
              var r = items[i].getBoundingClientRect();
              var ex = (r.left + r.right) / 2;
              var ey = (r.top + r.bottom) / 2;

              var dx = ex - cx;
              var dy = ey - cy;

              // Must move in the right direction
              var inDirection = false;
              switch(direction) {
                case 'left':  inDirection = dx < -5; break;
                case 'right': inDirection = dx > 5; break;
                case 'up':    inDirection = dy < -5; break;
                case 'down':  inDirection = dy > 5; break;
              }
              if (!inDirection) continue;

              // Score: prefer elements that are more directly in the direction
              var dist = Math.sqrt(dx * dx + dy * dy);
              // Weight directional alignment heavily
              var alignment = 0;
              switch(direction) {
                case 'left':
                case 'right':
                  alignment = Math.abs(dy) / (Math.abs(dx) + 1);
                  break;
                case 'up':
                case 'down':
                  alignment = Math.abs(dx) / (Math.abs(dy) + 1);
                  break;
              }
              var score = dist * (1 + alignment * 2);

              if (score < bestDist) {
                bestDist = score;
                best = i;
              }
            }

            if (best !== null) {
              window._tvFocusElement(best);
            }
          };

          // 7. Activate the currently focused element
          window._tvActivate = function() {
            var el = document.activeElement;
            if (!el) return;
            // Simulate click
            el.click();
            // Also fire keydown Enter for frameworks that listen to key events
            el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true }));
          };

          // 8. Toggle play/pause on the video
          window._tvTogglePlay = function() {
            var video = document.querySelector('video');
            if (video) {
              if (video.paused) video.play(); else video.pause();
            }
          };

          // 9. Dispatch keyboard event to page (for existing handlers)
          window._tvDispatchKey = function(key, code) {
            window.dispatchEvent(new KeyboardEvent('keydown', {
              key: key, code: code, bubbles: true, cancelable: true
            }));
          };

          console.log('[DpadNav] Setup complete, ' + window._tvFocusables.length + ' focusable elements found');
        }
      })();
    ''');
  }

  // ──────────────────────────────────────────────────────────────
  //  D-pad → WebView JS bridge
  // ──────────────────────────────────────────────────────────────

  /// Dispatches D-pad keys to the embed's navigation system.
  /// Arrow keys navigate between UI controls; Enter/Select activates them;
  /// dedicated keys trigger specific actions (play, settings, back).
  Future<void> _dispatchKeyToWebView(LogicalKeyboardKey key) async {
    switch (key) {
      // ── Arrow keys → spatial navigation between controls ──
      case LogicalKeyboardKey.arrowRight:
        await _controller.runJavaScript("window._tvSpatialNav && window._tvSpatialNav('right');");
      case LogicalKeyboardKey.arrowLeft:
        await _controller.runJavaScript("window._tvSpatialNav && window._tvSpatialNav('left');");
      case LogicalKeyboardKey.arrowUp:
        await _controller.runJavaScript("window._tvSpatialNav && window._tvSpatialNav('up');");
      case LogicalKeyboardKey.arrowDown:
        await _controller.runJavaScript("window._tvSpatialNav && window._tvSpatialNav('down');");

      // ── Enter / Select → activate focused element ──
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.gameButtonA:
      case LogicalKeyboardKey.numpadEnter:
        await _controller.runJavaScript("window._tvActivate && window._tvActivate();");

      // ── Space → play/pause (quick toggle) ──
      case LogicalKeyboardKey.space:
        await _controller.runJavaScript("window._tvTogglePlay && window._tvTogglePlay();");

      // ── Back / Escape → close modals or exit ──
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.browserBack:
        await _tryCloseModalOrPop();
        return;

      // ── Play/Pause dedicated button ──
      case LogicalKeyboardKey.mediaPlayPause:
        await _controller.runJavaScript("window._tvTogglePlay && window._tvTogglePlay();");

      // ── Menu / Context → open settings if available ──
      case LogicalKeyboardKey.menu:
      case LogicalKeyboardKey.contextMenu:
        // Try to find and click a settings/gear button
        await _controller.runJavaScript('''
          (function() {
            var btns = document.querySelectorAll('button, [role="button"], [class*="setting"], [class*="gear"]');
            for (var i = 0; i < btns.length; i++) {
              var text = (btns[i].textContent || '').toLowerCase();
              var cls = (btns[i].className || '').toLowerCase();
              if (text.includes('setting') || cls.includes('setting') || cls.includes('gear') || cls.includes('config')) {
                btns[i].click();
                return;
              }
            }
            // Fallback: dispatch 's' key for embeds that use keyboard shortcuts
            window._tvDispatchKey('s', 'KeyS');
          })();
        ''');

      // ── Rewind / Fast-forward media keys ──
      case LogicalKeyboardKey.mediaRewind:
        await _controller.runJavaScript("window._tvDispatchKey('ArrowLeft', 'ArrowLeft');");
      case LogicalKeyboardKey.mediaFastForward:
        await _controller.runJavaScript("window._tvDispatchKey('ArrowRight', 'ArrowRight');");
      case LogicalKeyboardKey.mediaPlay:
        await _controller.runJavaScript("var v = document.querySelector('video'); if(v && v.paused) v.play();");
      case LogicalKeyboardKey.mediaPause:
        await _controller.runJavaScript("var v = document.querySelector('video'); if(v && !v.paused) v.pause();");
      case LogicalKeyboardKey.mediaStop:
        await _controller.runJavaScript("var v = document.querySelector('video'); if(v) { v.pause(); v.currentTime = 0; }");

      default:
        return;
    }
  }

  /// Check if a modal/dialog is open inside the WebView; close it.
  /// If nothing to close, pop the Flutter route.
  Future<void> _tryCloseModalOrPop() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          // Check common modal patterns
          var selectors = [
            '#server-modal', '.modal', '[class*="modal"]',
            '[class*="overlay"]', '[class*="dialog"]', '[class*="popup"]',
            '[class*="settings-panel"]', '[class*="menu"]'
          ];
          for (var i = 0; i < selectors.length; i++) {
            var els = document.querySelectorAll(selectors[i]);
            for (var j = 0; j < els.length; j++) {
              var style = window.getComputedStyle(els[j]);
              if (style.display !== 'none' && style.visibility !== 'hidden') {
                els[j].style.display = 'none';
                return true;
              }
            }
          }
          return false;
        })();
      ''');

      final wasOpen = result == true || result == 1;
      if (!wasOpen && mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Key event handler
  // ──────────────────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    _dispatchKeyToWebView(event.logicalKey);
    return KeyEventResult.handled;
  }

  // ──────────────────────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: [
              if (_embedUrl.isNotEmpty)
                WebViewWidget(controller: _controller),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),

              // Top bar with back + title
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    TvFocusWrapper(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    if (_title.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
