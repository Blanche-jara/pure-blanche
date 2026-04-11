import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

/// Embeds a YouTube video via iframe (no-cookie domain for privacy).
class YoutubePlayer extends StatefulWidget {
  final String youtubeId;
  final bool autoplay;

  const YoutubePlayer({
    super.key,
    required this.youtubeId,
    this.autoplay = false,
  });

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'yt-player-${widget.youtubeId}-${widget.autoplay}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final autoFlag = widget.autoplay ? '1' : '0';
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src =
            'https://www.youtube-nocookie.com/embed/${widget.youtubeId}'
            '?autoplay=$autoFlag&mute=${widget.autoplay ? '1' : '0'}'
            '&rel=0&modestbranding=1&playsinline=1';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'autoplay; fullscreen; encrypted-media';
        iframe.setAttribute('allowfullscreen', '');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
