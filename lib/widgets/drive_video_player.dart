import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

/// Embeds the custom video-player.html with a Google Drive file ID.
/// [autoplay] mutes and auto-plays when the widget is visible.
class DriveVideoPlayer extends StatefulWidget {
  final String driveFileId;
  final bool autoplay;

  const DriveVideoPlayer({
    super.key,
    required this.driveFileId,
    this.autoplay = false,
  });

  @override
  State<DriveVideoPlayer> createState() => _DriveVideoPlayerState();
}

class _DriveVideoPlayerState extends State<DriveVideoPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'drive-video-${widget.driveFileId}-${widget.autoplay}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final autoFlag = widget.autoplay ? '1' : '0';
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = 'apps/video-player.html?id=${widget.driveFileId}&autoplay=$autoFlag';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'autoplay; fullscreen';
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
