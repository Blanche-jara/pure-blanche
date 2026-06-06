import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../widgets/apple_widgets.dart';

/// 도움말 화면: 사용법 + 핵심 개념(ICM·Chip-chop·Save) + 화면별 기능 설명.
///
/// 상단 AppBar의 `?` 버튼에서 진입한다. 딜 화면 범례와 색을 맞춰
/// (ICM=에메랄드, Chip-chop=골드, Save=세이지) 개념을 시각적으로 연결한다.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // 딜 화면 범례와 동일한 식별색.
  static const _saveColor = Color(0xFF8FA39A);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('도움말')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const AppleLargeTitle(
            title: '도움말',
            subtitle: 'ICM Split 사용법과 핵심 개념',
          ),

          const _Section(
            title: '이 앱은?',
            child: _Para(
              'ICM Split은 포커 토너먼트 막바지에 남은 상금을 어떻게 나눌지(딜)와, '
              '올인 상황에서 콜/폴드를 ICM 기준으로 판단하도록 돕는 계산기입니다. '
              '칩 스택과 상금 구조만 넣으면 세 가지 분배 방식과 의사결정 지표를 한눈에 비교할 수 있어요.',
            ),
          ),

          const _Section(
            title: '사용 순서',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step(
                  n: '1',
                  title: '입력',
                  body: '각 플레이어의 칩 스택과 상금 구조(1·2·3등 …)를 입력합니다.',
                ),
                _Step(
                  n: '2',
                  title: '결과',
                  body: '내 칩 스택이 ICM 기준 "실제 상금 가치(₩)"로 얼마인지 확인합니다.',
                ),
                _Step(
                  n: '3',
                  title: '딜',
                  body: 'ICM · Chip-chop · Save 세 분배안을 막대그래프·표로 비교하고 협상합니다.',
                ),
                _Step(
                  n: '4',
                  title: '의사결정',
                  body: '버블에서 올인 콜/폴드가 ICM상 이득인지 판단합니다.',
                  last: true,
                ),
              ],
            ),
          ),

          _Section(
            title: '핵심 개념',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Concept(
                  color: scheme.primary,
                  term: 'ICM',
                  sub: 'Independent Chip Model',
                  body:
                      '칩 스택을 "기대 상금(₩)"으로 환산하는 표준 모델입니다. 상금은 유한하기 때문에 '
                      '칩이 많아질수록 1칩당 가치는 줄어듭니다 — 그래서 단순 칩 비율과 다릅니다. '
                      '공정한 딜과 정확한 의사결정의 기준이 됩니다.',
                ),
                _Concept(
                  color: AppColors.gold,
                  term: 'Chip-chop',
                  sub: '칩 비례 분배',
                  body:
                      '최저 등수 상금을 전원에게 먼저 보장한 뒤, 남은 상금을 칩 비율 그대로 나누는 방식입니다. '
                      '계산이 단순하지만 칩리더에게 유리하고 숏스택에 불리합니다. '
                      '실전에선 보통 ICM과 Chip-chop 사이에서 협상합니다.',
                ),
                _Concept(
                  color: _saveColor,
                  term: 'Save',
                  sub: 'Save-for-winner',
                  body:
                      '1등 상금에서 적립금을 떼어 최종 우승자에게 따로 적립하고, 나머지를 지금 ICM으로 분배합니다. '
                      '기대 총액은 순수 ICM과 같고, 분산(리스크)만 우승자 자리로 옮겨집니다.',
                  last: true,
                ),
              ],
            ),
          ),

          const _Section(
            title: '화면별 기능',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Feature(
                  icon: Icons.edit_outlined,
                  title: '입력',
                  body: '플레이어별 칩 스택과 상금 구조를 입력합니다. 모든 계산의 출발점이에요.',
                ),
                _Feature(
                  icon: Icons.bar_chart_outlined,
                  title: '결과',
                  body: '각 플레이어의 ICM 지분(₩)을 숫자와 그래프로 보여줍니다.',
                ),
                _Feature(
                  icon: Icons.handshake_outlined,
                  title: '딜',
                  body:
                      'ICM · Chip-chop · Save 세 방식의 분배액을 나란히 비교합니다. '
                      '슬라이더로 위너 적립금(Save)을 조절하면 분배가 실시간으로 바뀝니다.',
                ),
                _Feature(
                  icon: Icons.psychology_outlined,
                  title: '의사결정',
                  body:
                      '버블 팩터(리스크 프리미엄), 올인 콜 필요 에쿼티(p*), '
                      '푸시/폴드 ICM EV를 계산해 콜·폴드 판단을 돕습니다.',
                  last: true,
                ),
              ],
            ),
          ),

          const _Section(
            title: '상단 버튼',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Feature(
                  icon: Icons.save_outlined,
                  title: '저장',
                  body: '현재 입력을 시나리오로 저장합니다.',
                ),
                _Feature(
                  icon: Icons.folder_open_outlined,
                  title: '불러오기',
                  body: '저장해 둔 시나리오를 다시 불러옵니다.',
                ),
                _Feature(
                  icon: Icons.refresh,
                  title: '초기화',
                  body: '입력을 처음 상태로 되돌립니다.',
                ),
                _Feature(
                  icon: Icons.help_outline,
                  title: '도움말',
                  body: '지금 보고 있는 이 화면입니다.',
                  last: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const _Footer(),
        ],
      ),
    );
  }
}

/// muted 헤더 캡션 + 라운드 카드 한 장.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
          child: Text(
            title,
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ApplePanel(child: child),
      ],
    );
  }
}

/// 본문 단락.
class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// 번호가 붙은 사용 순서 한 줄.
class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.title,
    required this.body,
    this.last = false,
  });
  final String n;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.colorScheme.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: t.textTheme.labelMedium?.copyWith(
                color: t.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 색 점 + 용어 + 보조어 + 설명 (딜 범례 색과 매칭).
class _Concept extends StatelessWidget {
  const _Concept({
    required this.color,
    required this.term,
    required this.sub,
    required this.body,
    this.last = false,
  });
  final Color color;
  final String term;
  final String sub;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                term,
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sub,
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: t.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// 아이콘 + 제목 + 설명 (화면/버튼 기능 한 줄).
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: t.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 버전/제작자 푸터.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Text(
            'ICM Split',
            style: t.textTheme.titleMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0 · made by Blanche',
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
