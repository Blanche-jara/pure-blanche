/// 정산표 — 공유 링크 만들기/복사 + 공유 상태 배너.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../../theme/app_colors.dart';
import 'models.dart';
import 'ui_kit.dart';

/// 공유 코드로 이 정산표를 여는 전체 URL.
/// 예: `https://pure-blanche.com/#/settlement/k3m8qr2t`
String shareLinkFor(String code) {
  final loc = web.window.location;
  return '${loc.protocol}//${loc.host}/#/settlement/$code';
}

/// 현재 주소의 `#/settlement/<code>` 에서 코드만 꺼낸다. 없으면 null.
String? codeFromLocation() {
  final hash = web.window.location.hash; // 예: "#/settlement/k3m8qr2t"
  final m = RegExp(r'^#/settlement/([a-z0-9]{8})$').firstMatch(hash);
  return m?.group(1);
}

Future<void> copyShareLink(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: shareLinkFor(code)));
  if (!context.mounted) return;
  showToast(context, '공유 링크를 복사했다');
}

/// 프로젝트가 서버 공유인지 이 브라우저 전용인지 한 줄로 알려준다.
class ShareBanner extends StatelessWidget {
  final SettlementProject project;

  const ShareBanner({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final code = project.code;

    if (code == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.warmCharcoal.withValues(alpha: 0.8),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, size: 15, color: AppColors.steel),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                '이 브라우저에만 저장된 정산표다. 다른 사람은 볼 수 없다.',
                style: TextStyle(fontSize: 12.5, color: AppColors.steel),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.signalGreen.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.signalGreen.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 15, color: AppColors.signalGreen),
          const SizedBox(width: 9),
          const Text(
            '공유 중',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.signalGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              shareLinkFor(code),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: AppColors.parchment,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GhostButton(
            label: '링크 복사',
            icon: Icons.copy,
            dense: true,
            onTap: () => copyShareLink(context, code),
          ),
        ],
      ),
    );
  }
}
