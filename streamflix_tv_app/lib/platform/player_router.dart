import 'player_router_native.dart'
    if (dart.library.html) 'player_router_web.dart';

import 'package:flutter/material.dart';

class PlayerRouter {
  static Future<void> open(
    BuildContext context, {
    required String embedUrl,
    required String title,
    required Object mediaId,
    required String mediaType,
    int? season,
    int? episode,
  }) {
    return PlayerRouterPlatform.open(
      context,
      embedUrl: embedUrl,
      title: title,
      mediaId: mediaId,
      mediaType: mediaType,
      season: season,
      episode: episode,
    );
  }
}
