CREATE TABLE IF NOT EXISTS messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  message    TEXT NOT NULL,
  ip_hash    TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_messages_id     ON messages(id DESC);
CREATE INDEX IF NOT EXISTS idx_messages_iphash ON messages(ip_hash, created_at);

-- 최초 1회: 환영 메시지(이미 있으면 넣지 않음)
INSERT INTO messages (name, message, created_at)
SELECT 'Blanche', '방명록에 오신 걸 환영합니다!', datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM messages);
