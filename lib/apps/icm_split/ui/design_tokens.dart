import 'package:flutter/material.dart';

/// "Night rail" — 프리미엄 다크 포커 룸 디자인 토큰 (자체 디자인).
///
/// 깊은 펠트 차콜 배경 + 에메랄드(펠트/머니) 단일 액센트 + 골드(위너/칩) 하이라이트.
/// 플레이어는 실제 카지노 칩 색을 부여해 도메인 정체성을 준다.
class AppColors {
  const AppColors._();

  // ---- 다크(기본) 표면 ----
  static const bg = Color(0xFF0E1311); // 스캐폴드(펠트-블랙, 그린 언더톤)
  static const bgElevated = Color(0xFF131A16); // 상단 바/네비
  static const surface = Color(0xFF18201B); // 카드
  static const surfaceHigh = Color(0xFF202A23); // 입력칸/강조
  static const hairline = Color(0xFF2A352E); // 보더
  static const hairlineSoft = Color(0xFF222B25);

  // ---- 라이트 표면(보조) ----
  static const lightBg = Color(0xFFF1F0E9); // 따뜻한 아이보리
  static const lightSurface = Color(0xFFFBFAF5);
  static const lightHairline = Color(0xFFE2E0D6);

  // ---- 액센트(밝기 공통) ----
  static const felt = Color(0xFF24C283); // primary 에메랄드
  static const feltDeep = Color(0xFF159E66);
  static const feltGlow = Color(0xFF3BE3A0);
  static const gold = Color(0xFFE6B457); // 위너/칩/하이라이트
  static const danger = Color(0xFFE5585D);
  static const onAccent = Color(0xFF052012); // 에메랄드 위 텍스트(다크 그린-블랙)

  // ---- 텍스트(다크) ----
  static const textHi = Color(0xFFF1F4F1);
  static const textMid = Color(0xFFA7B2AB);
  static const textLow = Color(0xFF6C776F);

  // ---- 텍스트(라이트) ----
  static const inkHi = Color(0xFF14201A);
  static const inkMid = Color(0xFF5A655E);

  /// 카지노 칩 색(플레이어 식별). 다크/라이트 공통, 칩 도트엔 링을 둘러 어두운 칩도 보이게.
  static const chips = <Color>[
    Color(0xFFEDEDED), // white
    Color(0xFFE5585D), // red
    Color(0xFF4C8DFF), // blue
    Color(0xFF24C283), // green
    Color(0xFFE6B457), // gold
    Color(0xFFB573E6), // purple
    Color(0xFFF0894C), // orange
    Color(0xFF45C7C7), // teal
    Color(0xFFE57FB0), // pink
    Color(0xFF9AA4AE), // gray
  ];

  static Color chip(int i) => chips[i % chips.length];
}

/// 모서리 반경.
class AppRadii {
  const AppRadii._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20; // 카드/패널
  static const double pill = 999;
}

/// 스페이싱(8px 기반).
class AppSpacing {
  const AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
}

/// 히어로/요약 패널용 미묘한 펠트 그라데이션(깊이감).
LinearGradient feltGradient(Brightness b) => b == Brightness.dark
    ? const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B2620), Color(0xFF141B17)],
      )
    : const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF3F1E8)],
      );

/// 타입 스케일 → Material [TextTheme]. 시스템 폰트 + 강한 위계(큰 숫자가 주인공).
TextTheme pokerTextTheme(Color hi, Color mid) {
  TextStyle s(
    double size,
    FontWeight w,
    double tracking,
    Color c, {
    double height = 1.2,
  }) => TextStyle(
    fontSize: size,
    fontWeight: w,
    letterSpacing: tracking,
    height: height,
    color: c,
  );

  return TextTheme(
    displaySmall: s(34, FontWeight.w700, -0.5, hi, height: 1.08),
    headlineMedium: s(27, FontWeight.w700, -0.4, hi, height: 1.12),
    headlineSmall: s(22, FontWeight.w600, -0.3, hi, height: 1.18),
    titleLarge: s(19, FontWeight.w600, -0.2, hi, height: 1.2),
    titleMedium: s(16, FontWeight.w600, -0.1, hi, height: 1.25),
    titleSmall: s(14, FontWeight.w600, 0, mid, height: 1.3),
    bodyLarge: s(16, FontWeight.w400, 0, hi, height: 1.45),
    bodyMedium: s(14, FontWeight.w400, 0, hi, height: 1.4),
    bodySmall: s(12.5, FontWeight.w400, 0.1, mid, height: 1.35),
    labelLarge: s(15, FontWeight.w600, 0.1, hi, height: 1.0),
    labelMedium: s(12.5, FontWeight.w600, 0.4, mid, height: 1.2),
    labelSmall: s(11, FontWeight.w600, 0.6, mid, height: 1.1),
  );
}
