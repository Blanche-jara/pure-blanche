import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/guestbook_service.dart';
import '../widgets/page_scaffold.dart';

class GuestbookPage extends StatefulWidget {
  const GuestbookPage({super.key});

  @override
  State<GuestbookPage> createState() => _GuestbookPageState();
}

class _GuestbookPageState extends State<GuestbookPage> {
  final _service = GuestbookService();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  // 목록 로드 상태
  bool _loading = true;
  String? _loadError;
  List<GuestEntry> _entries = const [];

  // 작성 상태
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final entries = await _service.fetchEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on GuestbookException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = '방명록을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || message.isEmpty) {
      setState(() => _submitError = '이름과 메시지를 모두 입력해주세요.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final created = await _service.submit(name: name, message: message);
      if (!mounted) return;
      setState(() {
        _entries = [created, ..._entries];
        _nameController.clear();
        _messageController.clear();
        _submitting = false;
      });
    } on GuestbookException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = '작성에 실패했습니다.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Guestbook',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GUESTBOOK',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.52,
              color: AppColors.signalGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Leave a Message',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 48),

          // Input form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.carbon,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warmCharcoal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StyledTextField(
                  controller: _nameController,
                  hint: '이름',
                  maxLines: 1,
                  maxLength: 30,
                  enabled: !_submitting,
                ),
                const SizedBox(height: 16),
                _StyledTextField(
                  controller: _messageController,
                  hint: '메시지를 남겨주세요...',
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_submitting,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SubmitButton(
                    onTap: _submitEntry,
                    loading: _submitting,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Entries area (3-state)
          _buildEntriesArea(),
        ],
      ),
    );
  }

  Widget _buildEntriesArea() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.signalGreen),
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _ErrorCard(message: _loadError!, onRetry: _loadEntries);
    }

    if (_entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: const Text(
          '아직 작성된 방명록이 없습니다.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: AppColors.steel,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_entries.length, (i) {
        final entry = _entries[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < _entries.length - 1 ? 16 : 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.carbon,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warmCharcoal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.snow,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.localDate,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.parchment,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warmCharcoal),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 40,
            color: AppColors.steel,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.6,
              color: AppColors.parchment,
            ),
          ),
          const SizedBox(height: 24),
          _RetryButton(onTap: onRetry),
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '다시 시도',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _hovered ? AppColors.mint : AppColors.snow,
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: AppColors.snow,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: AppColors.steel,
        ),
        counterStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.steel,
        ),
        filled: true,
        fillColor: AppColors.abyss,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.warmCharcoal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.warmCharcoal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.signalGreen),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.warmCharcoal),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool loading;
  const _SubmitButton({required this.onTap, this.loading = false});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.carbon,
            border: Border.all(
              color: (_hovered && !disabled)
                  ? AppColors.signalGreen
                  : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.signalGreen),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.loading ? '전송 중...' : 'Submit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: disabled
                      ? AppColors.steel
                      : (_hovered ? AppColors.mint : AppColors.snow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
