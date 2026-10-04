import 'dart:math' as math;
import 'package:flutter/material.dart' hide Ink;
import '../../engine/balance.dart';
import '../../engine/checkpoints.dart';
import '../design_tokens.dart';

class GameGuide extends StatefulWidget {
  const GameGuide({super.key});

  @override
  State<GameGuide> createState() => _GameGuideState();
}

class _GameGuideState extends State<GameGuide> {
  final _scroll = ScrollController();
  int _index = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: math.min(560, constraints.maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (int i = 0; i < _pages.length; i++)
                  ChoiceChip(
                    key: ValueKey('guide-${_pages[i].id}'),
                    label: Text(_pages[i].tab),
                    selected: i == _index,
                    showCheckmark: false,
                    selectedColor: Ink.orange.withValues(alpha: .2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: i == _index ? Ink.gold : Ink.muted,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _select(i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              page.title,
              style: const TextStyle(color: Ink.gold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('guide-body'),
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      button: true,
                      label: '${page.title} 예시 화면 크게 보기',
                      child: InkWell(
                        key: ValueKey('guide-image-${page.id}'),
                        onTap: () => _enlarge(page),
                        child: Container(
                          color: Ink.inset,
                          padding: const EdgeInsets.all(4),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Image.asset(
                              page.asset,
                              scale: 4,
                              filterQuality: FilterQuality.none,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${page.caption} · 눌러서 확대',
                      style: const TextStyle(
                        color: Ink.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < page.tips.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1} ',
                              style: const TextStyle(
                                color: Ink.gold,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                page.tips[i],
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ExpansionTile(
                      key: ValueKey('guide-details-${page.id}'),
                      title: const Text(
                        '세부 수치 · 예외',
                        style: TextStyle(fontSize: 13, color: Ink.muted),
                      ),
                      tilePadding: EdgeInsets.zero,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      children: [
                        for (final (label, value) in page.rules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Ink.gold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    key: const ValueKey('guide-previous'),
                    label: '이전',
                    onPressed: _index == 0 ? null : () => _select(_index - 1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_index + 1} / ${_pages.length}',
                    style: const TextStyle(color: Ink.muted, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: PixelButton(
                    key: const ValueKey('guide-next'),
                    label: '다음',
                    onPressed: _index == _pages.length - 1
                        ? null
                        : () => _select(_index + 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _enlarge(_GuidePage page) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Ink.panel,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      page.title,
                      style: const TextStyle(color: Ink.gold),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '확대 화면 닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.asset(
                  page.asset,
                  scale: 4,
                  filterQuality: FilterQuality.none,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel: page.caption,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '두 손가락이나 휠로 확대할 수 있어요.',
                style: TextStyle(color: Ink.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuidePage {
  final String id, tab, title, caption;
  final List<String> tips;
  final List<(String, String)> rules;
  const _GuidePage(
    this.id,
    this.tab,
    this.title,
    this.caption,
    this.tips,
    this.rules,
  );
  String get asset => 'assets/sword_upgrade/guide/$id.png';
}

final _pages = <_GuidePage>[
  _GuidePage(
    'probability',
    '강화',
    '강화와 장인의 기운',
    '일반 +20 · 1회 실패한 예시',
    [
      '강화해서 가치를 높이고, 팔아서 자금을 모아요. 목표는 일반 +${Balance.maxLevel}!',
      '성공률은 다음 단계 기준. 실패하면 파괴될 수 있어요.',
      '실패하면 기운이 자동 누적! 기본 40% → 44% → 48%.',
    ],
    [
      ('처음 시작', '${money(Balance.startGold)} G / 일반 검 +0'),
      ('일반 성공률', '+0→+1: 95% / +37→+38: 5%'),
      (
        '기운 누적',
        '실패마다 기본 확률의 10% 추가. 40% → 44% → 48%\n최대 10회분: 기본의 2배, 최종 상한 100%. 상점 구매 불필요.',
      ),
      (
        '기운 유지·초기화',
        '단계별로 누적. 보호로 살아남은 실패도 포함.\n파괴·판매·보관·교체 후에도 유지. 해당 단계 성공 때만 초기화.',
      ),
      ('고강과 희귀', '+37→+38은 최대 기운에도 10%. 희귀에는 적용 안 됨.'),
      ('엔딩 뒤에도 계속', '+38 검은 판매·재료 사용 불가. 보관 후 다른 검으로 계속 가능.'),
      ('자금이 바닥나면', '강화 자금도 판매할 잠금 해제 검도 없으면 잡일로 50 G 지급.'),
    ],
  ),
  const _GuidePage(
    'protection',
    '보호',
    '파괴방지와 강화비',
    '90% 보호를 선택한 예시',
    [
      '보호율은 강화 실패 때 검을 지킬 확률이에요.',
      '검 가치에 비례해 시도마다 결제. 성공해도 보호비를 내요.',
      '90%도 파괴될 수 있어요. +0·희귀에는 적용 안 돼요.',
    ],
    [
      ('선택과 결제', '없음·25%·50%·90% 선택. 총 강화비 = 강화비 + 보호비.'),
      ('확률 구분', '보호는 강화 성공률을 올리지 않음. 실패한 뒤 별도로 보호 판정.'),
      ('기본 보호비 / 현재 검 가치', '25% 보호: 6% / 50% 보호: 15% / 90% 보호: 35%'),
      ('고강 할인', '+26~+30: 기본 보호비 ×60%\n+31~+37: 기본 보호비 ×30%\n판매 수수료 할인과는 별개.'),
      ('단계가 바뀌면', '고강일수록 보호비 증가. 파괴 후 낮은 단계로 돌아가면 감소.\n미리 구매·비축하는 보호권은 없음.'),
      ('+0와 희귀', '둘 다 보호비 0 G. +0에서 고른 보호는 +1부터 적용.'),
      ('돈이 부족하면', '총 강화비를 못 내면 정지. 선택한 보호를 자동 해제하지 않음.'),
    ],
  ),
  _GuidePage(
    'storage',
    '보관함',
    '보관해서 돌파하기',
    '재료 검 +15와 잠긴 검 +10',
    [
      '보관하면 새 시작 검을 받아요. 보관 칸은 상점에서 구매!',
      '돌파 재료의 단계·개수는 보관함 아래에서 확인하세요.',
      '재료는 성공 때만 소비! 잠그면 판매·자동 선택을 막아요.',
    ],
    [
      (
        '보관과 교체',
        '일반 계정 최대 ${Balance.slotPrices.length}칸. 칸을 눌러 꺼내거나 모루 검과 교체.\n무료로 받은 시작 검은 한 번 강화한 뒤 판매·보관 가능.',
      ),
      (
        '돌파 재료표',
        Balance.gates.entries
            .map(
              (e) =>
                  '+${e.key}→+${e.key + 1}: +${e.value.minimumLevel} 이상 ${e.value.count}자루',
            )
            .join('\n'),
      ),
      (
        '재료 예외',
        '구매한 +10·20·30 시작 검의 첫 돌파만 재료 면제. 확률·강화비·파괴 위험 유지.\n실패·파괴 때 재료 유지. 희귀·일반 +38은 재료 사용 불가.\n잠긴 검도 직접 고르면 재료 사용 가능하므로 선택 전 확인.',
      ),
      ('자동 강화', '재료가 필요한 돌파 앞에서 정지. 시작 검의 면제 돌파는 자동 진행 가능.'),
      ('판매 수수료', '협상 Lv.0: 25% → Lv.5: 0%\n판매 후에도 선택한 시작점의 새 검 지급.'),
    ],
  ),
  const _GuidePage(
    'rare',
    '희귀 검',
    '희귀는 하트 3개로 시작',
    '알렉산드로스 +0 · 내구도 3',
    [
      '일반 검 실제 파괴 시 발견! 기본 0.5%, 상점에서 최대 5%.',
      '하트 3개로 +10에 도전. 실패하면 단계 유지·하트 −1.',
      '발견하면 자동 정지! 보호·기운·돌파는 적용 안 돼요.',
    ],
    [
      ('발견 판정', '7종이 같은 확률로 등장.\n보호로 살아남은 실패·판매·보관·희귀 파괴는 발견 추첨 없음.'),
      (
        '희귀 성공률',
        '+0→+1: 70% / +9→+10: 25%\n+0·내구도 3으로 등장. 마지막 하트를 잃으면 파괴. 자동 강화 불가.',
      ),
      ('가치와 비용', '기본 가치 = 일반 +10 가치와 파괴된 검 가치 ×3 중 큰 값.\n희귀 강화비 = 현재 가치 ×3%.'),
      ('도감', '발견한 종류와 최고 강화 단계가 기록됨.'),
    ],
  ),
  _GuidePage(
    'shop',
    '상점',
    '원하는 구간부터 다시 시작',
    '일반 +10·+20·+30 시작점',
    [
      '일반 +10·+20·+30부터 재시작. 첫 돌파 재료만 면제!',
      '희귀 +0 시작도 구매 가능. 가격은 일반 +30 시작의 30배!',
      '시작점 선택 후, 파괴·판매·보관한 다음 새 검부터 적용.',
    ],
    [
      ('상점의 영구 강화', '보관함 확장 / 협상력(수수료 감소) / 희귀 발견 확률(최대 5%)'),
      (
        '일반 시작점 가격',
        Checkpoints.normalLevels
            .map((n) => '+$n: ${money(Checkpoints.normalPrice(n))} G')
            .join('\n'),
      ),
      ('상위 시작점', '높은 구간 구매 시 하위 포함. 추가 구매는 총 가격 차액만 결제.'),
      (
        '희귀 시작점',
        '발견한 종류만 구매 가능. 종류마다 ${money(Checkpoints.rarePrice)} G.\n+0·내구도 3 / 기본 가치 ${money(Checkpoints.rareBase)} G.',
      ),
      (
        '선택과 판매',
        '이미 강화한 모루 검은 교체하지 않음. 일반 +0은 언제든 무료 선택.\n시작 검은 한 번 강화 후 판매·보관. 판매액은 강화로 늘어난 가치 기준.',
      ),
    ],
  ),
  const _GuidePage(
    'auto',
    '자동',
    '목표를 정하고 자동 강화',
    '목표 +25를 설정한 예시',
    [
      '목표 선택 → 시작! 보호를 유지하며 파괴돼도 재도전.',
      '목표·재료 돌파·희귀·자금 부족에서 정지. 면제 돌파는 진행!',
      '팝업·탭 이탈에도 정지. 오프라인 진행은 없어요.',
    ],
    [
      (
        '자동 강화 범위',
        '일반 +1~+38 목표 / 무료. 자동 판매·보관·보호 변경 없음.\n탭 복귀·재접속 뒤 자동 재시작 안 됨.',
      ),
      ('정지 시점', '현재 강화 연출을 마친 뒤 정지. 희귀를 자동으로 강화하지 않음.'),
      ('설정', '배경음악 / 효과음 / 전체 음소거 / 짧은 강화 연출 / +20 이상 실수 방지 확인'),
      ('연출 시간', '수동 0.9초 / 자동 0.3초 / 특별 1.2초\n짧은 연출: 0.4초 / 0.15초 / 0.6초'),
      (
        '단축키',
        'Space 강화 / S 판매 / D 보관\n1~4 없음·25%·50%·90% 보호 / 팝업 안에서는 작동 안 됨.',
      ),
    ],
  ),
  const _GuidePage(
    'save',
    '저장',
    '자동 저장과 백업',
    '설정의 백업·초기화 버튼',
    [
      '같은 브라우저·같은 주소에서 자동 저장되고 이어져요.',
      '설정에서 백업 내보내기·가져오기. 가져오면 진행 교체!',
      '게임 초기화는 확인 팝업 후 진행. 먼저 백업하세요.',
    ],
    [
      (
        '다른 환경으로 옮길 때',
        '다른 기기·브라우저·시크릿 창과 저장 공유 안 됨. 백업 코드로 이동.\n브라우저 데이터를 지우면 저장이 사라질 수 있음.',
      ),
      ('초기화 범위', '검·골드·보관함·도감·구매·엔딩·설정 모두 초기화.\n취소하면 유지. 저장 실패 시 현재 진행 보존.'),
      ('치트 계정', '최대 골드·전체 해금·테스트용 보관함 8칸.\n일반 +38과 희귀 7종 +10을 보관.'),
      (
        '치트의 100% 확률',
        '기본 치트는 장인의 기운 최대라 저강이 100%일 수 있음.\n일반 확률용 치트는 초기 기운 0. 치트 자체가 확률을 바꾸지는 않음.',
      ),
    ],
  ),
];
