import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import '../../theme/app_colors.dart';
import '_dict.dart';

// ─── lz-string JS interop ───
// Loaded via web/index.html <script src="...lz-string.min.js">.
@JS('LZString.compressToEncodedURIComponent')
external String _lzCompress(String text);

class SafeLinkApp extends StatefulWidget {
  const SafeLinkApp({super.key});

  @override
  State<SafeLinkApp> createState() => _SafeLinkAppState();
}

class _SafeLinkAppState extends State<SafeLinkApp> {
  final _input = TextEditingController();
  String? _output;
  String? _error;

  String get _origin {
    final loc = web.window.location;
    return '${loc.protocol}//${loc.host}';
  }

  /// Method used for the most recent encoding.
  String? _method; // 'lz' or 'plain'
  String? _dictMatch; // matched dict label, if any
  int? _strippedCount;
  bool _stripTracking = true;

  void _generate() {
    final raw = _input.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _output = null;
        _method = null;
        _dictMatch = null;
        _strippedCount = null;
        _error = 'URL을 입력하세요';
      });
      return;
    }
    // Auto-prepend https:// if scheme missing
    String url = raw;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        !parsed.hasScheme ||
        !parsed.hasAuthority ||
        !parsed.host.contains('.') ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      setState(() {
        _output = null;
        _method = null;
        _dictMatch = null;
        _strippedCount = null;
        _error = '유효한 http/https URL이 아닙니다 (host에 도메인 필요)';
      });
      return;
    }

    // Step 1: optionally strip tracking params
    int strippedCount = 0;
    String working = url;
    if (_stripTracking) {
      final beforeParams = Uri.parse(url).queryParameters.length;
      working = stripTracking(url);
      final afterParams = Uri.parse(working).queryParameters.length;
      strippedCount = beforeParams - afterParams;
    }

    // Step 2: apply dict prefix substitution
    final dict = applyDict(working);
    final substituted = dict.result;

    // Step 3: try lz-string vs plain URI-encode, pick shorter
    final compressed = _lzCompress(substituted);
    final encoded = Uri.encodeComponent(substituted);
    final useLz = compressed.length < encoded.length;
    final payload = useLz ? 'c~$compressed' : 'r~$encoded';

    setState(() {
      _output = '$_origin/go/#$payload';
      _method = useLz ? 'lz' : 'plain';
      _dictMatch = dict.label;
      _strippedCount = strippedCount;
      _error = null;
    });
  }

  Future<void> _copy() async {
    if (_output == null) return;
    await Clipboard.setData(ClipboardData(text: _output!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('복사 완료'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.carbon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openInNewTab() {
    if (_output == null) return;
    web.window.open(_output!, '_blank');
  }

  void _clear() {
    setState(() {
      _input.clear();
      _output = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.abyss,
      ),
      child: Scaffold(
        backgroundColor: AppColors.abyss,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _header(),
                  const SizedBox(height: 36),

                  // Tracking toggle
                  _trackingToggle(),
                  const SizedBox(height: 20),

                  // Input
                  _label('LONG URL'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _input,
                    style: GoogleFonts.inter(
                      color: AppColors.snow,
                      fontSize: 15,
                    ),
                    cursorColor: AppColors.signalGreen,
                    minLines: 1,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      hint: 'https://example.com/very/long/path?with=params',
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action row
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryBtn(
                          icon: Icons.bolt,
                          label: 'GENERATE',
                          onTap: _generate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _GhostBtn(
                        icon: Icons.refresh,
                        label: 'CLEAR',
                        onTap: _clear,
                      ),
                    ],
                  ),

                  if (_output != null) ...[
                    const SizedBox(height: 32),
                    _label('SAFE LINK'),
                    const SizedBox(height: 10),
                    _outputBox(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryBtn(
                            icon: Icons.content_copy,
                            label: 'COPY',
                            onTap: _copy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _GhostBtn(
                          icon: Icons.open_in_new,
                          label: 'TEST',
                          onTap: _openInNewTab,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _statsRow(),
                  ],

                  const SizedBox(height: 36),
                  _howItWorks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── UI helpers ─────────────────

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.signalGreen),
          ),
          child: const Icon(Icons.link, color: AppColors.signalGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "It's Safe Link",
                style: GoogleFonts.inter(
                  color: AppColors.snow,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trustable redirector through pure-blanche.com',
                style: TextStyle(
                  color: AppColors.steel,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.signalGreen,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.warmCharcoal, fontSize: 14),
      filled: true,
      fillColor: AppColors.carbon,
      contentPadding: const EdgeInsets.all(14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.warmCharcoal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.signalGreen, width: 2),
      ),
    );
  }

  Widget _outputBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.signalGreen.withValues(alpha: 0.5)),
      ),
      child: SelectableText(
        _output!,
        style: const TextStyle(
          color: AppColors.snow,
          fontFamily: 'Consolas, monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _statsRow() {
    final original = _input.text.trim();
    final shortened = _output ?? '';
    final originalLen = original.length;
    final shortenedLen = shortened.length;
    final methodLabel =
        _method == 'lz' ? 'lz-string' : (_method == 'plain' ? 'plain' : '—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _stat('ORIGINAL', '${originalLen}c', AppColors.steel),
            _stat('SAFE LINK', '${shortenedLen}c', AppColors.snow),
            _stat('METHOD', methodLabel, AppColors.signalGreen),
          ],
        ),
        if (_dictMatch != null || (_strippedCount ?? 0) > 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_dictMatch != null) _badge('📚 ${_dictMatch!}', AppColors.signalGreen),
              if ((_strippedCount ?? 0) > 0)
                _badge('🧹 stripped $_strippedCount params', AppColors.mint),
            ],
          ),
        ],
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _trackingToggle() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _stripTracking = !_stripTracking),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(
              color: _stripTracking
                  ? AppColors.signalGreen.withValues(alpha: 0.5)
                  : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _stripTracking
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color:
                    _stripTracking ? AppColors.signalGreen : AppColors.steel,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strip tracking parameters',
                      style: GoogleFonts.inter(
                        color: AppColors.snow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'utm_*, fbclid, traceId 등 자동 제거',
                      style: TextStyle(color: AppColors.steel, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.steel,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Consolas, monospace',
          ),
        ),
      ],
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warmCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.steel),
              const SizedBox(width: 8),
              Text(
                'HOW IT WORKS',
                style: GoogleFonts.inter(
                  color: AppColors.steel,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '· URL을 lz-string으로 압축해 hash(#) 뒤에 인코딩\n'
            '· 백엔드/DB 없이 클라이언트 JS만으로 디코드 → redirect\n'
            '· 매핑이 링크 자체에 포함되므로 만료/저장 없음\n'
            '· 도착지를 한 번 보여준 뒤 이동 (피싱 방지)',
            style: TextStyle(
              color: AppColors.parchment,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Buttons ─────────────────

class _PrimaryBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.carbon : AppColors.carbon,
            border: Border.all(color: AppColors.signalGreen),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.signalGreen.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: AppColors.signalGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: AppColors.mint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GhostBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _hovered ? AppColors.signalGreen : AppColors.steel,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: _hovered ? AppColors.signalGreen : AppColors.steel,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
