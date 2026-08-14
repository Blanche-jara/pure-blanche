-- SMTM 비밀 프로젝트(암호 잠금) — 기존 DB에 1회만 실행.
-- settle_projects 는 CREATE TABLE IF NOT EXISTS 라 이미 만들어진 테이블엔
-- 새 컬럼이 추가되지 않는다. 그래서 ALTER 로 따로 붙인다.
-- 이미 실행했다면 "duplicate column name" 에러가 난다(정상, 무시).
ALTER TABLE settle_projects ADD COLUMN pass_salt TEXT;
ALTER TABLE settle_projects ADD COLUMN pass_hash TEXT;
