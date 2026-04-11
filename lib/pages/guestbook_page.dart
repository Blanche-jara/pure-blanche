import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/page_scaffold.dart';

class GuestbookPage extends StatefulWidget {
  const GuestbookPage({super.key});

  @override
  State<GuestbookPage> createState() => _GuestbookPageState();
}

class _GuestbookPageState extends State<GuestbookPage> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final List<_GuestEntry> _entries = [
    _GuestEntry(name: 'Blanche', message: '방명록에 오신 걸 환영합니다!', date: '2026.04.10'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitEntry() {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || message.isEmpty) return;

    setState(() {
      _entries.insert(
        0,
        _GuestEntry(
          name: name,
          message: message,
          date: _today(),
        ),
      );
      _nameController.clear();
      _messageController.clear();
    });
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Guestbook',
      body: Stack(
        children: [
          Column(
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
                ),
                const SizedBox(height: 16),
                _StyledTextField(
                  controller: _messageController,
                  hint: '메시지를 남겨주세요...',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _SubmitButton(onTap: _submitEntry),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Entries
          ...List.generate(_entries.length, (i) {
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
                        Text(
                          entry.name,
                          style: const TextStyle(
                            fontFamily: 'Segoe UI',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.snow,
                          ),
                        ),
                        Text(
                          entry.date,
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
        ],
      ),
          // Under construction overlay
          Positioned.fill(
            child: Container(
              color: AppColors.abyss.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 48,
                      color: AppColors.signalGreen,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '공사중',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.snow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '현재 페이지를 준비하고 있습니다.\n빠른 시일 내에 찾아뵙겠습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.parchment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestEntry {
  final String name;
  final String message;
  final String date;

  const _GuestEntry({
    required this.name,
    required this.message,
    required this.date,
  });
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SubmitButton({required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
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
            color: _hovered ? AppColors.carbon : AppColors.carbon,
            border: Border.all(
              color: _hovered ? AppColors.signalGreen : AppColors.warmCharcoal,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Submit',
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
