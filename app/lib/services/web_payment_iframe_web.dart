import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerIframeFactory(String viewType, String url) {
  // Register the factory with Flutter's web engine
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'payment; clipboard-write'; // Allow secure payment features and copy-paste clipboard events
    return iframe;
  });
}
