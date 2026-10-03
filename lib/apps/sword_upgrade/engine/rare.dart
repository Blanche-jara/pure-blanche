class RareWeapon {
  final String id;
  final String name;
  final String description;
  const RareWeapon(this.id, this.name, this.description);
}

const rareWeapons = <RareWeapon>[
  RareWeapon('alexandros', '알렉산드로스', '길고 곧은 사시미 칼날. 적갈색 손잡이에 깃든 첫 번째 전설.'),
  RareWeapon('muramasa', '무라마사', '고요하게 휘어진 칼날. 한 번 뽑으면 쉽게 내려놓을 수 없다.'),
  RareWeapon('seven_branch', '칠지도', '여섯 갈래 가지와 하나의 칼끝. 검이라기보다 하나의 의식.'),
  RareWeapon('softshell', '자라검', '넓적한 자라 등딱지가 손을 감싼다. 느긋해 보여도 날은 예리하다.'),
  RareWeapon('ring_pommel', '환두대도', '둥근 고리 손잡이와 묵직한 외날. 오래된 전사의 흔적.'),
  RareWeapon('obsidian_saw', '흑요석 톱니검', '검은 돌 조각들이 톱니처럼 박힌 칼날. 닿는 순간 갈라진다.'),
  RareWeapon('crescent', '초승달검', '달의 곡선을 품은 비대칭 칼날. 어둠 속에서 빛을 베어낸다.'),
];
