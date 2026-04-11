import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

/// Provides fullscreen toggle that works on web and is a no-op on mobile.
class FullscreenService {
  static void enterFullscreen() {
    if (!kIsWeb) return;
    web.document.documentElement?.requestFullscreen();
  }

  static void exitFullscreen() {
    if (!kIsWeb) return;
    web.document.exitFullscreen();
  }
}
