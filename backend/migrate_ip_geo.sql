-- 기존 messages 테이블에 IP/지역 컬럼 추가 (관리자 방명록 화면용).
-- 이미 테이블이 존재하는 프로덕션/기존 로컬 DB에 "한 번만" 실행한다.
-- (SQLite는 ADD COLUMN IF NOT EXISTS 가 없어 재실행 시 "duplicate column" 에러 → 1회만.)
-- 신규 DB는 schema.sql 의 CREATE TABLE 에 이미 포함되어 있으므로 이 파일이 필요 없다.
--
--   npx wrangler d1 execute pure-blanche-guestbook --remote --file=./migrate_ip_geo.sql

ALTER TABLE messages ADD COLUMN ip TEXT;
ALTER TABLE messages ADD COLUMN country TEXT;
ALTER TABLE messages ADD COLUMN region TEXT;
ALTER TABLE messages ADD COLUMN city TEXT;
