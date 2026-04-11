import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import '../../theme/app_colors.dart';

/// Embeds an HTML page via iframe for web projects (Jamakase, 251228).
class HtmlAppPage extends StatefulWidget {
  final String title;
  final String htmlPath;

  const HtmlAppPage({
    super.key,
    required this.title,
    required this.htmlPath,
  });

  @override
  State<HtmlAppPage> createState() => _HtmlAppPageState();
}

class _HtmlAppPageState extends State<HtmlAppPage> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'html-app-${widget.htmlPath.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = widget.htmlPath;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'autoplay';
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Column(
        children: [
          // Top bar with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.abyss.withValues(alpha: 0.92),
              border: const Border(
                bottom: BorderSide(color: AppColors.warmCharcoal),
              ),
            ),
            child: Row(
              children: [
                _BackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: AppColors.snow,
                  ),
                ),
              ],
            ),
          ),
          // Iframe
          Expanded(
            child: HtmlElementView(viewType: _viewType),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: _hovered ? AppColors.signalGreen : AppColors.fog,
          ),
        ),
      ),
    );
  }
}
