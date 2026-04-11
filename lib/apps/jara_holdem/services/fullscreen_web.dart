import 'package:web/web.dart' as web;

/// Web implementations using the web package.
void enterFullscreenImpl() {
  web.document.documentElement?.requestFullscreen();
}

void exitFullscreenImpl() {
  web.document.exitFullscreen();
}
