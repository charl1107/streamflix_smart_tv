import 'dart:ui_web' as ui;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildPlatformEmbedView({
  required String embedUrl,
  required String title,
  required VoidCallback onLoaded,
}) {
  final viewType = 'vidnest-iframe-${embedUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
  ui.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = embedUrl;
      iframe.style.border = '0';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.backgroundColor = '#000';
      iframe.allowFullscreen = true;
      iframe.allow = 'autoplay; fullscreen; picture-in-picture; encrypted-media';
      iframe.referrerPolicy = 'origin';
      iframe.onload = (web.Event _) {
        onLoaded();
      }.toJS;
      return iframe;
    },
  );
  return HtmlElementView(viewType: viewType);
}
