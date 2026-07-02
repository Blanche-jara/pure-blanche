CREATE TABLE IF NOT EXISTS messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  message    TEXT NOT NULL,
  ip_hash    TEXT,
  ip         TEXT,   -- 원본 IP (관리자 전용). 신규 글부터 기록.
  country    TEXT,   -- Cloudflare 지오 (국가 코드)
  region     TEXT,   -- 지역/시도
  city       TEXT,   -- 도시
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
