import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/ad_blocker.dart';
import '../services/vidnest_service.dart';
import '../services/embed_service.dart';
import '../widgets/tv_focus_wrapper.dart';
import '../widgets/tv_server_switcher_modal.dart';
import '../widgets/web_iframe.dart';
import '../config/tv_layout.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  final FocusNode _tvInputFocusNode = FocusNode();

  String _embedUrl = '';
  String _title = '';
  dynamic _mediaId;
  String _mediaType = 'movie';
  int _season = 1;
  int _episode = 1;

  String _activeProviderId = 'vidnest';
  String _activeServerId = 'lamda';
  String? _animeFallbackUrl;
  String _animeProvider = 'MegaPlay';
  int _lastPlaybackSeconds = 0;

  bool _isLoading = true;
  bool _initialized = false;
  bool _showServerModal = false;

  String? _hudBadgeText;
  IconData? _hudBadgeIcon;
  Timer? _hudTimer;
  Timer? _loadingTimeoutTimer;

  void _disableAndroidPopups(AndroidWebViewController controller) {
    // Suppress native JS dialogs for all frames (including cross-origin
    // subframes).  The Vidnest gate uses window.confirm in a subframe;
    // setOnJavaScriptConfirmDialog calls setSynchronousReturnValueForOnJsConfirm
    // internally, which intercepts at the native level for every frame.
    controller.setOnJavaScriptConfirmDialog((request) async {
      if (AdBlocker.isGateMessage(request.message)) {
        debugPrint('[AdBlock] Auto-confirmed gate dialog: ${request.message}');
        return true;
      }
      debugPrint('[AdBlock] Swallowed JS confirm: ${request.message}');
      return false;
    });

    controller.setOnJavaScriptAlertDialog((request) async {
      debugPrint('[AdBlock] Swallowed JS alert: ${request.message}');
    });

    controller.setOnJavaScriptTextInputDialog((request) async {
      debugPrint('[AdBlock] Swallowed JS prompt: ${request.message}');
      return '';
    });
  }

  void _startLoadingSafetyTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _mediaId = args['mediaId'];
        _mediaType = (args['mediaType'] ?? 'movie').toString().toLowerCase();
        _season = args['season'] is int ? args['season'] : 1;
        _episode = args['episode'] is int ? args['episode'] : 1;
        _title = args['title'] ?? 'Streaming Player';
        _animeFallbackUrl = args['fallbackEmbedUrl'] as String?;

        final providedUrl = args['embedUrl'] as String?;
        if (providedUrl != null && providedUrl.isNotEmpty) {
          _embedUrl = providedUrl;
          if (_mediaType == 'anime' && providedUrl.contains('vidnest.fun')) {
            _animeProvider = 'Vidnest';
          }
        } else if (_mediaId != null) {
          _embedUrl = _buildTargetUrl(serverId: _activeServerId, startAt: 0);
        } else {
          _embedUrl = 'https://vidnest.fun/movie/324857';
        }

        if (!kIsWeb) {
          unawaited(_initWebView());
        } else {
          _isLoading = false;
        }
        _startLoadingSafetyTimeout();
        _initialized = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tvInputFocusNode.requestFocus();
        });
      } else {
        _embedUrl = 'https://vidnest.fun/movie/324857';
        if (!kIsWeb) {
          unawaited(_initWebView());
        } else {
          _isLoading = false;
        }
        _startLoadingSafetyTimeout();
        _initialized = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tvInputFocusNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKeyEvent);
    _loadingTimeoutTimer?.cancel();
    _hudTimer?.cancel();
    _tvInputFocusNode.dispose();
    super.dispose();
  }

  String _buildTargetUrl({
    String? providerId,
    String? serverId,
    int startAt = 0,
  }) {
    final effectiveProvider = providerId ?? _activeProviderId;
    final effectiveServer = serverId ?? _activeServerId;

    if (_mediaType == 'tv') {
      return EmbedService.getTvUrl(
        _mediaId,
        _season,
        _episode,
        provider: effectiveProvider,
        server: effectiveServer,
        startAt: startAt,
      );
    } else if (_mediaType == 'anime') {
      return EmbedService.getAnimeUrl(
        _mediaId,
        _season,
        _episode,
        provider: effectiveProvider,
        server: effectiveServer,
        startAt: startAt,
      );
    } else {
      return EmbedService.getMovieUrl(
        _mediaId ?? '324857',
        provider: effectiveProvider,
        server: effectiveServer,
        startAt: startAt,
      );
    }
  }

  Map<String, String> _embedRequestHeaders() {
    final host = Uri.tryParse(_embedUrl)?.host.toLowerCase() ?? '';
    if (host.endsWith('vidsrc.sbs')) {
      return const {'Referer': 'https://vidsrc.sbs/'};
    }
    if (host.endsWith('megaplay.buzz')) {
      return const {'Referer': 'https://megaplay.buzz/'};
    }
    return const {'Referer': 'https://vidnest.fun/'};
  }

  Future<void> _attachNativeResourceBlocker(
    AndroidWebViewController controller,
  ) async {
    try {
      await const MethodChannel('com.streamflix.streamflix_tv/ad_blocker')
          .invokeMethod<void>('attachResourceBlocker', controller.webViewIdentifier);
    } catch (error) {
      debugPrint('[AdBlock] Native resource blocker unavailable: $error');
    }
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(Colors.black);

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      _disableAndroidPopups(platform);
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnPlatformPermissionRequest((request) => request.grant());
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
      // Android WebView rejects third-party cookies by default. Keep that
      // default instead of creating a version-specific cookie manager.
      platform.setOnConsoleMessage((message) {
        debugPrint('[Vidnest Console] ${message.message}');
      });
    }

    await _controller.setNavigationDelegate(
      NavigationDelegate(
          onPageStarted: (String url) async {
            // Install popup blocking as early as WebView exposes the document.
            try {
              await _controller.runJavaScript(AdBlocker.adBlockScript);
            } catch (_) {}
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[WebView Resource Error] ${error.description} for ${error.url}',
            );
            if (mounted && _isLoading && (error.isForMainFrame ?? true)) {
              _showHudBadge(
                'Stream error. Press ▲ to switch server',
                Icons.warning_amber_rounded,
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final isAllowed = AdBlocker.shouldAllowNavigation(
              _embedUrl,
              request.url,
            );
            if (!isAllowed) {
              debugPrint(
                '[AdBlock] Blocked navigation attempt to: ${request.url}',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) async {
            try {
              final css = AdBlocker.adBlockCss
                  .replaceAll('\n', ' ')
                  .replaceAll("'", "\\'");
              final injectCssScript =
                  """
                (function() {
                  const style = document.createElement('style');
                  style.innerHTML = '$css';
                  (document.head || document.documentElement).appendChild(style);
                  document.body.classList.add('is-embedded');
                })();
              """;
              await _controller.runJavaScript(injectCssScript);
              await _controller.runJavaScript(AdBlocker.adBlockScript);
            } catch (e) {
              debugPrint('[AdBlock] Failed to inject ad shielding script: $e');
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
      ),
    );
    if (platform is AndroidWebViewController) {
      await _attachNativeResourceBlocker(platform);
    }
    await _controller.loadRequest(
      Uri.parse(_embedUrl),
      headers: _embedRequestHeaders(),
    );
  }

  void _showHudBadge(String text, IconData icon) {
    _hudTimer?.cancel();
    setState(() {
      _hudBadgeText = text;
      _hudBadgeIcon = icon;
    });
    _hudTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _hudBadgeText = null;
          _hudBadgeIcon = null;
        });
      }
    });
  }

  Future<int> _fetchCurrentPlaybackSeconds() async {
    if (kIsWeb) return 0;
    try {
      final jsResult = await _controller.runJavaScriptReturningResult('''
        (function() {
          function findVideo() {
            var v = document.querySelector('video');
            if (v) return v;
            var iframes = document.querySelectorAll('iframe');
            for (var i = 0; i < iframes.length; i++) {
              try {
                var doc = iframes[i].contentDocument || iframes[i].contentWindow.document;
                var iv = doc.querySelector('video');
                if (iv) return iv;
              } catch(e) {}
            }
            return null;
          }
          var v = findVideo();
          return v ? Math.floor(v.currentTime) : 0;
        })();
      ''');
      final parsed = int.tryParse(jsResult.toString());
      return parsed ?? 0;
    } catch (e) {
      debugPrint('Error getting playback time: $e');
      return 0;
    }
  }

  Future<void> _togglePlayPause() async {
    if (kIsWeb) return;
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          try { window.open = function() { return null; }; } catch (e) {}
          document.querySelectorAll(
            '[class*="ad-overlay"],[id*="ad-overlay"],[class*="ad-popup"],[id*="ad-popup"],.popunder,#player-ad-overlay'
          ).forEach(function(el) { if (!el.querySelector('video')) el.remove(); });

          function findVideo() {
            var v = document.querySelector('video');
            if (v) return v;
            var iframes = document.querySelectorAll('iframe');
            for (var i = 0; i < iframes.length; i++) {
              try {
                var doc = iframes[i].contentDocument || iframes[i].contentWindow.document;
                var iv = doc.querySelector('video');
                if (iv) return iv;
              } catch(e) {}
            }
            return null;
          }

          var v = findVideo();
          if (v) {
            if (v.paused) {
              var p = v.play();
              if (p && p.catch) p.catch(function() {});
              return 'playing';
            }
            v.pause();
            return 'paused';
          }

          var playBtn = document.querySelector('button[class*="PlayButton-module"], button[aria-label="Play"], button[aria-label="Pause"], button[data-media-tooltip="play"]');
          if (playBtn) {
            playBtn.click();
            var label = (playBtn.getAttribute('aria-label') || '').toLowerCase();
            return label.includes('pause') ? 'playing' : 'paused';
          }
          return 'novideo';
        })();
      ''');
      final status = result.toString().replaceAll('"', '').trim();
      if (status == 'playing') {
        _showHudBadge('Play', Icons.play_arrow);
      } else if (status == 'paused') {
        _showHudBadge('Pause', Icons.pause);
      }
    } catch (e) {
      debugPrint('Play/Pause error: $e');
    }
  }

  Future<void> _seekRelative(int seconds) async {
    if (kIsWeb) return;
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          function findVideo() {
            var v = document.querySelector('video');
            if (v) return v;
            var iframes = document.querySelectorAll('iframe');
            for (var i = 0; i < iframes.length; i++) {
              try {
                var doc = iframes[i].contentDocument || iframes[i].contentWindow.document;
                var iv = doc.querySelector('video');
                if (iv) return iv;
              } catch(e) {}
            }
            return null;
          }

          var v = findVideo();
          if (v) {
            var targetTime = v.currentTime + ($seconds);
            if ($seconds > 0) {
              v.currentTime = Math.min(v.duration || 999999, targetTime);
            } else {
              v.currentTime = Math.max(0, targetTime);
            }
            return Math.floor(v.currentTime);
          }

          // Fallback: click forward/backward buttons and dispatch keyboard arrows
          if ($seconds > 0) {
            var fwdBtn = document.querySelector('button[class*="SeekForwardButton-module"], button[aria-label*="forward"]');
            if (fwdBtn) fwdBtn.click();
            window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', code: 'ArrowRight', keyCode: 39, which: 39, bubbles: true }));
          } else {
            var backBtn = document.querySelector('button[class*="SeekBackwardButton-module"], button[aria-label*="backward"]');
            if (backBtn) backBtn.click();
            window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', code: 'ArrowLeft', keyCode: 37, which: 37, bubbles: true }));
          }

          return 0;
        })();
      ''');
      final curSec = int.tryParse(result.toString()) ?? 0;
      final timeStr = curSec > 0 ? '  (${_formatDuration(curSec)})' : '';
      if (seconds > 0) {
        _showHudBadge('+$seconds s$timeStr', Icons.fast_forward);
      } else {
        _showHudBadge('$seconds s$timeStr', Icons.fast_rewind);
      }
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Triggers the embed's built-in Server Selection menu (Cloud icon)
  Future<void> triggerEmbedServerMenu() async {
    if (kIsWeb) return;
    try {
      await _controller.runJavaScript('''
        (function() {
          const btn = document.querySelector('button[class*="ServerMenu-module"][class*="menuButton"], button[aria-label="Server Selection"]');
          if (btn) btn.click();
        })();
      ''');
    } catch (e) {
      debugPrint('Server menu trigger error: $e');
    }
  }

  /// Triggers the embed's built-in Captions / Subtitles toggle
  Future<void> triggerEmbedCaptions() async {
    if (kIsWeb) return;
    try {
      await _controller.runJavaScript('''
        (function() {
          const btn = document.querySelector('button[class*="CaptionButton-module"], button[aria-label="Captions"]');
          if (btn) btn.click();
        })();
      ''');
      _showHudBadge('Subtitles Toggled', Icons.subtitles);
    } catch (e) {
      debugPrint('Captions trigger error: $e');
    }
  }

  /// Triggers the embed's built-in Settings menu (Gear icon)
  Future<void> triggerEmbedSettings() async {
    if (kIsWeb) return;
    try {
      await _controller.runJavaScript('''
        (function() {
          const btn = document.querySelector('button[class*="SettingsMenu-module"][class*="menuButton"], button[aria-label="Settings"]');
          if (btn) btn.click();
        })();
      ''');
    } catch (e) {
      debugPrint('Settings trigger error: $e');
    }
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    final h = totalSeconds ~/ 3600;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _onSwitchProvider(EmbedProvider provider) async {
    final currentPos = await _fetchCurrentPlaybackSeconds();
    _lastPlaybackSeconds = currentPos > 0 ? currentPos : _lastPlaybackSeconds;
    _activeProviderId = provider.id;

    final newUrl = _buildTargetUrl(
      providerId: _activeProviderId,
      serverId: _activeServerId,
      startAt: _lastPlaybackSeconds,
    );

    setState(() {
      _showServerModal = false;
      _isLoading = true;
      _embedUrl = newUrl;
    });
    _startLoadingSafetyTimeout();

    _showHudBadge('Switched to ${provider.name}', Icons.cloud_sync);

    if (!kIsWeb) {
      await _controller.loadRequest(
        Uri.parse(_embedUrl),
        headers: _embedRequestHeaders(),
      );
    } else {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) {
      _tvInputFocusNode.requestFocus();
    }
  }

  Future<void> _onSwitchServer(VidnestServer server) async {
    final currentPos = await _fetchCurrentPlaybackSeconds();
    _lastPlaybackSeconds = currentPos > 0 ? currentPos : _lastPlaybackSeconds;
    _activeProviderId = 'vidnest';
    _activeServerId = server.id;

    final newUrl = _buildTargetUrl(
      providerId: 'vidnest',
      serverId: _activeServerId,
      startAt: _lastPlaybackSeconds,
    );

    setState(() {
      _showServerModal = false;
      _isLoading = true;
      _embedUrl = newUrl;
    });
    _startLoadingSafetyTimeout();

    _showHudBadge(
      'Switched to ${server.name} (${_formatDuration(_lastPlaybackSeconds)})',
      Icons.dns,
    );

    if (!kIsWeb) {
      await _controller.loadRequest(
        Uri.parse(_embedUrl),
        headers: _embedRequestHeaders(),
      );
    } else {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) {
      _tvInputFocusNode.requestFocus();
    }
  }

  Future<void> _switchAnimeProvider() async {
    final fallbackUrl = _animeFallbackUrl;
    if (fallbackUrl == null || fallbackUrl.isEmpty) return;

    final currentUrl = _embedUrl;
    setState(() {
      _embedUrl = fallbackUrl;
      _animeFallbackUrl = currentUrl;
      _animeProvider = _animeProvider == 'MegaPlay' ? 'Vidnest' : 'MegaPlay';
      _isLoading = true;
    });
    _startLoadingSafetyTimeout();
    _showHudBadge('Switched to $_animeProvider', Icons.swap_horiz);

    if (!kIsWeb) {
      await _controller.loadRequest(
        Uri.parse(_embedUrl),
        headers: _embedRequestHeaders(),
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final key = event.logicalKey;

    if (_showServerModal) {
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.goBack) {
        setState(() => _showServerModal = false);
        _tvInputFocusNode.requestFocus();
        return true;
      }
      return false; // Allow modal's own FocusScope to receive navigation keys
    }

    // Dismiss or Back
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack) {
      if (mounted) Navigator.pop(context);
      return true;
    }

    // Toggle Server Switcher
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.contextMenu) {
      setState(() => _showServerModal = true);
      return true;
    }

    // Play / Pause
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      _togglePlayPause();
      return true;
    }

    // Seek Left (-10s)
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaRewind) {
      _seekRelative(-10);
      return true;
    }

    // Seek Right (+10s)
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaFastForward) {
      _seekRelative(10);
      return true;
    }

    return false;
  }

  KeyEventResult _handleTvKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Dismiss or Back
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack) {
      if (_showServerModal) {
        setState(() => _showServerModal = false);
        _tvInputFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored; // Let PopScope handle exit
    }

    if (_showServerModal) {
      return KeyEventResult.ignored; // Let Modal FocusScope handle
    }

    // Toggle Server Switcher
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.contextMenu) {
      setState(() => _showServerModal = true);
      return KeyEventResult.handled;
    }

    // Play / Pause
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }

    // Seek Left (-10s)
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaRewind) {
      _seekRelative(-10);
      return KeyEventResult.handled;
    }

    // Seek Right (+10s)
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaFastForward) {
      _seekRelative(10);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showServerModal,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showServerModal) {
          setState(() => _showServerModal = false);
          _tvInputFocusNode.requestFocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
            children: [
              // 1. Embedded Video Player (Native Android WebView or Web IFrame)
              if (_embedUrl.isNotEmpty)
                Positioned.fill(
                  child: kIsWeb
                      ? buildPlatformEmbedView(
                          embedUrl: _embedUrl,
                          title: _title,
                          fallbackLabel: _mediaType == 'anime'
                              ? null
                              : (_activeProviderId == 'vidnest'
                                    ? 'Try VidSrc'
                                    : 'Use Vidnest'),
                          onFallback: _mediaType == 'anime'
                              ? null
                              : () => _onSwitchProvider(
                                  EmbedService.findProvider(
                                    _activeProviderId == 'vidnest'
                                        ? 'vidsrc'
                                        : 'vidnest',
                                  ),
                                ),
                          onLoaded: () {
                            if (mounted) setState(() => _isLoading = false);
                          },
                        )
                      : Focus(
                          canRequestFocus: false,
                          descendantsAreFocusable: false,
                          skipTraversal: true,
                          child: WebViewWidget(controller: _controller),
                        ),
                ),

              // 1b. Transparent D-Pad input overlay — intercepts key events
              // before the native Android WebView platform view can consume
              // them, so arrow-key seek and play/pause work on TV remotes.
              if (!kIsWeb)
                Positioned.fill(
                  child: Focus(
                    focusNode: _tvInputFocusNode,
                    autofocus: true,
                    onKeyEvent: _handleTvKeyEvent,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

              // 2. Loading Indicator
              if (_isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.blueAccent),
                            SizedBox(height: 16),
                            Text(
                              'Connecting to Vidnest Stream...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Top Navigation & Info Bar
              if (!kIsWeb)
                Positioned(
                  // Keep controls clear of the browser/app chrome and the
                  // embedded player's top-edge gesture area.
                  top: TvLayout.headerTopInset(context) + 24,
                  left: TvLayout.horizontalInset(context),
                  right: TvLayout.horizontalInset(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TvFocusWrapper(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          if (_title.isNotEmpty) ...[
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_mediaType != 'anime')
                            TvFocusWrapper(
                              onTap: () => _onSwitchProvider(
                                EmbedService.findProvider(
                                  _activeProviderId == 'vidnest'
                                      ? 'vidsrc'
                                      : 'vidnest',
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE50914,
                                  ).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  _activeProviderId == 'vidnest'
                                      ? 'Try VidSrc'
                                      : 'Use Vidnest',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_mediaType != 'anime') const SizedBox(width: 12),
                          if (_mediaType == 'anime' && _animeFallbackUrl != null)
                            TvFocusWrapper(
                              onTap: _switchAnimeProvider,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  'Use ${_animeProvider == 'MegaPlay' ? 'Vidnest' : 'MegaPlay'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_mediaType == 'anime' && _animeFallbackUrl != null)
                            const SizedBox(width: 12),
                          // Server switching applies only to Vidnest.
                          if (_activeProviderId == 'vidnest')
                            TvFocusWrapper(
                              onTap: () =>
                                  setState(() => _showServerModal = true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE50914,
                                  ).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE50914,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.dns,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Server: ${VidnestService.findServer(_activeServerId).name} (Up)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              // 4. Center On-Screen Feedback HUD (Auto-Hides)
              if (_hudBadgeText != null)
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hudBadgeText != null ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white24, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hudBadgeIcon != null) ...[
                            Icon(
                              _hudBadgeIcon,
                              color: const Color(0xFFE50914),
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                          ],
                          Text(
                            _hudBadgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. TV Server Switcher Overlay Modal (D-Pad UP or Menu)
              if (_showServerModal)
                TvServerSwitcherModal(
                  activeServerId: _activeServerId,
                  activeProviderId: _activeProviderId,
                  onServerSelected: _onSwitchServer,
                  onProviderSelected: _onSwitchProvider,
                  onDismiss: () {
                    setState(() => _showServerModal = false);
                    _tvInputFocusNode.requestFocus();
                  },
                ),
            ],
          ),
        ),
      );
  }
}
