import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:streamflix_tv/config/api_config.dart';
import 'package:streamflix_tv/services/subtitle_parser.dart';
import 'package:streamflix_tv/widgets/subtitle_overlay.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

// ─── Stream model ──────────────────────────────────────────────
class _StreamSource {
  final int id;
  final String source;
  final String server;
  final String label;
  final String url;

  const _StreamSource({
    required this.id,
    required this.source,
    required this.server,
    required this.label,
    required this.url,
  });

  factory _StreamSource.fromJson(Map<String, dynamic> json) => _StreamSource(
        id: json['id'] ?? 0,
        source: json['source'] ?? 'Extension',
        server: json['server'] ?? 'Server',
        label: json['label'] ?? 'HD',
        url: json['url'] ?? '',
      );
}

// ─── Main Player Screen ────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // ── State ─────────────────────────────────────────────────────
  VideoPlayerController? _controller;
  List<_StreamSource> _streams = [];
  List<String> _backupEmbeds = [];
  int _currentStreamIndex = 0;
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _initialized = false;

  // ── Controls visibility ───────────────────────────────────────
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _progressTimer;

  // ── Passed args ───────────────────────────────────────────────
  String _embedUrl = '';
  String _title = '';
  dynamic _mediaId;
  String _mediaType = 'movie';
  int _season = 1;
  int _episode = 1;

  // ── Subtitles ────────────────────────────────────────────────
  List<SubtitleTrack> _subtitleTracks = [];
  int _selectedSubtitleIndex = -1; // -1 = off
  SubtitleCue? _activeCue;

  // ── Feedback overlay ──────────────────────────────────────────
  String _feedbackText = '';
  IconData? _feedbackIcon;
  bool _showFeedback = false;
  Timer? _feedbackTimer;

  // ── Focus ─────────────────────────────────────────────────────
  final FocusNode _focusNode = FocusNode();

  // ── Dio for API calls ─────────────────────────────────────────
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ──────────────────────────────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _embedUrl = args['embedUrl'] ?? '';
        _title = args['title'] ?? 'Player';
        _mediaId = args['mediaId'];
        _mediaType = args['mediaType'] ?? 'movie';
        _season = args['season'] ?? 1;
        _episode = args['episode'] ?? 1;
        _initialized = true;
        _fetchStreams();
      }
    }
  }

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
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _feedbackTimer?.cancel();
    _controller?.dispose();
    _focusNode.dispose();
    _dio.close(force: true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  // ── Subtitle helpers ─────────────────────────────────────────

  void _onPositionUpdate() {
    if (!mounted || _controller == null || _selectedSubtitleIndex < 0) return;
    final track = _subtitleTracks[_selectedSubtitleIndex];
    final pos = _controller!.value.position;
    final cue = track.getActiveCue(pos);
    if (cue != _activeCue) {
      setState(() => _activeCue = cue);
    }
  }

  Future<void> _fetchSubtitles(String streamUrl) async {
    try {
      final url = ApiConfig.subtitles(streamUrl);
      final response = await _dio.get<dynamic>(url);
      final data = response.data as Map<String, dynamic>;
      final tracks = (data['subtitles'] as List<dynamic>?)
              ?.map((s) => SubtitleTrack.fromApiJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      if (!mounted) return;
      setState(() {
        _subtitleTracks = tracks;
        _selectedSubtitleIndex = -1;
        _activeCue = null;
      });

      // Auto-select default track if available
      final defaultIdx = tracks.indexWhere((t) => t.isDefault);
      if (defaultIdx >= 0) {
        await _loadSubtitleTrack(defaultIdx);
      }
    } catch (e) {
      debugPrint('[Player] Subtitle fetch failed: $e');
    }
  }

  Future<void> _loadSubtitleTrack(int index) async {
    if (index < -1 || index >= _subtitleTracks.length) return;
    if (index == _selectedSubtitleIndex) return;

    if (index == -1) {
      setState(() {
        _selectedSubtitleIndex = -1;
        _activeCue = null;
      });
      return;
    }

    final track = _subtitleTracks[index];

    // Fetch and parse VTT content if cues haven't been loaded yet
    if (track.cues.isEmpty && track.url.isNotEmpty) {
      try {
        final response = await _dio.get<dynamic>(track.url);
        final vttContent = response.data.toString();
        final cues = parseVtt(vttContent);

        if (!mounted) return;
        // Create a copy with parsed cues
        final updatedTrack = SubtitleTrack(
          name: track.name,
          language: track.language,
          url: track.url,
          isDefault: track.isDefault,
          cues: cues,
        );
        setState(() {
          _subtitleTracks[index] = updatedTrack;
          _selectedSubtitleIndex = index;
          _activeCue = null;
        });
      } catch (e) {
        debugPrint('[Player] Failed to load subtitle track: $e');
      }
    } else {
      setState(() {
        _selectedSubtitleIndex = index;
        _activeCue = null;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Data fetching
  // ──────────────────────────────────────────────────────────────

  String _buildStreamsUrl() {
    if (_mediaType == 'anime') {
      return ApiConfig.animeStreams(_mediaId, _season, _episode);
    } else if (_mediaType == 'tv') {
      return ApiConfig.tvStreams(_mediaId, _season, _episode);
    } else {
      return ApiConfig.movieStreams(_mediaId);
    }
  }

  Future<void> _fetchStreams() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = _buildStreamsUrl();
      debugPrint('[Player] Fetching streams: $url');
      final response = await _dio.get<dynamic>(url);
      final data = response.data as Map<String, dynamic>;

      final streamsList = (data['streams'] as List<dynamic>?)
              ?.map((s) =>
                  _StreamSource.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];
      final backups = (data['backupEmbeds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _streams = streamsList;
        _backupEmbeds = backups;
      });

      if (_streams.isNotEmpty) {
        await _playStream(0);
      } else if (_backupEmbeds.isNotEmpty) {
        _loadBackupEmbed(_backupEmbeds.first);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No streams available';
        });
      }
    } catch (e) {
      debugPrint('[Player] Stream fetch error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load streams';
      });
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Playback
  // ──────────────────────────────────────────────────────────────

  Future<void> _playStream(int index) async {
    if (index < 0 || index >= _streams.length) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentStreamIndex = index;
      _isBuffering = true;
    });

    final stream = _streams[index];

    // Dispose old controller
    await _controller?.dispose();

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(stream.url));

      controller.addListener(_videoListener);
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isLoading = false;
        _isBuffering = false;
      });

      await controller.play();
      _startHideTimer();
      _startProgressTimer();

      // Fetch subtitle tracks for this stream
      _fetchSubtitles(stream.url);
    } catch (e) {
      debugPrint('[Player] Playback error for stream ${index}: $e');
      // Try next stream
      if (index + 1 < _streams.length) {
        await _playStream(index + 1);
      } else if (_backupEmbeds.isNotEmpty) {
        _loadBackupEmbed(_backupEmbeds.first);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Playback failed';
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final controller = _controller!;

    if (controller.value.hasError) {
      debugPrint('[Player] Video error: ${controller.value.errorDescription}');
      // Try next stream on error
      if (_currentStreamIndex + 1 < _streams.length) {
        _playStream(_currentStreamIndex + 1);
      }
    }

    // Check for buffering
    final isNowBuffering =
        controller.value.isBuffering || controller.value.duration == Duration.zero;
    if (isNowBuffering != _isBuffering) {
      setState(() => _isBuffering = isNowBuffering);
    }
  }

  void _loadBackupEmbed(String url) {
    // For backup embeds, fall back to WebView mode
    setState(() {
      _isLoading = false;
      _hasError = false;
    });

    // Navigate to WebView fallback player
    Navigator.pushReplacementNamed(
      context,
      '/player_webview',
      arguments: {
        'embedUrl': url,
        'title': _title,
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  Controls
  // ──────────────────────────────────────────────────────────────

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _showFeedbackOverlay(Icons.pause, null);
    } else {
      _controller!.play();
      _showFeedbackOverlay(Icons.play_arrow, null);
    }
    _showControlsTemporarily();
  }

  void _seekRelative(Duration offset) {
    if (_controller == null) return;
    final newPos = _controller!.value.position + offset;
    final clamped = newPos.isNegative
        ? Duration.zero
        : (newPos > _controller!.value.duration
            ? _controller!.value.duration
            : newPos);
    _controller!.seekTo(clamped);

    final seconds = offset.inSeconds;
    final label = seconds > 0 ? '+${seconds}s' : '${seconds}s';
    _showFeedbackOverlay(null, label);
    _showControlsTemporarily();
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
    _showControlsTemporarily();
  }

  // ── Feedback overlay ──────────────────────────────────────────

  void _showFeedbackOverlay(IconData? icon, String? text) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackIcon = icon;
      _feedbackText = text ?? '';
      _showFeedback = true;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  // ── Controls visibility ───────────────────────────────────────

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() {});
        _onPositionUpdate();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────
  //  Keyboard / D-pad
  // ──────────────────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Play / Pause
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }

    // Seek ±10s
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekRelative(const Duration(seconds: 10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekRelative(const Duration(seconds: -10));
      return KeyEventResult.handled;
    }

    // Volume feedback
    if (key == LogicalKeyboardKey.arrowUp) {
      _showFeedbackOverlay(Icons.volume_up, null);
      _showControlsTemporarily();
      return KeyEventResult.ignored; // Let system handle volume
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _showFeedbackOverlay(Icons.volume_down, null);
      _showControlsTemporarily();
      return KeyEventResult.ignored;
    }

    // Back
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ──────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
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
          child: GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: _togglePlayPause,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Video ──────────────────────────────────
                _buildVideo(),

                // ── Buffering spinner ──────────────────────
                if (_isBuffering && !_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 3,
                    ),
                  ),

                // ── Loading state ──────────────────────────
                if (_isLoading) _buildLoadingScreen(),

                // ── Error state ────────────────────────────
                if (_hasError) _buildErrorScreen(),

                // ── Controls overlay ───────────────────────
                if (_showControls && !_isLoading && !_hasError)
                  _buildControlsOverlay(),

                // ── Subtitles ──────────────────────────────
                SubtitleOverlay(activeCue: _activeCue),

                // ── Seek / volume feedback ─────────────────
                if (_showFeedback) _buildFeedbackOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Video widget ────────────────────────────────────────────
  Widget _buildVideo() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  // ── Loading screen ──────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_streams.isNotEmpty)
              Text(
                'Connecting to ${_streams[_currentStreamIndex.clamp(0, _streams.length - 1)].source}...',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ── Error screen ────────────────────────────────────────────
  Widget _buildErrorScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),
            TvFocusWrapper(
              onTap: _fetchStreams,
              autofocus: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feedback overlay (center icon/text) ─────────────────────
  Widget _buildFeedbackOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _showFeedback ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(40),
          ),
          child: _feedbackIcon != null
              ? Icon(_feedbackIcon, color: Colors.white, size: 40)
              : Center(
                  child: Text(
                    _feedbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Main controls overlay ───────────────────────────────────
  Widget _buildControlsOverlay() {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;
    final isPlaying = _controller?.value.isPlaying ?? false;

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.transparent,
              Colors.black87,
            ],
            stops: [0.0, 0.2, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────
              _buildTopBar(),
              const Spacer(),
              // ── Center play button ──────────────────────
              _buildCenterPlayButton(isPlaying),
              const Spacer(),
              // ── Bottom bar ──────────────────────────────
              _buildBottomBar(position, duration, isPlaying),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back button
          TvFocusWrapper(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Source badge
          if (_streams.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '${_streams[_currentStreamIndex.clamp(0, _streams.length - 1)].source} • ${_streams[_currentStreamIndex.clamp(0, _streams.length - 1)].label}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // Server selector button
          if (_streams.length > 1) ...[
            const SizedBox(width: 12),
            TvFocusWrapper(
              onTap: _showServerSelector,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dns, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Servers',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Center play/pause ──────────────────────────────────────
  Widget _buildCenterPlayButton(bool isPlaying) {
    return TvFocusWrapper(
      onTap: _togglePlayPause,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────
  Widget _buildBottomBar(Duration position, Duration duration, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          // ── Progress bar ─────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.blueAccent,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 3,
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, duration.inMilliseconds.toDouble())
                  : 0.0,
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (value) {
                _seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          // ── Time labels + controls row ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Current time
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                // Rewind 10s
                TvFocusWrapper(
                  onTap: () => _seekRelative(const Duration(seconds: -10)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.replay_10,
                        color: Colors.white70, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                // Play / Pause
                TvFocusWrapper(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Forward 10s
                TvFocusWrapper(
                  onTap: () => _seekRelative(const Duration(seconds: 10)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.forward_10,
                        color: Colors.white70, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                // Duration
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                // Subtitle toggle
                TvFocusWrapper(
                  onTap: _showSubtitleSelector,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _selectedSubtitleIndex >= 0
                          ? Colors.blueAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.subtitles,
                      color: _selectedSubtitleIndex >= 0
                          ? Colors.blueAccent
                          : Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Fullscreen hint
                const Icon(Icons.fullscreen, color: Colors.white38, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Subtitle selector modal ────────────────────────────────
  void _showSubtitleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubtitleSelectorSheet(
        tracks: _subtitleTracks,
        currentIndex: _selectedSubtitleIndex,
        onSelect: (index) {
          Navigator.pop(context);
          _loadSubtitleTrack(index);
        },
      ),
    );
  }

  // ── Server selector modal ───────────────────────────────────
  void _showServerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServerSelectorSheet(
        streams: _streams,
        currentIndex: _currentStreamIndex,
        onSelect: (index) {
          Navigator.pop(context);
          _playStream(index);
        },
      ),
    );
  }
}

// ─── Server Selector Bottom Sheet (D-pad navigable) ──────────
class _ServerSelectorSheet extends StatefulWidget {
  final List<_StreamSource> streams;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ServerSelectorSheet({
    required this.streams,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  State<_ServerSelectorSheet> createState() => _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends State<_ServerSelectorSheet> {
  final FocusNode _sheetFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;
  final List<FocusNode> _itemFocusNodes = [];

  @override
  void initState() {
    super.initState();
    // Start focus on the currently active stream, or the first one
    _focusedIndex = widget.currentIndex.clamp(0, widget.streams.length - 1);
    for (int i = 0; i < widget.streams.length; i++) {
      _itemFocusNodes.add(FocusNode());
    }
    // Auto-focus the active item after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusedIndex < _itemFocusNodes.length) {
        _itemFocusNodes[_focusedIndex].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _sheetFocus.dispose();
    _scrollController.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int direction) {
    final newIndex = (_focusedIndex + direction).clamp(0, widget.streams.length - 1);
    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _itemFocusNodes[newIndex].requestFocus();
      // Scroll into view
      _scrollController.animateTo(
        newIndex * 88.0, // approximate item height
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Down → next item
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    // Up → previous item
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    // Left/Right → also move through items (TV remaps these)
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _moveFocus(key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      return KeyEventResult.handled;
    }
    // Enter/OK/Select → pick this stream
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onSelect(_focusedIndex);
      return KeyEventResult.handled;
    }
    // Back/Escape → dismiss
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled; // Consume all other keys in the sheet
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _sheetFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF12131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Stream Sources',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Use ↑↓ to navigate, OK to select',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.streams.length,
                itemBuilder: (context, index) {
                  final stream = widget.streams[index];
                  final isActive = index == widget.currentIndex;
                  final isFocused = index == _focusedIndex;
                  return Focus(
                    focusNode: _itemFocusNodes[index],
                    child: GestureDetector(
                      onTap: () => widget.onSelect(index),
                      child: AnimatedScale(
                        scale: isFocused ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : isFocused
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? Colors.blueAccent
                                  : isFocused
                                      ? Colors.blueAccent.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.1),
                              width: isActive || isFocused ? 2 : 1,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.radio_button_checked
                                    : isFocused
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                color: isActive
                                    ? Colors.blueAccent
                                    : isFocused
                                        ? Colors.blueAccent.withValues(alpha: 0.7)
                                        : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stream.server,
                                      style: TextStyle(
                                        color: isActive || isFocused
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stream.source,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.blueAccent
                                            : Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stream.label,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Subtitle Selector Bottom Sheet (D-pad navigable) ───────
class _SubtitleSelectorSheet extends StatefulWidget {
  final List<SubtitleTrack> tracks;
  final int currentIndex; // -1 = off
  final ValueChanged<int> onSelect;

  const _SubtitleSelectorSheet({
    required this.tracks,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  State<_SubtitleSelectorSheet> createState() => _SubtitleSelectorSheetState();
}

class _SubtitleSelectorSheetState extends State<_SubtitleSelectorSheet> {
  final FocusNode _sheetFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late int _focusedIndex; // 0 = Off, 1..n = track index
  final List<FocusNode> _itemFocusNodes = [];

  int get _itemCount => widget.tracks.length + 1; // +1 for "Off"

  @override
  void initState() {
    super.initState();
    // Map currentIndex: -1 → 0 (Off), else index + 1
    _focusedIndex = widget.currentIndex < 0 ? 0 : widget.currentIndex + 1;
    for (int i = 0; i < _itemCount; i++) {
      _itemFocusNodes.add(FocusNode());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusedIndex < _itemFocusNodes.length) {
        _itemFocusNodes[_focusedIndex].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _sheetFocus.dispose();
    _scrollController.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int direction) {
    final newIndex = (_focusedIndex + direction).clamp(0, _itemCount - 1);
    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      _itemFocusNodes[newIndex].requestFocus();
      _scrollController.animateTo(
        newIndex * 80.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _moveFocus(key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.numpadEnter) {
      // 0 → off (-1), 1..n → track index
      final selected = _focusedIndex == 0 ? -1 : _focusedIndex - 1;
      widget.onSelect(selected);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _sheetFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF12131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Subtitles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Use ↑↓ to navigate, OK to select',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _itemCount,
                itemBuilder: (context, index) {
                  final isOff = index == 0;
                  final trackIndex = index - 1;
                  final track = !isOff ? widget.tracks[trackIndex] : null;
                  final isActive = index == (widget.currentIndex < 0 ? 0 : widget.currentIndex + 1);
                  final isFocused = index == _focusedIndex;

                  final label = isOff ? 'Off' : '${track!.name} (${track.language})';
                  final subtitle = isOff ? 'No subtitles' : '${track!.cues.isNotEmpty ? '${track.cues.length} cues' : 'Tap to load'}';

                  return Focus(
                    focusNode: _itemFocusNodes[index],
                    child: GestureDetector(
                      onTap: () {
                        final selected = index == 0 ? -1 : index - 1;
                        widget.onSelect(selected);
                      },
                      child: AnimatedScale(
                        scale: isFocused ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : isFocused
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? Colors.blueAccent
                                  : isFocused
                                      ? Colors.blueAccent.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.1),
                              width: isActive || isFocused ? 2 : 1,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.radio_button_checked
                                    : isFocused
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                color: isActive
                                    ? Colors.blueAccent
                                    : isFocused
                                        ? Colors.blueAccent.withValues(alpha: 0.7)
                                        : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isActive || isFocused
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.blueAccent
                                            : Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isOff) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    track!.language.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
