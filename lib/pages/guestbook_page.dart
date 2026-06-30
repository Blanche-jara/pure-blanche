import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
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

  // 관리자 상태. _adminToken != null 이면 관리자 모드.
  static const String _adminStorageKey = 'pb_admin_token';
  String? _adminToken;
  bool get _isAdmin => _adminToken != null;

  @override
  void initState() {
    super.initState();
    _restoreAdmin();
    _loadEntries();
    // 숨김 URL(#/guestbook?admin) 진입 시, 아직 인증 전이면 비밀번호 프롬프트.
    if (!_isAdmin && _adminRequestedFromUrl()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptAdminLogin();
      });
    }
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

  // ── 관리자 모드 ──────────────────────────────────────────────────────
  // 해시 라우팅이므로 전체 URL(예: .../#/guestbook?admin)에 admin이 있으면 진입.
  bool _adminRequestedFromUrl() =>
      Uri.base.toString().toLowerCase().contains('admin');

  void _restoreAdmin() {
    try {
      final saved = web.window.sessionStorage.getItem(_adminStorageKey);
      if (saved != null && saved.isNotEmpty) _adminToken = saved;
    } catch (_) {
      // sessionStorage 비활성 등 — 무시(비관리자 모드 유지).
    }
  }

  void _saveAdmin(String token) {
    _adminToken = token;
    try {
      web.window.sessionStorage.setItem(_adminStorageKey, token);
    } catch (_) {}
  }

  void _exitAdmin() {
    setState(() => _adminToken = null);
    try {
      web.window.sessionStorage.removeItem(_adminStorageKey);
    } catch (_) {}
  }

  /// 관리자 토큰 만료(401) 공통 처리: 안내 + 관리자 모드 해제.
  void _handleAdminExpired() {
    _showSnack('관리자 인증이 만료되었습니다. 다시 로그인해주세요.');
    _exitAdmin();
  }

  Future<void> _promptAdminLogin() async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (_) => _AdminLoginDialog(
        controller: controller,
        onVerify: _service.verifyAdmin,
      ),
    );
    controller.dispose();
    if (token != null && token.isNotEmpty && mounted) {
      setState(() => _saveAdmin(token));
    }
  }

  Future<void> _confirmDelete(GuestEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: '방명록 삭제',
        body: '"${entry.name}" 님의 글을 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
        confirmLabel: '삭제',
        danger: true,
      ),
    );
    if (ok != true || !mounted) return;
    final token = _adminToken;
    if (token == null) return;
    try {
      await _service.deleteEntry(entry.id, adminToken: token);
      if (!mounted) return;
      setState(
          () => _entries = _entries.where((e) => e.id != entry.id).toList());
    } on GuestbookException catch (e) {
      if (!mounted) return;
      if (e.authExpired) {
        _handleAdminExpired();
      } else {
        _showSnack(e.message);
      }
    }
  }

  Future<void> _editEntry(GuestEntry entry) async {
    final token = _adminToken;
    if (token == null) return;
    final result = await showDialog<GuestEntry>(
      context: context,
      builder: (_) => _AdminEditDialog(
        entry: entry,
        onSave: (name, message) => _service.updateEntry(
          entry.id,
          name: name,
          message: message,
          adminToken: token,
        ),
        onAuthExpired: _handleAdminExpired,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _entries =
            _entries.map((e) => e.id == result.id ? result : e).toList();
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.carbon,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          if (_isAdmin) ...[
            const SizedBox(height: 16),
            _AdminBar(onExit: _exitAdmin),
          ],
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
                if (_isAdmin) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _AdminAction(
                        icon: Icons.edit_outlined,
                        label: '수정',
                        onTap: () => _editEntry(entry),
                      ),
                      const SizedBox(width: 8),
                      _AdminAction(
                        icon: Icons.delete_outline,
                        label: '삭제',
                        danger: true,
                        onTap: () => _confirmDelete(entry),
                      ),
                    ],
                  ),
                ],
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

