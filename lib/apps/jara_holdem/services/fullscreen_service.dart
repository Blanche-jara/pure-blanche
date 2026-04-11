import 'fullscreen_stub.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart'
    as fullscreen_impl;

/// Provides fullscreen toggle that works on web and is a no-op on mobile.
class FullscreenService {
  static void enterFullscreen() => fullscreen_impl.enterFullscreenImpl();
  static void exitFullscreen() => fullscreen_impl.exitFullscreenImpl();
}
