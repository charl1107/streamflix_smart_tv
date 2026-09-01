import 'package:flutter/material.dart';
import 'package:streamflix_tv/services/subtitle_parser.dart';

/// Renders subtitle text as an overlay at the bottom of the video player.
/// Automatically shows/hides based on the current playback position.
class SubtitleOverlay extends StatelessWidget {
  final SubtitleCue? activeCue;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;

  const SubtitleOverlay({
    super.key,
    this.activeCue,
    this.fontSize = 22,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    if (activeCue == null) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activeCue!.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.4,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
