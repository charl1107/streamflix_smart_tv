import 'package:flutter/material.dart';

class PlayerRouterPlatform {
  static Future<void> open(
    BuildContext context, {
    required String embedUrl,
    required String title,
    required Object mediaId,
    required String mediaType,
    int? season,
    int? episode,
  }) {
    final args = <String, dynamic>{
      'embedUrl': embedUrl,
      'title': title,
      'mediaId': mediaId,
      'mediaType': mediaType,
    };
    if (season != null) args['season'] = season;
    if (episode != null) args['episode'] = episode;

    return Navigator.pushNamed(context, '/player', arguments: args);
  }
}
