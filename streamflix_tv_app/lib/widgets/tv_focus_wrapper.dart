import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final ValueChanged<bool>? onFocusChange;

  const TvFocusWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.autofocus = false,
    this.borderRadius,
    this.onFocusChange,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'TvFocusWrapper');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChange?.call(_isFocused);
    if (_isFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA || 
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFocused ? const Color(0xFFE50914) : Colors.transparent,
                width: 2.2,
              ),
              borderRadius: effectiveRadius,
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withValues(alpha: 0.55),
                        blurRadius: 16,
                        spreadRadius: 3,
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
