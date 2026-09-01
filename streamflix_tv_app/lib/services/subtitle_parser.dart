// WebVTT Subtitle Parser
// Parses .vtt subtitle files into timed cue objects for overlay rendering.

/// Represents a single subtitle cue with start/end timestamps and text.
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  /// Check if this cue is active at a given position.
  bool isActiveAt(Duration position) {
    return position >= start && position <= end;
  }

  @override
  String toString() => 'Cue($start -> $end: $text)';
}

/// Represents a subtitle track with language info and parsed cues.
class SubtitleTrack {
  final String name;
  final String language;
  final String url;
  final bool isDefault;
  final List<SubtitleCue> cues;

  const SubtitleTrack({
    required this.name,
    required this.language,
    required this.url,
    this.isDefault = false,
    this.cues = const [],
  });

  factory SubtitleTrack.fromApiJson(Map<String, dynamic> json) =>
      SubtitleTrack(
        name: json['name'] ?? 'Unknown',
        language: json['language'] ?? 'und',
        url: json['url'] ?? '',
        isDefault: json['isDefault'] ?? false,
      );

  /// Get the active cue at the given position, or null.
  SubtitleCue? getActiveCue(Duration position) {
    for (final cue in cues) {
      if (cue.isActiveAt(position)) return cue;
    }
    return null;
  }
}

/// Parse a WebVTT subtitle file content into a list of cues.
///
/// Handles both standard VTT and HLS-style VTT (which may lack the WEBVTT header).
List<SubtitleCue> parseVtt(String content) {
  final cues = <SubtitleCue>[];
  final lines = content.split(RegExp(r'\r?\n'));

  // Skip WEBVTT header and any metadata
  int i = 0;
  while (i < lines.length && !lines[i].contains('-->')) {
    i++;
  }

  while (i < lines.length) {
    final line = lines[i].trim();

    // Look for a timestamp line: "00:00:01.000 --> 00:00:04.000"
    if (line.contains('-->')) {
      final parts = line.split('-->');
      if (parts.length == 2) {
        final start = _parseTimestamp(parts[0].trim());
        final end = _parseTimestamp(parts[1].trim());

        // Collect cue text (may be multi-line)
        final textLines = <String>[];
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          final cueLine = lines[i].trim();
          // Skip VTT tags like <c.colorE5E5E5> etc
          final cleaned = cueLine
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .trim();
          if (cleaned.isNotEmpty) {
            textLines.add(cleaned);
          }
          i++;
        }

        if (textLines.isNotEmpty && start != null && end != null) {
          cues.add(SubtitleCue(
            start: start,
            end: end,
            text: textLines.join('\n'),
          ));
        }
      }
    } else {
      i++;
    }
  }

  return cues;
}

/// Parse a VTT timestamp string like "00:01:23.456" or "1:23:45,678" into Duration.
Duration? _parseTimestamp(String ts) {
  // Normalize separators: replace comma with dot
  ts = ts.replaceAll(',', '.');

  final parts = ts.split(':');
  if (parts.length == 3) {
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = _parseSeconds(parts[2]);
    if (seconds != null) {
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds.floor(),
        milliseconds: ((seconds % 1) * 1000).round(),
      );
    }
  } else if (parts.length == 2) {
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = _parseSeconds(parts[1]);
    if (seconds != null) {
      return Duration(
        minutes: minutes,
        seconds: seconds.floor(),
        milliseconds: ((seconds % 1) * 1000).round(),
      );
    }
  }
  return null;
}

double? _parseSeconds(String s) {
  return double.tryParse(s);
}
