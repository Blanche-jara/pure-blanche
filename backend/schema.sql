CREATE TABLE IF NOT EXISTS messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  message    TEXT NOT NULL,
  ip_hash    TEXT,
  ip         TEXT,   -- 원본 IP (관리자 전용). 신규 글부터 기록.
  country    TEXT,   -- Cloudflare 지오 (국가 코드)
  region     TEXT,   -- 지역/시도
  city       TEXT,   -- 도시
  latitude   TEXT,   -- 위도(도시 근사) — 지도 링크용
  longitude  TEXT,   -- 경도(도시 근사)
  postal     TEXT,   -- 우편번호
  isp        TEXT,   -- ISP/기관 (cf.asOrganization)
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_messages_id     ON messages(id DESC);
CREATE INDEX IF NOT EXISTS idx_messages_iphash ON messages(ip_hash, created_at);

-- 최초 1회: 환영 메시지(이미 있으면 넣지 않음)
INSERT INTO messages (name, message, created_at)
SELECT 'Blanche', '방명록에 오신 걸 환영합니다!', datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM messages);

-- 코드 프로젝트 페이지 접속 기록. day 는 KST(UTC+9) 기준 날짜 문자열.
CREATE TABLE IF NOT EXISTS page_views (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  page       TEXT NOT NULL,
  ip_hash    TEXT,
  day        TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_pv_page_day ON page_views(page, day);
CREATE INDEX IF NOT EXISTS idx_pv_day      ON page_views(day);

-- Word Guesser 가 수렴한 "오늘의 정답" 보고. variant: kakao5/kordle6/kordle12.
CREATE TABLE IF NOT EXISTS wg_answers (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  variant    TEXT NOT NULL,
  answer     TEXT NOT NULL,
  ip_hash    TEXT,
  day        TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_wg_variant_day ON wg_answers(variant, day);

-- ── 정산표 (docs/SETTLEMENT_BACKEND.md) ────────────────────────────────
-- 공유 코드(code)를 아는 사람이 함께 편집하는 정산 원장.
-- 분할·상계 계산은 전부 클라이언트가 하고, 서버는 원장만 보관한다.
CREATE TABLE IF NOT EXISTS settle_projects (
  id         TEXT PRIMARY KEY,
  code       TEXT NOT NULL UNIQUE,   -- 공유 코드 8자
  name       TEXT NOT NULL,
  owner_hash TEXT,                   -- SHA-256(ownerToken). 프로젝트 삭제 권한 확인용
  pass_salt  TEXT,                   -- 비밀 프로젝트: 암호 솔트(hex). NULL이면 공개
  pass_hash  TEXT,                   -- 비밀 프로젝트: PBKDF2-SHA256(암호, 솔트)
  ip_hash    TEXT,                   -- 생성자 IP 해시 (rate limit)
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sp_code   ON settle_projects(code);
CREATE INDEX IF NOT EXISTS idx_sp_iphash ON settle_projects(ip_hash, created_at);

CREATE TABLE IF NOT EXISTS settle_members (
  id         TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name       TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0   -- 입력 순서 보존(나머지 배분이 이 순서를 따름)
);
CREATE INDEX IF NOT EXISTS idx_sm_project ON settle_members(project_id, sort_order);

CREATE TABLE IF NOT EXISTS settle_expenses (
  id           TEXT PRIMARY KEY,
  project_id   TEXT NOT NULL,
  title        TEXT NOT NULL,
  amount       INTEGER NOT NULL,
  payer_id     TEXT NOT NULL,
  participants TEXT NOT NULL,             -- JSON 배열 (member id)
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_se_project ON settle_expenses(project_id, created_at);

CREATE TABLE IF NOT EXISTS settle_transfers (
  id         TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  from_id    TEXT NOT NULL,
  to_id      TEXT NOT NULL,
  amount     INTEGER NOT NULL,
  memo       TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_st_project ON settle_transfers(project_id, created_at);

-- "입금했습니다" 처리 기록. 한 지출에 대한 한 채무자의 정산 완료 표시.
CREATE TABLE IF NOT EXISTS settle_legs (
  project_id TEXT NOT NULL,
  expense_id TEXT NOT NULL,
  debtor_id  TEXT NOT NULL,
  settled_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (project_id, expense_id, debtor_id)
);
CREATE INDEX IF NOT EXISTS idx_sl_project ON settle_legs(project_id);
