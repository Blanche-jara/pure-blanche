import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Card Widget ---
class _PokerCard extends StatelessWidget {
  final String rank;
  final String suit; // ♠ ♥ ♦ ♣
  final double width;
  final double height;

  const _PokerCard(this.rank, this.suit, {this.width = 38, this.height = 54});

  bool get _isRed => suit == '♥' || suit == '♦';

  @override
  Widget build(BuildContext context) {
    final color = _isRed ? Colors.red.shade600 : Colors.grey.shade900;
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3, offset: const Offset(1, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(rank, style: TextStyle(color: color, fontSize: width * 0.38, fontWeight: FontWeight.w900, height: 1)),
          Text(suit, style: TextStyle(color: color, fontSize: width * 0.32, height: 1)),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final List<List<String>> cards; // [['A', '♠'], ['K', '♠']]
  final double cardWidth;
  final double cardHeight;

  const _CardRow(this.cards, {this.cardWidth = 38, this.cardHeight = 54});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: cards.map((c) => _PokerCard(c[0], c[1], width: cardWidth, height: cardHeight)).toList(),
    );
  }
}

// --- Help Screen ---
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'HOLDEM GUIDE',
            style: GoogleFonts.orbitron(
              color: Colors.amber.shade300,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.red.shade400,
            indicatorWeight: 3,
            labelColor: Colors.red.shade400,
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w400),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'BASICS'),
              Tab(text: 'ACTIONS'),
              Tab(text: 'STREETS'),
              Tab(text: 'HANDS'),
              Tab(text: 'POSITIONS'),
              Tab(text: 'BETTING'),
              Tab(text: 'GAME FLOW'),
              Tab(text: 'RANKINGS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBasicsPage(context),
            _buildActionsPage(context),
            _buildStreetsPage(context),
            _buildHandsPage(context),
            _buildPositionsPage(context),
            _buildBettingPage(context),
            const _GameFlowPage(),
            _buildRankingsPage(context),
          ],
        ),
      ),
    );
  }

  // ===== BASICS =====
  Widget _buildBasicsPage(BuildContext context) {
    return _pageList(context, '기본 용어', [
      _row('SB', 'Small Blind. 딜러 왼쪽 첫 번째 플레이어가 강제로 베팅하는 금액. BB의 절반이 일반적.'),
      _row('BB', 'Big Blind. 딜러 왼쪽 두 번째 플레이어가 강제로 베팅하는 금액. 해당 레벨의 최소 베팅 단위.'),
      _row('Ante', '모든 플레이어가 매 핸드 시작 전 내는 강제 베팅. 액션을 유도하기 위해 중후반부터 적용.'),
      _row('Dealer', '딜러 버튼(D)을 가진 포지션. 매 핸드마다 시계 방향으로 이동하며, 베팅 순서의 기준이 된다.'),
      _row('Level', '블라인드 단계. 일정 시간이 지나면 다음 레벨로 올라가며 SB/BB/Ante가 증가한다.'),
      _row('Break', '휴식 시간. 몇 레벨마다 주어지며, 이 시간 동안 게임이 중단된다.'),
      _row('Pot', '현재 핸드에서 모든 플레이어가 베팅한 칩의 총합.'),
    ]);
  }

  // ===== ACTIONS =====
  Widget _buildActionsPage(BuildContext context) {
    return _pageList(context, '액션', [
      _row('Fold', '패를 포기하고 해당 핸드에서 빠지는 것. 이미 베팅한 칩은 돌려받을 수 없다.'),
      _row('Check', '베팅 없이 차례를 넘기는 것. 앞에 베팅이 없을 때만 가능.'),
      _row('Call', '이전 플레이어의 베팅 금액과 동일하게 따라 베팅하는 것.'),
      _row('Bet', '해당 라운드에서 첫 번째로 칩을 거는 것. 이후 다른 플레이어가 콜/레이즈/폴드를 선택.'),
      _row('Raise', '이전 베팅보다 더 높은 금액으로 베팅. 최소 레이즈는 직전 레이즈 폭 이상.'),
      _row('Re-raise', '레이즈에 대해 다시 레이즈하는 것. 3-Bet, 4-Bet 등으로도 불린다.'),
      _row('All-in', '보유한 칩 전부를 베팅. 올인 후에는 추가 베팅 없이 쇼다운까지 진행.'),
    ]);
  }

  // ===== STREETS =====
  Widget _buildStreetsPage(BuildContext context) {
    return _pageList(context, '게임 진행 단계', [
      _row('Preflop', '커뮤니티 카드가 깔리기 전 단계. 각 플레이어는 2장의 홀카드를 받고 첫 베팅을 진행.'),
      _row('Flop', '커뮤니티 카드 3장이 동시에 공개되는 단계. 두 번째 베팅 라운드가 진행된다.'),
      _row('Turn', '네 번째 커뮤니티 카드가 공개되는 단계. 세 번째 베팅 라운드.'),
      _row('River', '다섯 번째(마지막) 커뮤니티 카드가 공개되는 단계. 최종 베팅 라운드.'),
      _row('Showdown', '최종 베팅 후 남은 플레이어들이 카드를 공개하여 승자를 결정하는 과정.'),
      // Card diagram
      _streetsDiagram(),
    ]);
  }

  Widget _streetsDiagram() {
    return Builder(builder: (context) {
      final sw = MediaQuery.of(context).size.width;
      final cardW = (sw * 0.09).clamp(44.0, 72.0);
      final cardH = cardW * 1.42;
      final gap = cardW * 0.15;
      final labelSize = (sw * 0.015).clamp(10.0, 16.0);

      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2E0E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade900),
          ),
          child: Column(
            children: [
              Text('COMMUNITY CARDS', style: TextStyle(color: Colors.white24, fontSize: labelSize, letterSpacing: 4)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flop (3 cards)
                  _PokerCard('A', '♥', width: cardW, height: cardH),
                  SizedBox(width: gap),
                  _PokerCard('K', '♦', width: cardW, height: cardH),
                  SizedBox(width: gap),
                  _PokerCard('7', '♠', width: cardW, height: cardH),
                  SizedBox(width: gap * 2),
                  // Turn
                  _PokerCard('J', '♣', width: cardW, height: cardH),
                  SizedBox(width: gap * 2),
                  // River
                  _PokerCard('2', '♥', width: cardW, height: cardH),
                ],
              ),
              const SizedBox(height: 12),
              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardW * 3 + gap * 2,
                    child: Center(child: Text('FLOP', style: TextStyle(color: Colors.amber, fontSize: labelSize, fontWeight: FontWeight.bold, letterSpacing: 2))),
                  ),
                  SizedBox(width: gap * 2),
                  SizedBox(
                    width: cardW,
                    child: Center(child: Text('TURN', style: TextStyle(color: Colors.cyan, fontSize: labelSize, fontWeight: FontWeight.bold, letterSpacing: 2))),
                  ),
                  SizedBox(width: gap * 2),
                  SizedBox(
                    width: cardW,
                    child: Center(child: Text('RIVER', style: TextStyle(color: Colors.red.shade300, fontSize: labelSize, fontWeight: FontWeight.bold, letterSpacing: 2))),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ===== HANDS =====
  Widget _buildHandsPage(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final termFs = (sw * 0.022).clamp(14.0, 28.0);
    final descFs = (sw * 0.014).clamp(11.0, 17.0);
    final cardW = (sw * 0.03).clamp(24.0, 40.0);
    final cardH = cardW * 1.42;

    final hands = [
      ['Pocket Pair', '같은 숫자 2장', 'A', '♠', 'A', '♥'],
      ['Suited', '같은 무늬', 'A', '♠', 'K', '♠'],
      ['Offsuit', '다른 무늬', 'A', '♠', 'K', '♥'],
      ['Suited\nConnector', '같은 무늬+연속 숫자', '8', '♥', '9', '♥'],
      ['Offsuit\nConnector', '다른 무늬+연속 숫자', 'T', '♣', 'J', '♦'],
      ['Gap\nConnector', '한 칸 건너뛴 연속', '9', '♠', 'J', '♠'],
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subtitle('핸드 타입'),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: hands.length,
              itemBuilder: (context, i) {
                final h = hands[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(h[0], style: GoogleFonts.orbitron(color: Colors.red.shade500, fontSize: termFs, fontWeight: FontWeight.w800, height: 1.2)),
                            const SizedBox(height: 4),
                            Flexible(child: Text(h[1], style: TextStyle(color: Colors.white60, fontSize: descFs), overflow: TextOverflow.ellipsis, maxLines: 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CardRow([[h[2], h[3]], [h[4], h[5]]], cardWidth: cardW, cardHeight: cardH),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== POSITIONS (landscape: side-by-side, portrait: vertical) =====
  Widget _buildPositionsPage(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isPortrait = sh > sw;
    final termFs = (sw * 0.018).clamp(12.0, 22.0);
    final descFs = (sw * 0.013).clamp(10.0, 16.0);

    final positions = [
      ['SB', 'Small Blind', Colors.blue],
      ['BB', 'Big Blind', Colors.indigo],
      ['UTG', '얼리. 가장 먼저 액션', Colors.red.shade700],
      ['UTG+1', '얼리. UTG 다음', Colors.red.shade400],
      ['LJ', '미들. 로우잭', Colors.orange],
      ['HJ', '미들~레이트. 하이잭', Colors.amber.shade700],
      ['CO', '레이트. 컷오프', Colors.green],
      ['BTN', '레이트. 딜러버튼. 최고 포지션', Colors.teal],
    ];

    Widget positionList({bool compact = false}) {
      final spacing = compact ? 4.0 : 8.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _subtitle('포지션 (8-MAX)'),
          ...positions.map((p) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  children: [
                    Container(
                      width: termFs * 2.2,
                      height: termFs * 2.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (p[2] as Color),
                      ),
                      child: Center(
                        child: Text(
                          (p[0] as String).length <= 3 ? p[0] as String : (p[0] as String).substring(0, 2),
                          style: TextStyle(color: Colors.white, fontSize: descFs, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p[0] as String, style: GoogleFonts.orbitron(color: Colors.red.shade500, fontSize: termFs, fontWeight: FontWeight.w700)),
                          Text(p[1] as String, style: TextStyle(color: Colors.white54, fontSize: descFs)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
    }

    if (isPortrait) {
      // Portrait: vertical layout — position list on top, diagram below
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            positionList(compact: true),
            const SizedBox(height: 8),
            Expanded(child: _positionDiagram()),
          ],
        ),
      );
    }

    // Landscape: side-by-side
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: sw * 0.32,
            child: positionList(),
          ),
          const SizedBox(width: 16),
          Expanded(child: _positionDiagram()),
        ],
      ),
    );
  }

  Widget _positionDiagram() {
    return LayoutBuilder(builder: (context, constraints) {
      final availW = constraints.maxWidth;
      final tableW = availW.clamp(180.0, 600.0);
      final tableH = tableW * 0.7;
      final seatSize = (tableW * 0.08).clamp(24.0, 48.0);
      final fontSize = (tableW * 0.022).clamp(7.0, 13.0);

      // 8 seats positioned around an oval table
      // Positions (clockwise from bottom-center): BTN, SB, BB, UTG, UTG+1, LJ, HJ, CO
      final seats = <_SeatInfo>[
        _SeatInfo('BTN', 'D', Colors.teal, 0.50, 0.92),
        _SeatInfo('SB', 'SB', Colors.blue, 0.18, 0.80),
        _SeatInfo('BB', 'BB', Colors.indigo, 0.05, 0.55),
        _SeatInfo('UTG', '', Colors.red.shade700, 0.10, 0.25),
        _SeatInfo('UTG+1', '', Colors.red.shade400, 0.28, 0.05),
        _SeatInfo('LJ', '', Colors.orange, 0.55, 0.02),
        _SeatInfo('HJ', '', Colors.amber.shade700, 0.78, 0.15),
        _SeatInfo('CO', '', Colors.green, 0.88, 0.42),
      ];

      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Center(
          child: SizedBox(
            width: tableW,
            height: tableH + seatSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Table surface
                Positioned(
                  left: seatSize * 0.5,
                  top: seatSize * 0.5,
                  child: Container(
                    width: tableW - seatSize,
                    height: tableH - seatSize * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(tableH * 0.45),
                      color: const Color(0xFF1B5E20),
                      border: Border.all(color: const Color(0xFF3E2723), width: 6),
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('8-MAX', style: GoogleFonts.orbitron(color: Colors.white24, fontSize: fontSize * 1.4, fontWeight: FontWeight.w700, letterSpacing: 3)),
                          const SizedBox(height: 4),
                          // Arrows showing action direction
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _posLabel('얼리', Colors.red.shade300, fontSize),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward, color: Colors.white24, size: fontSize * 1.2),
                              ),
                              _posLabel('미들', Colors.orange.shade300, fontSize),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward, color: Colors.white24, size: fontSize * 1.2),
                              ),
                              _posLabel('레이트', Colors.green.shade300, fontSize),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Seats
                ...seats.map((s) => Positioned(
                      left: s.x * (tableW - seatSize),
                      top: s.y * (tableH - seatSize * 0.3),
                      child: _buildSeat(s, seatSize, fontSize),
                    )),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _posLabel(String text, Color color, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: fontSize * 0.9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSeat(_SeatInfo seat, double size, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: seat.color,
            boxShadow: [BoxShadow(color: seat.color.withValues(alpha: 0.5), blurRadius: 6)],
          ),
          child: Center(
            child: Text(
              seat.chip.isNotEmpty ? seat.chip : seat.label.length <= 2 ? seat.label : seat.label.substring(0, 2),
              style: TextStyle(color: Colors.white, fontSize: fontSize * 1.1, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(seat.label, style: TextStyle(color: Colors.white70, fontSize: fontSize, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ===== BETTING =====
  Widget _buildBettingPage(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final termFs = (sw * 0.018).clamp(12.0, 22.0);
    final descFs = (sw * 0.012).clamp(10.0, 15.0);
    final tipFs = (sw * 0.011).clamp(9.0, 14.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subtitle('베팅 액션'),
          // === 4 actions in 2x2 grid ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _actionCard('OPEN', '아무도 베팅하지 않은 상태에서 처음으로 베팅.\nBB의 2~3배 크기로 오픈하는 것이 일반적.', Colors.green, termFs, descFs)),
              const SizedBox(width: 12),
              Expanded(child: _actionCard('RAISE', '앞 사람의 베팅보다 더 큰 금액을 베팅.\n최소 레이즈: 직전 베팅/레이즈 폭 이상.', Colors.orange, termFs, descFs)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _actionCard('CALL', '앞 사람의 베팅 금액과 동일하게 따라 베팅.\nBB만큼 콜하는 것을 "림프(Limp)"라 부른다.', Colors.blue, termFs, descFs)),
              const SizedBox(width: 12),
              Expanded(child: _actionCard('FOLD', '핸드를 포기하고 해당 판에서 빠지는 것.\n약한 핸드일수록 빠른 폴드가 칩을 지키는 길.', Colors.red, termFs, descFs)),
            ],
          ),

          const SizedBox(height: 16),
          _subtitle('TIP: 포지션별 오픈 범위'),

          // === Position tips (compact) ===
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availH = constraints.maxHeight;
                final cellH = (availH - 8 * 4) / 5;
                return Column(
                  children: [
                    _posTip('UTG / UTG+1', '얼리', '타이트하게. AA~TT, AK, AQs 위주로 오픈', Colors.red, tipFs, cellH),
                    const SizedBox(height: 8),
                    _posTip('LJ / HJ', '미들', '수딧 커넥터, 중간 포켓 페어 추가 가능', Colors.orange, tipFs, cellH),
                    const SizedBox(height: 8),
                    _posTip('CO', '컷오프', '넓은 범위 오픈. 스틸(블라인드 훔치기) 시도', Colors.green, tipFs, cellH),
                    const SizedBox(height: 8),
                    _posTip('BTN', '딜러', '가장 넓게 오픈. Flop 이후 항상 마지막 액션 = 정보 우위', Colors.teal, tipFs, cellH),
                    const SizedBox(height: 8),
                    _posTip('SB / BB', '블라인드', 'SB: 포지션 불리, 신중하게. BB: 디스카운트로 넓게 디펜스', Colors.indigo, tipFs, cellH),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _posTip(String pos, String type, String desc, Color color, double fs, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: fs * 2.2,
            height: fs * 2.2,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Center(
              child: Text(pos.split(' ')[0], style: TextStyle(color: Colors.white, fontSize: fs * 0.75, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: fs * 4,
            child: Text(type, style: TextStyle(color: color, fontSize: fs, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: Colors.white60, fontSize: fs, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, String desc, Color color, double titleFs, double descFs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(title, style: GoogleFonts.orbitron(color: color, fontSize: titleFs, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ),
          const SizedBox(height: 10),
          Text(desc, style: TextStyle(color: Colors.white70, fontSize: descFs, height: 1.6)),
        ],
      ),
    );
  }

  // ===== RANKINGS =====
  Widget _buildRankingsPage(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final termFs = (sw * 0.018).clamp(12.0, 24.0);
    final descFs = (sw * 0.012).clamp(10.0, 16.0);
    final cardW = (sw * 0.025).clamp(20.0, 36.0);
    final cardH = cardW * 1.42;

    final ranks = [
      ['High Card', '아무 조합도 없음', 'A', '♠', '8', '♥', '5', '♦', '3', '♣', '2', '♠'],
      ['One Pair', '같은 숫자 2장', 'K', '♠', 'K', '♥', '9', '♦', '5', '♣', '2', '♠'],
      ['Two Pair', '같은 숫자 2장 × 2세트', 'Q', '♠', 'Q', '♥', '7', '♦', '7', '♣', '3', '♠'],
      ['Three of a Kind', '같은 숫자 3장 (트립스/셋)', 'J', '♠', 'J', '♥', 'J', '♦', '8', '♣', '2', '♠'],
      ['Straight', '연속된 숫자 5장', '5', '♠', '6', '♥', '7', '♦', '8', '♣', '9', '♠'],
      ['Flush', '같은 무늬 5장', 'A', '♥', 'T', '♥', '8', '♥', '5', '♥', '2', '♥'],
      ['Full House', '3장 + 2장 조합', 'A', '♠', 'A', '♥', 'A', '♦', 'K', '♣', 'K', '♠'],
      ['Four of a Kind', '같은 숫자 4장 (쿼드)', '9', '♠', '9', '♥', '9', '♦', '9', '♣', 'A', '♠'],
      ['Straight Flush', '같은 무늬 + 연속 숫자', '5', '♥', '6', '♥', '7', '♥', '8', '♥', '9', '♥'],
      ['Royal Flush', 'T-J-Q-K-A 같은 무늬', 'T', '♠', 'J', '♠', 'Q', '♠', 'K', '♠', 'A', '♠'],
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subtitle('족보 (약 → 강)'),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemCount: ranks.length,
              itemBuilder: (context, i) {
                final r = ranks[i];
                final cards = <List<String>>[];
                for (int j = 2; j < r.length; j += 2) {
                  cards.add([r[j], r[j + 1]]);
                }
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${i + 1}. ',
                            style: TextStyle(color: Colors.white24, fontSize: termFs, fontWeight: FontWeight.w600),
                          ),
                          Flexible(
                            child: Text(r[0], style: GoogleFonts.orbitron(color: Colors.red.shade500, fontSize: termFs, fontWeight: FontWeight.w800, height: 1.2), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(r[1], style: TextStyle(color: Colors.white54, fontSize: descFs), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Flexible(child: _CardRow(cards, cardWidth: cardW, cardHeight: cardH)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== Shared Helpers =====
  Widget _pageList(BuildContext context, String subtitle, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      children: [_subtitle(subtitle), ...children],
    );
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text, style: const TextStyle(color: Colors.white24, fontSize: 16, letterSpacing: 4)),
    );
  }

  Widget _row(String term, String desc) {
    return Builder(builder: (context) {
      final sw = MediaQuery.of(context).size.width;
      final termW = (sw * 0.28).clamp(110.0, 220.0);
      final termFs = (sw * 0.045).clamp(22.0, 48.0);
      final descFs = (sw * 0.022).clamp(14.0, 22.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: termW,
              child: Text(term, style: GoogleFonts.orbitron(color: Colors.red.shade500, fontSize: termFs, fontWeight: FontWeight.w800, height: 1.2)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: descFs, height: 1.6)),
            ),
          ],
        ),
      );
    });
  }
}

// ===== GAME FLOW PAGE (StatefulWidget with PageView) =====
class _GameFlowPage extends StatefulWidget {
  const _GameFlowPage();

  @override
  State<_GameFlowPage> createState() => _GameFlowPageState();
}

class _GameFlowPageState extends State<_GameFlowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _totalPages = 10;

  // Per-page data: title, description, community cards count, highlighted seat index, show chips, folded seats
  static final _pages = <_FlowPageData>[
    _FlowPageData(
      title: '카드 배분 (Dealing)',
      desc: '딜러(BTN)가 SB부터 시계 방향으로 한 장씩 두 바퀴를 돌려\n각 플레이어에게 2장의 홀카드(비공개)를 배분합니다.',
      communityCards: 0,
      allHaveCards: true,
      highlightSeat: 0, // BTN
      chipSeats: {},
      foldedSeats: {},
      showPot: false,
    ),
    _FlowPageData(
      title: '블라인드 포스팅 (Blinds)',
      desc: 'SB가 스몰 블라인드, BB가 빅 블라인드를 강제 베팅합니다.\nAnte가 있는 레벨에서는 모든 플레이어가 Ante도 냅니다.',
      communityCards: 0,
      allHaveCards: true,
      highlightSeat: -1,
      chipSeats: {1, 2}, // SB, BB
      foldedSeats: {},
      showPot: true,
    ),
    _FlowPageData(
      title: '프리플롭 베팅 (Preflop)',
      desc: 'UTG(BB 왼쪽)부터 시계 방향으로 액션을 시작합니다.\n각 플레이어는 Fold, Call, 또는 Raise를 선택합니다.',
      communityCards: 0,
      allHaveCards: true,
      highlightSeat: 3, // UTG
      chipSeats: {1, 2},
      foldedSeats: {},
      showPot: true,
    ),
    _FlowPageData(
      title: '프리플롭 완료',
      desc: '모든 플레이어의 베팅 금액이 일치하면 프리플롭이 종료됩니다.\nBB는 모두 콜만 한 경우 체크(옵션) 또는 레이즈를 선택할 수 있습니다.\n폴드한 플레이어는 이후 참여하지 않습니다.',
      communityCards: 0,
      allHaveCards: true,
      highlightSeat: -1,
      chipSeats: {},
      foldedSeats: {3, 5, 7}, // UTG, LJ, CO folded
      showPot: true,
    ),
    _FlowPageData(
      title: '플롭 공개 (Flop)',
      desc: '딜러가 한 장을 번(Burn) 한 후, 커뮤니티 카드 3장을 동시에 공개합니다.\n모든 남은 플레이어가 공유하는 공용 카드입니다.',
      communityCards: 3,
      allHaveCards: true,
      highlightSeat: 0,
      chipSeats: {},
      foldedSeats: {3, 5, 7},
      showPot: true,
    ),
    _FlowPageData(
      title: '플롭 베팅 (Flop Betting)',
      desc: 'SB(또는 남은 플레이어 중 가장 얼리)부터 액션을 시작합니다.\n앞에 베팅이 없으면 Check 가능. BTN이 마지막에 액션합니다.\nPostflop부터는 BTN이 항상 마지막 → 레이트 포지션의 이점!',
      communityCards: 3,
      allHaveCards: true,
      highlightSeat: 1, // SB
      chipSeats: {},
      foldedSeats: {3, 5, 7},
      showPot: true,
    ),
    _FlowPageData(
      title: '턴 공개 (Turn)',
      desc: '딜러가 한 장을 번(Burn) 한 후, 4번째 커뮤니티 카드를 공개합니다.\n남은 플레이어들의 핸드 강도가 더 명확해집니다.',
      communityCards: 4,
      allHaveCards: true,
      highlightSeat: 0,
      chipSeats: {},
      foldedSeats: {3, 4, 5, 7}, // more folds
      showPot: true,
    ),
    _FlowPageData(
      title: '턴 베팅 (Turn Betting)',
      desc: '플롭과 동일한 순서로 베팅 라운드가 진행됩니다.\n턴부터는 베팅 사이즈가 커지는 경향이 있습니다.\n팟이 커질수록 결정의 무게도 커집니다.',
      communityCards: 4,
      allHaveCards: true,
      highlightSeat: 1,
      chipSeats: {},
      foldedSeats: {3, 4, 5, 7},
      showPot: true,
    ),
    _FlowPageData(
      title: '리버 공개 & 베팅 (River)',
      desc: '딜러가 마지막 5번째 커뮤니티 카드를 공개합니다.\n최종 베팅 라운드가 진행됩니다. 이 라운드가 끝나면 쇼다운으로 진행합니다.\n더 이상 카드가 공개되지 않으므로 블러핑의 마지막 기회입니다.',
      communityCards: 5,
      allHaveCards: true,
      highlightSeat: 1,
      chipSeats: {},
      foldedSeats: {3, 4, 5, 7},
      showPot: true,
    ),
    _FlowPageData(
      title: '쇼다운 (Showdown)',
      desc: '최종 베팅 후 남은 플레이어들이 카드를 공개합니다.\n홀카드 2장 + 커뮤니티 5장 중 가장 좋은 5장 조합으로 승부합니다.\n가장 높은 족보를 가진 플레이어가 팟을 획득합니다.',
      communityCards: 5,
      allHaveCards: true,
      highlightSeat: -1,
      chipSeats: {},
      foldedSeats: {3, 4, 5, 7},
      showPot: true,
      isShowdown: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final titleFs = (sw * 0.022).clamp(14.0, 28.0);
    final descFs = (sw * 0.014).clamp(11.0, 18.0);
    final navFs = (sw * 0.014).clamp(11.0, 16.0);

    return Column(
      children: [
        // Top: step indicator + navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Step indicator
              Text(
                'STEP ${_currentPage + 1} / $_totalPages',
                style: GoogleFonts.orbitron(
                  color: Colors.white38,
                  fontSize: navFs,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              // Dot indicators
              ...List.generate(_totalPages, (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentPage ? Colors.amber : Colors.white12,
                ),
              )),
              const Spacer(),
              // Nav buttons
              IconButton(
                icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.white70 : Colors.white12, size: 28),
                onPressed: _currentPage > 0 ? _prevPage : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: _currentPage < _totalPages - 1 ? Colors.white70 : Colors.white12, size: 28),
                onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
              ),
            ],
          ),
        ),

        // Main content: PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _totalPages,
            itemBuilder: (context, i) {
              final page = _pages[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Table diagram (center, expanded)
                    Expanded(
                      child: Center(
                        child: _buildFlowTable(context, page),
                      ),
                    ),
                    // Description (bottom)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.title,
                            style: GoogleFonts.orbitron(
                              color: Colors.amber.shade300,
                              fontSize: titleFs,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            page.desc,
                            style: TextStyle(color: Colors.white70, fontSize: descFs, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // Community card examples
  static const _communityCardData = [
    ['A', '♥'], ['K', '♦'], ['7', '♠'], ['J', '♣'], ['2', '♥'],
  ];

  // Player hole cards (for showdown)
  static const _playerHoleCards = [
    [['Q', '♠'], ['Q', '♥']], // BTN
    [['9', '♦'], ['T', '♦']], // SB
    [['A', '♣'], ['K', '♣']], // BB - winner
    [['5', '♠'], ['6', '♠']], // UTG (folded)
    [['J', '♥'], ['3', '♦']], // UTG+1 (folded)
    [['8', '♣'], ['2', '♣']], // LJ (folded)
    [['T', '♠'], ['9', '♠']], // HJ
    [['4', '♥'], ['4', '♦']], // CO (folded)
  ];

  Widget _buildFlowTable(BuildContext context, _FlowPageData page) {
    final sw = MediaQuery.of(context).size.width;
    final tableW = (sw * 0.65).clamp(280.0, 550.0);
    final tableH = tableW * 0.65;
    final seatSize = (sw * 0.04).clamp(24.0, 40.0);
    final fontSize = (sw * 0.011).clamp(7.0, 12.0);
    final cardW = (sw * 0.025).clamp(18.0, 32.0);
    final cardH = cardW * 1.42;

    final seats = <_SeatInfo>[
      _SeatInfo('BTN', 'D', Colors.teal, 0.50, 0.92),
      _SeatInfo('SB', 'SB', Colors.blue, 0.15, 0.80),
      _SeatInfo('BB', 'BB', Colors.indigo, 0.03, 0.50),
      _SeatInfo('UTG', 'U', Colors.red.shade700, 0.08, 0.20),
      _SeatInfo('UTG+1', 'U1', Colors.red.shade400, 0.28, 0.03),
      _SeatInfo('LJ', 'LJ', Colors.orange, 0.55, 0.00),
      _SeatInfo('HJ', 'HJ', Colors.amber.shade700, 0.78, 0.12),
      _SeatInfo('CO', 'CO', Colors.green, 0.90, 0.40),
    ];

    return SizedBox(
      width: tableW,
      height: tableH + seatSize * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Table surface
          Positioned(
            left: seatSize * 0.5,
            top: seatSize * 0.5,
            child: Container(
              width: tableW - seatSize,
              height: tableH - seatSize * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tableH * 0.45),
                color: const Color(0xFF1B5E20),
                border: Border.all(color: const Color(0xFF3E2723), width: 5),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
              ),
            ),
          ),

          // Community cards (center of table)
          if (page.communityCards > 0)
            Positioned(
              left: (tableW - (cardW * page.communityCards + 4 * (page.communityCards - 1))) / 2,
              top: tableH * 0.35,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(page.communityCards, (i) {
                  final c = _communityCardData[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: _PokerCard(c[0], c[1], width: cardW, height: cardH),
                  );
                }),
              ),
            ),

          // Pot indicator
          if (page.showPot)
            Positioned(
              left: tableW * 0.35,
              top: tableH * 0.55,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.amber.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.amber, size: fontSize),
                    SizedBox(width: 3),
                    Text('POT', style: TextStyle(color: Colors.amber, fontSize: fontSize, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

          // Seats
          ...List.generate(seats.length, (i) {
            final s = seats[i];
            final isFolded = page.foldedSeats.contains(i);
            final isHighlighted = page.highlightSeat == i;
            final showCards = page.allHaveCards && !isFolded;
            final showFaceUp = page.isShowdown && !isFolded;

            return Positioned(
              left: s.x * (tableW - seatSize),
              top: s.y * (tableH - seatSize * 0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seat circle
                  Container(
                    width: seatSize,
                    height: seatSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFolded ? Colors.grey.shade800 : s.color,
                      boxShadow: isHighlighted
                          ? [BoxShadow(color: Colors.yellow.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 2)]
                          : [BoxShadow(color: s.color.withValues(alpha: isFolded ? 0.1 : 0.4), blurRadius: 4)],
                      border: isHighlighted ? Border.all(color: Colors.yellow, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        s.chip,
                        style: TextStyle(
                          color: isFolded ? Colors.white24 : Colors.white,
                          fontSize: fontSize * 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label
                  Text(
                    s.label,
                    style: TextStyle(
                      color: isFolded ? Colors.white24 : Colors.white70,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Cards below seat
                  if (showCards && !showFaceUp)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFaceDownCard(cardW * 0.7, cardH * 0.7),
                        _buildFaceDownCard(cardW * 0.7, cardH * 0.7),
                      ],
                    ),
                  if (showFaceUp)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PokerCard(_playerHoleCards[i][0][0], _playerHoleCards[i][0][1], width: cardW * 0.7, height: cardH * 0.7),
                        _PokerCard(_playerHoleCards[i][1][0], _playerHoleCards[i][1][1], width: cardW * 0.7, height: cardH * 0.7),
                      ],
                    ),
                  if (isFolded)
                    Text('FOLD', style: TextStyle(color: Colors.red.shade300.withValues(alpha: 0.5), fontSize: fontSize * 0.8, fontWeight: FontWeight.w700)),
                  // Chip indicator for blinds
                  if (page.chipSeats.contains(i))
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        i == 1 ? 'SB' : 'BB',
                        style: TextStyle(color: Colors.amber, fontSize: fontSize * 0.8, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            );
          }),

          // Action arrow for highlighted seat
          if (page.highlightSeat >= 0 && page.highlightSeat < seats.length)
            Positioned(
              left: tableW * 0.38,
              top: tableH * 0.18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.yellow.withValues(alpha: 0.7), size: fontSize * 1.5),
                  Text(
                    'ACTION',
                    style: TextStyle(color: Colors.yellow.withValues(alpha: 0.7), fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceDownCard(double w, double h) {
    return Container(
      width: w,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white24, width: 0.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Center(
        child: Text('?', style: TextStyle(color: Colors.white38, fontSize: w * 0.4, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _FlowPageData {
  final String title;
  final String desc;
  final int communityCards;
  final bool allHaveCards;
  final int highlightSeat; // -1 = none
  final Set<int> chipSeats;
  final Set<int> foldedSeats;
  final bool showPot;
  final bool isShowdown;

  const _FlowPageData({
    required this.title,
    required this.desc,
    required this.communityCards,
    required this.allHaveCards,
    required this.highlightSeat,
    required this.chipSeats,
    required this.foldedSeats,
    required this.showPot,
    this.isShowdown = false,
  });
}

class _SeatInfo {
  final String label;
  final String chip;
  final Color color;
  final double x;
  final double y;

  const _SeatInfo(this.label, this.chip, this.color, this.x, this.y);
}
