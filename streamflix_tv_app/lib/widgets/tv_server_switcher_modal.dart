import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vidnest_service.dart';
import '../services/embed_service.dart';
import '../config/tv_layout.dart';

class TvServerSwitcherModal extends StatefulWidget {
  final String activeServerId;
  final String activeProviderId;
  final ValueChanged<VidnestServer> onServerSelected;
  final ValueChanged<EmbedProvider>? onProviderSelected;
  final VoidCallback onDismiss;

  const TvServerSwitcherModal({
    super.key,
    required this.activeServerId,
    this.activeProviderId = 'vidnest',
    required this.onServerSelected,
    this.onProviderSelected,
    required this.onDismiss,
  });

  @override
  State<TvServerSwitcherModal> createState() => _TvServerSwitcherModalState();
}

class _TvServerSwitcherModalState extends State<TvServerSwitcherModal> {
  late final List<FocusNode> _serverFocusNodes;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _serverFocusNodes = List.generate(
      VidnestService.servers.length,
      (index) => FocusNode(),
    );

    // Default focus to currently active server
    final activeIndex = VidnestService.servers.indexWhere(
      (s) => s.id.toLowerCase() == widget.activeServerId.toLowerCase(),
    );
    _focusedIndex = activeIndex >= 0 ? activeIndex : 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _serverFocusNodes.isNotEmpty) {
        _serverFocusNodes[_focusedIndex].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _serverFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        widget.onDismiss();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: TvLayout.horizontalInset(context),
        vertical: TvLayout.sectionGap(context) * 2,
      ),
      child: FocusScope(
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: (MediaQuery.sizeOf(context).width * 0.62)
              .clamp(760.0, 1120.0)
              .toDouble(),
          padding: EdgeInsets.all(TvLayout.sectionGap(context) * 1.75),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_sync, color: Color(0xFFE50914), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Flexible(
                          child: Text(
                            'Select Streaming Server',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'D-Pad to navigate • Press OK to switch',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'If your current stream buffers or fails, switch to another Vidnest mirror server. Position is preserved.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),

              // Provider Badge
              Row(
                children: [
                  Text(
                    'Provider:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Color(0xFFE50914), size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Vidnest Official (9 Fast CDN Mirrors)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Server Grid
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: VidnestService.servers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final server = VidnestService.servers[index];
                    final isActive = server.id.toLowerCase() == widget.activeServerId.toLowerCase();

                    return _ServerCard(
                      server: server,
                      isActive: isActive,
                      focusNode: _serverFocusNodes[index],
                      onTap: () => widget.onServerSelected(server),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Close Hint
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                  label: const Text('Dismiss (Back)', style: TextStyle(color: Colors.white60)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatefulWidget {
  final VidnestServer server;
  final bool isActive;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _ServerCard({
    required this.server,
    required this.isActive,
    required this.focusNode,
    required this.onTap,
  });

  @override
  State<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<_ServerCard> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused
        ? const Color(0xFFE50914)
        : (widget.isActive ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.1));

    final bgColor = _isFocused
        ? const Color(0xFFE50914).withValues(alpha: 0.25)
        : (widget.isActive ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05));

    return InkWell(
      focusNode: widget.focusNode,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: _isFocused ? 2.5 : 1.2),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              widget.isActive ? Icons.check_circle : Icons.dns_outlined,
              color: widget.isActive ? const Color(0xFF10B981) : (_isFocused ? const Color(0xFFE50914) : Colors.white70),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.server.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: _isFocused || widget.isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.server.badge,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.server.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
