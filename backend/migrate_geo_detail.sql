-- messages 테이블에 지도/ISP/우편번호 컬럼 추가 (v1.4).
-- migrate_ip_geo.sql 이후 실행. 기존 DB에 "한 번만".
--   npx wrangler d1 execute pure-blanche-guestbook --remote --file=./migrate_geo_detail.sql

ALTER TABLE messages ADD COLUMN latitude TEXT;
ALTER TABLE messages ADD COLUMN longitude TEXT;
ALTER TABLE messages ADD COLUMN postal TEXT;
ALTER TABLE messages ADD COLUMN isp TEXT;