/// 관리자 모드 표시 + 종료 배너.
class _AdminBar extends StatelessWidget {
  final VoidCallback onExit;
  const _AdminBar({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.signalGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.signalGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined,
              size: 16, color: AppColors.signalGreen),
          const SizedBox(width: 8),
          const Text(
            '관리자 모드 — 모든 글 수정·삭제 가능',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.signalGreen,
            ),
          ),
          const SizedBox(width: 14),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onExit,
              child: const Text(
                '종료',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.steel,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 관리자용 글 작업 버튼(수정/삭제).
class _AdminAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _AdminAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<_AdminAction> createState() => _AdminActionState();
}

class _AdminActionState extends State<_AdminAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger ? AppColors.danger : AppColors.signalGreen;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.abyss,
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: _hovered ? accent : AppColors.warmCharcoal),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 15, color: _hovered ? accent : AppColors.steel),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: _hovered ? accent : AppColors.parchment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 관리자 비밀번호 입력 다이얼로그. 검증 성공 시 입력한 토큰을 pop으로 반환.
class _AdminLoginDialog extends StatefulWidget {
  final TextEditingController controller;
  final Future<bool> Function(String) onVerify;
  const _AdminLoginDialog({required this.controller, required this.onVerify});

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final value = widget.controller.text.trim();
    if (value.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await widget.onVerify(value);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(value);
      } else {
        setState(() {
          _busy = false;
          _error = '비밀번호가 올바르지 않습니다.';
        });
      }
    } on GuestbookException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '인증에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.carbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.warmCharcoal),
      ),
      title: const Text(
        '관리자 인증',
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.snow,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            obscureText: true,
            enabled: !_busy,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 15, color: AppColors.snow),
            decoration: _dialogInput('관리자 비밀번호'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: AppColors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('취소',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.steel)),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.signalGreen)),
                )
              : const Text('확인',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.mint,
                      fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// 확인/취소 다이얼로그. pop(true)=확인.
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool danger;
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.carbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.warmCharcoal),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.snow,
        ),
      ),
      content: Text(
        body,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.6,
            color: AppColors.parchment),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.steel)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.danger : AppColors.mint)),
        ),
      ],
    );
  }
}

/// 관리자용 글 수정 다이얼로그. 저장 성공 시 수정된 GuestEntry를 pop으로 반환.
class _AdminEditDialog extends StatefulWidget {
  final GuestEntry entry;
  final Future<GuestEntry> Function(String name, String message) onSave;
  final VoidCallback onAuthExpired;
  const _AdminEditDialog({
    required this.entry,
    required this.onSave,
    required this.onAuthExpired,
  });

  @override
  State<_AdminEditDialog> createState() => _AdminEditDialogState();
}

class _AdminEditDialogState extends State<_AdminEditDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.entry.name);
  late final TextEditingController _message =
      TextEditingController(text: widget.entry.message);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _name.text.trim();
    final message = _message.text.trim();
    if (name.isEmpty || message.isEmpty) {
      setState(() => _error = '이름과 메시지를 모두 입력해주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await widget.onSave(name, message);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on GuestbookException catch (e) {
      if (!mounted) return;
      // 토큰 만료면 다이얼로그를 닫고 관리자 모드를 해제(삭제 경로와 일관).
      if (e.authExpired) {
        Navigator.of(context).pop();
        widget.onAuthExpired();
        return;
      }
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '수정에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.carbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.warmCharcoal),
      ),
      title: const Text(
        '방명록 수정',
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.snow,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              maxLines: 1,
              maxLength: 30,
              enabled: !_busy,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 15, color: AppColors.snow),
              decoration: _dialogInput('이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 5,
              maxLength: 500,
              enabled: !_busy,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 15, color: AppColors.snow),
              decoration: _dialogInput('메시지'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('취소',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.steel)),
        ),
        TextButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.signalGreen)),
                )
              : const Text('저장',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.mint,
                      fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// 다이얼로그 입력 필드 공통 데코레이션.
InputDecoration _dialogInput(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Inter', color: AppColors.steel),
    counterStyle:
        const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.steel),
    filled: true,
    fillColor: AppColors.abyss,
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
    contentPadding: const EdgeInsets.all(14),
  );
}
