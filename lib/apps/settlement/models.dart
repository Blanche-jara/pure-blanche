/// 정산표 — 데이터 모델.
///
/// 금액은 모두 **원 단위 정수(int)**. 부동소수점 오차를 만들지 않는다.
/// 저장은 [SettlementProject.toJson] / [SettlementProject.fromJson] 로
/// JSON 직렬화하며, 그대로 백엔드(D1) 전송에도 쓸 수 있는 형태다.
library;

/// 저장/전송된 시각 문자열을 **로컬 시간** [DateTime] 으로 되돌린다.
///
/// 로컬 저장분은 `DateTime.now().toIso8601String()`(로컬, 오프셋 없음),
/// 서버 응답은 UTC ISO8601(`…Z`)이라 그대로 파싱하면 9시간이 어긋난다.
/// `toLocal()` 은 로컬로 파싱된 값에는 아무 영향이 없다.
DateTime parseTime(String raw) => DateTime.parse(raw).toLocal();

/// 정산 참여자 한 명.
class Member {
  final String id;
  final String name;

  const Member({required this.id, required this.name});

  Member copyWith({String? name}) => Member(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String,
      );
}

/// 지출 한 건. "누가 결제했고, 누구를 위한 돈이었나".
class Expense {
  final String id;

  /// 항목명(예: "1차 삼겹살").
  final String title;

  /// 총 결제 금액(원).
  final int amount;

  /// 결제한 사람의 [Member.id].
  final String payerId;

  /// 이 지출을 나눠 부담할 사람들(결제자 포함 가능). 최소 1명.
  final List<String> participantIds;

  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.participantIds,
    required this.createdAt,
  });

  Expense copyWith({
    String? title,
    int? amount,
    String? payerId,
    List<String>? participantIds,
  }) =>
      Expense(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        payerId: payerId ?? this.payerId,
        participantIds: participantIds ?? this.participantIds,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'payerId': payerId,
        'participantIds': participantIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        title: j['title'] as String,
        amount: (j['amount'] as num).toInt(),
        payerId: j['payerId'] as String,
        participantIds:
            (j['participantIds'] as List).map((e) => e as String).toList(),
        createdAt: parseTime(j['createdAt'] as String),
      );
}

/// 정산용 직접 송금 기록. "A가 B에게 5만원 입금" 처럼 **건과 무관하게**
/// 뭉텅이로 오간 돈. 쌍별 상계에서 그대로 차감된다.
class Transfer {
  final String id;
  final String fromId;
  final String toId;
  final int amount;
  final String memo;
  final DateTime createdAt;

  const Transfer({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.memo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'memo': memo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transfer.fromJson(Map<String, dynamic> j) => Transfer(
        id: j['id'] as String,
        fromId: j['fromId'] as String,
        toId: j['toId'] as String,
        amount: (j['amount'] as num).toInt(),
        memo: (j['memo'] as String?) ?? '',
        createdAt: parseTime(j['createdAt'] as String),
      );
}

/// 정산 프로젝트 하나(= 한 번의 모임/여행).
class SettlementProject {
  final String id;

  /// 서버 공유 코드(8자). 로컬 전용 프로젝트는 null.
  /// 이 값이 있으면 `#/settlement/<code>` 링크로 다른 사람과 공유된다.
  final String? code;

  /// 암호로 잠긴 **비밀 프로젝트**인지. 링크를 알아도 암호를 넣어야 열린다.
  final bool locked;

  final String name;
  final DateTime createdAt;
  final List<Member> members;
  final List<Expense> expenses;
  final List<Transfer> transfers;

  /// 개인 페이지에서 "입금했습니다"로 정산 처리된 채무 건들.
  /// 원소는 [DebtLeg.key] 형식 `"<expenseId>::<debtorId>"`.
  final Set<String> settledLegs;

  const SettlementProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
    required this.expenses,
    required this.transfers,
    required this.settledLegs,
    this.code,
    this.locked = false,
  });

  factory SettlementProject.create({
    required String id,
    required String name,
    required List<Member> members,
    required DateTime createdAt,
  }) =>
      SettlementProject(
        id: id,
        name: name,
        createdAt: createdAt,
        members: members,
        expenses: const [],
        transfers: const [],
        settledLegs: const {},
      );

