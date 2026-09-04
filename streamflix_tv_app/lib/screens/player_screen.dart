import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/ad_blocker.dart';
import '../services/vidnest_service.dart';
import '../services/embed_service.dart';
import '../widgets/tv_focus_wrapper.dart';
import '../widgets/tv_server_switcher_modal.dart';

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
  int _lastPlaybackSeconds = 0;

  bool _isLoading = true;
  bool _initialized = false;
  bool _showServerModal = false;

  String? _hudBadgeText;
  IconData? _hudBadgeIcon;
  Timer? _hudTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _mediaId = args['mediaId'];
        _mediaType = (args['mediaType'] ?? 'movie').toString().toLowerCase();
        _season = args['season'] is int ? args['season'] : 1;
        _episode = args['episode'] is int ? args['episode'] : 1;
        _title = args['title'] ?? 'Streaming Player';

        final providedUrl = args['embedUrl'] as String?;
        if (providedUrl != null && providedUrl.isNotEmpty) {
          _embedUrl = providedUrl;
        } else if (_mediaId != null) {
          _embedUrl = _buildTargetUrl(serverId: _activeServerId, startAt: 0);
        } else {
          _embedUrl = 'https://vidnest.fun/movie/324857';
        }

        _initWebView();
        _initialized = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tvInputFocusNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    _tvInputFocusNode.dispose();
    super.dispose();
  }

  String _buildTargetUrl({String? providerId, String? serverId, int startAt = 0}) {
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

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(Colors.black);

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnPlatformPermissionRequest((request) => request.grant());
      platform.setMixedContentMode(MixedContentMode.alwaysAllow);
      platform.setOnConsoleMessage((message) {
        debugPrint('[Vidnest Console] ${message.message}');
      });
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('[WebView Resource Error] ${error.description} for ${error.url}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final isAllowed = AdBlocker.shouldAllowNavigation(_embedUrl, request.url);
            if (!isAllowed) {
              debugPrint('[AdBlock] Blocked navigation attempt to: ${request.url}');
              return NavigationDecision.prevent;
            }
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
      )
      ..loadRequest(
        Uri.parse(_embedUrl),
        headers: {
          'Referer': 'https://vidnest.fun/',
        },
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
    try {
      final jsResult = await _controller.runJavaScriptReturningResult('''
        (function() {
          const v = document.querySelector('video');
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
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          // 1. First attempt to click the exact Vidnest Play/Pause button
          const playBtn = document.querySelector('button[class*="PlayButton-module"], button[aria-label="Play"], button[aria-label="Pause"], button[data-media-tooltip="play"]');
          if (playBtn) {
            playBtn.click();
            const v = document.querySelector('video');
            if (v) return v.paused ? 'paused' : 'playing';
            const label = playBtn.getAttribute('aria-label') || '';
            return label.toLowerCase().includes('pause') ? 'playing' : 'paused';
          }

          // 2. Direct HTML5 video fallback
          const v = document.querySelector('video');
          if (!v) return 'novideo';
          if (v.paused) {
            v.play();
            return 'playing';
          } else {
            v.pause();
            return 'paused';
          }
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
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          if ($seconds > 0) {
            // Trigger Vidnest Forward +10s button
            const fwdBtn = document.querySelector('button[class*="SeekForwardButton-module"], button[aria-label*="forward"]');
            if (fwdBtn) {
              fwdBtn.click();
            } else {
              const v = document.querySelector('video');
              if (v) v.currentTime = Math.min(v.duration || 99999, v.currentTime + ($seconds));
            }
          } else {
            // Trigger Vidnest Backward -10s button
            const backBtn = document.querySelector('button[class*="SeekBackwardButton-module"], button[aria-label*="backward"]');
            if (backBtn) {
              backBtn.click();
            } else {
              const v = document.querySelector('video');
              if (v) v.currentTime = Math.max(0, v.currentTime + ($seconds));
            }
          }

          const v = document.querySelector('video');
          return v ? Math.floor(v.currentTime) : 0;
        })();
      ''');
      final curSec = int.tryParse(result.toString()) ?? 0;
      final timeStr = _formatDuration(curSec);
      if (seconds > 0) {
        _showHudBadge('+$seconds s  ($timeStr)', Icons.fast_forward);
      } else {
        _showHudBadge('$seconds s  ($timeStr)', Icons.fast_rewind);
      }
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Triggers the embed's built-in Server Selection menu (Cloud icon)
  Future<void> triggerEmbedServerMenu() async {
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

    _showHudBadge('Switched to ${provider.name}', Icons.cloud_sync);

    await _controller.loadRequest(
      Uri.parse(_embedUrl),
      headers: {'Referer': 'https://vidnest.fun/'},
    );

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

    _showHudBadge('Switched to ${server.name} (${_formatDuration(_lastPlaybackSeconds)})', Icons.dns);

    await _controller.loadRequest(
      Uri.parse(_embedUrl),
      headers: {'Referer': 'https://vidnest.fun/'},
    );

    if (mounted) {
      _tvInputFocusNode.requestFocus();
    }
  }

  KeyEventResult _handleTvKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
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
        body: Focus(
          focusNode: _tvInputFocusNode,
          autofocus: true,
          onKeyEvent: _handleTvKeyEvent,
          child: Stack(
            children: [
              // 1. Embedded Video WebView
              if (_embedUrl.isNotEmpty)
                WebViewWidget(controller: _controller),

              // 2. Loading Indicator
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.blueAccent),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to Vidnest Stream...',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Top Navigation & Info Bar
              Positioned(
                top: 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TvFocusWrapper(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                          ),
                        ),
                        if (_title.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    // Server Quick Switch Button
                    TvFocusWrapper(
                      onTap: () => setState(() => _showServerModal = true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_sync, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Source: ${EmbedService.findProvider(_activeProviderId).name}${_activeProviderId == "vidnest" ? " • ${VidnestService.findServer(_activeServerId).name}" : ""} (▲)',
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
              ),

              // 4. Center On-Screen Feedback HUD (Auto-Hides)
              if (_hudBadgeText != null)
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hudBadgeText != null ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                            Icon(_hudBadgeIcon, color: const Color(0xFFE50914), size: 32),
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
      ),
    );
  }
}
