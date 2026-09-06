import 'dart:ui_web' as ui;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = {};

Widget buildPlatformEmbedView({
  required String embedUrl,
  required String title,
  required VoidCallback onLoaded,
}) {
  final cleanHash = embedUrl.hashCode.abs().toString();
  final viewType = 'vidnest-iframe-$cleanHash';

  if (!_registeredViews.contains(viewType)) {
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final container = web.document.createElement('div') as web.HTMLDivElement;
        container.style.width = '100%';
        container.style.height = '100%';
        container.style.position = 'relative';
        container.style.backgroundColor = '#000';

        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = embedUrl;
        iframe.title = title.isNotEmpty ? title : 'Vidnest Stream';
        iframe.style.border = '0';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.setAttribute('frameborder', '0');
        iframe.setAttribute('scrolling', 'no');
        iframe.setAttribute('allowfullscreen', 'true');
        iframe.allowFullscreen = true;
        iframe.allow = 'autoplay; fullscreen; picture-in-picture; encrypted-media';
        iframe.referrerPolicy = 'origin';

        // A Flutter widget drawn over a platform iframe cannot reliably receive
        // pointer events on the web. Keep this app-owned control in the same
        // HTML stacking context as the iframe instead.
        final backButton = web.document.createElement('button') as web.HTMLButtonElement;
        backButton.textContent = '← Back';
        backButton.setAttribute('type', 'button');
        backButton.style.position = 'absolute';
        backButton.style.top = '88px';
        backButton.style.left = '24px';
        backButton.style.zIndex = '2147483647';
        backButton.style.minWidth = '96px';
        backButton.style.minHeight = '52px';
        backButton.style.padding = '0 18px';
        backButton.style.border = '1px solid rgba(255,255,255,.45)';
        backButton.style.borderRadius = '26px';
        backButton.style.background = 'rgba(0,0,0,.78)';
        backButton.style.color = '#fff';
        backButton.style.font = '600 16px system-ui, sans-serif';
        backButton.style.cursor = 'pointer';
        backButton.style.pointerEvents = 'auto';
        backButton.onclick = ((web.MouseEvent _) {
          web.window.history.back();
        }).toJS;

        var hasLoaded = false;
        void triggerLoaded() {
          if (!hasLoaded) {
            hasLoaded = true;
            onLoaded();
          }
        }
        iframe.onload = (web.Event _) {
          triggerLoaded();
        }.toJS;
        web.window.setTimeout((() => triggerLoaded()).toJS, 2000.toJS);
        container.append(iframe);
        container.append(backButton);
        return container;
      },
    );
    _registeredViews.add(viewType);
  }

  return HtmlElementView(
    key: ValueKey(embedUrl),
    viewType: viewType,
  );
}
