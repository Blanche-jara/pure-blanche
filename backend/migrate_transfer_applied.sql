-- SMTM 송금-건 연결(applied) — 기존 DB에 1회만 실행.
-- 송금 기록 시 그 돈이 덮는 채무 건을 자동 정산 처리하게 되면서,
-- 상계에서 두 번 빼지 않도록 "건에 붙은 금액"을 따로 보관한다.
-- 이미 실행했다면 "duplicate column name" 에러가 난다(정상, 무시).
-- --file 이 인증 오류로 막히면 같은 내용을 --command 로 넣으면 된다.
ALTER TABLE settle_transfers ADD COLUMN applied INTEGER NOT NULL DEFAULT 0;