  SettlementProject copyWith({
    String? name,
    List<Member>? members,
    List<Expense>? expenses,
    List<Transfer>? transfers,
    Set<String>? settledLegs,
  }) =>
      SettlementProject(
        id: id,
        code: code,
        locked: locked,
        name: name ?? this.name,
        createdAt: createdAt,
        members: members ?? this.members,
        expenses: expenses ?? this.expenses,
        transfers: transfers ?? this.transfers,
        settledLegs: settledLegs ?? this.settledLegs,
      );

  /// 서버와 공유되는 프로젝트인지.
  bool get isShared => code != null;

  /// [Member.id] → 이름. 없는 id는 '(삭제됨)'.
  String nameOf(String memberId) {
    for (final m in members) {
      if (m.id == memberId) return m.name;
    }
    return '(삭제됨)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (code != null) 'code': code,
        if (locked) 'locked': true,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
        'settledLegs': settledLegs.toList(),
      };

  factory SettlementProject.fromJson(Map<String, dynamic> j) =>
      SettlementProject(
        id: j['id'] as String,
        code: j['code'] as String?,
        locked: j['locked'] == true,
        name: j['name'] as String,
        createdAt: parseTime(j['createdAt'] as String),
        members: (j['members'] as List)
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList(),
        expenses: (j['expenses'] as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
        transfers: (j['transfers'] as List? ?? const [])
            .map((e) => Transfer.fromJson(e as Map<String, dynamic>))
            .toList(),
        settledLegs: (j['settledLegs'] as List? ?? const [])
            .map((e) => e as String)
            .toSet(),
      );
}

/// 지출 한 건에서 파생된 **채무 한 줄**: `debtor → creditor 로 amount 원`.
/// 저장되지 않는 계산 결과물이다(엔진이 매번 생성).
class DebtLeg {
  final String expenseId;
  final String expenseTitle;
  final String debtorId;
  final String creditorId;
  final int amount;
  final DateTime createdAt;

  /// 지출 총액 / 참여 인원 — 개인 페이지에 "97,000원 ÷ 3명" 으로 표시.
  final int expenseAmount;
  final int participantCount;

  final bool settled;

  const DebtLeg({
    required this.expenseId,
    required this.expenseTitle,
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    required this.createdAt,
    required this.expenseAmount,
    required this.participantCount,
    required this.settled,
  });

  /// [SettlementProject.settledLegs] 에 넣는 키.
  String get key => legKey(expenseId, debtorId);

  static String legKey(String expenseId, String debtorId) =>
      '$expenseId::$debtorId';
}

/// 두 사람 사이의 최종 송금 한 줄(쌍별 상계 결과). `from → to 로 amount 원`.
class PairFlow {
  final String fromId;
  final String toId;
  final int amount;

  /// 상계 전 총 채무액(from → to 방향의 미정산 건 합). 근거 표시용.
  final int rawForward;

  /// 상계 전 총 채무액(to → from 방향).
  final int rawBackward;

  /// 이 쌍에서 이미 오간 직접 송금 순액(from → to 방향, 음수면 반대).
  final int transferred;

  const PairFlow({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.rawForward,
    required this.rawBackward,
    required this.transferred,
  });
}

/// 인원 한 명의 정산 요약.
class MemberSummary {
  final String memberId;

  /// 이 사람이 결제한 총액.
  final int paid;

  /// 이 사람이 부담해야 할 총액(참여한 지출들의 자기 몫 합).
  final int share;

  /// 남에게 보내야 할 최종 금액(쌍별 상계 후 합).
  final int toSend;

  /// 남에게 받아야 할 최종 금액(쌍별 상계 후 합).
  final int toReceive;

  const MemberSummary({
    required this.memberId,
    required this.paid,
    required this.share,
    required this.toSend,
    required this.toReceive,
  });

  /// `paid - share`. 양수면 더 냈다(받을 사람), 음수면 덜 냈다(보낼 사람).
  int get net => paid - share;
}
