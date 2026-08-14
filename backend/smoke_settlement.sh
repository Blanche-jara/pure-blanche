#!/bin/bash
# SMTM(정산표) API 인수 기준 스모크 테스트 (docs/SETTLEMENT_BACKEND.md 7장)
#
#   bash backend/smoke_settlement.sh                          # 로컬 wrangler dev
#   API=https://api.pure-blanche.com bash backend/...          # 배포 확인
#
# 만든 정산표는 마지막에 소유자 토큰으로 지운다(프로덕션에 찌꺼기를 남기지 않는다).
API=${API:-http://localhost:8787}
pass=0; fail=0
check() { # check <설명> <실제> <기대>
  if [ "$2" = "$3" ]; then echo "  ✅ $1"; pass=$((pass+1));
  else echo "  ❌ $1  (실제: $2 / 기대: $3)"; fail=$((fail+1)); fi
}

echo "1) 프로젝트 생성"
C=$(curl -s -X POST $API/api/settlement -H 'Content-Type: application/json' \
  -d '{"name":"정산 테스트","members":["블랑쉬","민수","지연"]}')
CODE=$(echo "$C" | jq -r .project.code)
OWNER=$(echo "$C" | jq -r .ownerToken)
M1=$(echo "$C" | jq -r .project.members[0].id)
M2=$(echo "$C" | jq -r .project.members[1].id)
M3=$(echo "$C" | jq -r .project.members[2].id)
check "code 8자 발급" "$(echo -n "$CODE" | wc -c | tr -d ' ')" "8"
check "ownerToken 32자" "$(echo -n "$OWNER" | wc -c | tr -d ' ')" "32"
check "인원 3명 순서 보존" "$(echo "$C" | jq -r '[.project.members[].name]|join(",")')" "블랑쉬,민수,지연"

echo "2) 연속 생성 rate limit"
R=$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/settlement \
  -H 'Content-Type: application/json' -d '{"name":"x","members":["a","b"]}')
check "10초 내 재생성 429" "$R" "429"

echo "3) 조회"
check "GET 성공" "$(curl -s $API/api/settlement/$CODE | jq -r .project.name)" "정산 테스트"
check "없는 코드 404" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/settlement/zzzzzzzz)" "404"
check "형식 틀린 코드 404" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/settlement/ab)" "404"

echo "4) 지출 추가"
E=$(curl -s -X POST $API/api/settlement/$CODE/expenses -H 'Content-Type: application/json' \
  -d "{\"title\":\"1차 삼겹살\",\"amount\":97000,\"payerId\":\"$M1\",\"participantIds\":[\"$M1\",\"$M2\",\"$M3\"]}")
EID=$(echo "$E" | jq -r .project.expenses[0].id)
check "지출 1건" "$(echo "$E" | jq '.project.expenses|length')" "1"
check "금액 보존" "$(echo "$E" | jq -r .project.expenses[0].amount)" "97000"
check "참여자 3명" "$(echo "$E" | jq '.project.expenses[0].participantIds|length')" "3"
check "잘못된 결제자 400" "$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/settlement/$CODE/expenses \
  -H 'Content-Type: application/json' -d "{\"title\":\"x\",\"amount\":100,\"payerId\":\"nope\",\"participantIds\":[\"$M1\"]}")" "400"
check "금액 0 → 400" "$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/settlement/$CODE/expenses \
  -H 'Content-Type: application/json' -d "{\"title\":\"x\",\"amount\":0,\"payerId\":\"$M1\",\"participantIds\":[\"$M1\"]}")" "400"

echo "5) 입금 처리"
L=$(curl -s -X PUT $API/api/settlement/$CODE/legs -H 'Content-Type: application/json' \
  -d "{\"legs\":[{\"expenseId\":\"$EID\",\"debtorId\":\"$M2\"}],\"settled\":true}")
check "settledLegs 1건" "$(echo "$L" | jq '.project.settledLegs|length')" "1"
check "leg 키 형식" "$(echo "$L" | jq -r .project.settledLegs[0])" "$EID::$M2"
L2=$(curl -s -X PUT $API/api/settlement/$CODE/legs -H 'Content-Type: application/json' \
  -d "{\"legs\":[{\"expenseId\":\"$EID\",\"debtorId\":\"$M2\"}],\"settled\":false}")
check "입금 취소 시 제거" "$(echo "$L2" | jq '.project.settledLegs|length')" "0"
check "결제자 본인 leg 400" "$(curl -s -o /dev/null -w '%{http_code}' -X PUT $API/api/settlement/$CODE/legs \
  -H 'Content-Type: application/json' -d "{\"legs\":[{\"expenseId\":\"$EID\",\"debtorId\":\"$M1\"}],\"settled\":true}")" "400"

echo "6) 지출 수정 시 정산 표시 정리"
curl -s -o /dev/null -X PUT $API/api/settlement/$CODE/legs -H 'Content-Type: application/json' \
  -d "{\"legs\":[{\"expenseId\":\"$EID\",\"debtorId\":\"$M2\"},{\"expenseId\":\"$EID\",\"debtorId\":\"$M3\"}],\"settled\":true}"
U=$(curl -s -X PATCH $API/api/settlement/$CODE/expenses/$EID -H 'Content-Type: application/json' \
  -d "{\"title\":\"1차 삼겹살\",\"amount\":60000,\"payerId\":\"$M1\",\"participantIds\":[\"$M1\",\"$M2\"]}")
check "빠진 참여자의 정산 표시 삭제" "$(echo "$U" | jq '.project.settledLegs|length')" "1"
check "남은 표시는 민수 건" "$(echo "$U" | jq -r .project.settledLegs[0])" "$EID::$M2"

echo "7) 직접 송금"
T=$(curl -s -X POST $API/api/settlement/$CODE/transfers -H 'Content-Type: application/json' \
  -d "{\"fromId\":\"$M3\",\"toId\":\"$M1\",\"amount\":5000,\"memo\":\"계좌이체\"}")
TID=$(echo "$T" | jq -r .project.transfers[0].id)
check "송금 1건" "$(echo "$T" | jq '.project.transfers|length')" "1"
check "메모 보존" "$(echo "$T" | jq -r .project.transfers[0].memo)" "계좌이체"
check "자기 자신 송금 400" "$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/settlement/$CODE/transfers \
  -H 'Content-Type: application/json' -d "{\"fromId\":\"$M1\",\"toId\":\"$M1\",\"amount\":100}")" "400"
check "송금 삭제" "$(curl -s -X DELETE $API/api/settlement/$CODE/transfers/$TID | jq '.project.transfers|length')" "0"

echo "8) 인원"
A=$(curl -s -X POST $API/api/settlement/$CODE/members -H 'Content-Type: application/json' -d '{"name":"현우"}')
M4=$(echo "$A" | jq -r '.project.members[3].id')
check "인원 추가 후 4명" "$(echo "$A" | jq '.project.members|length')" "4"
check "이름 변경" "$(curl -s -X PATCH $API/api/settlement/$CODE/members/$M4 -H 'Content-Type: application/json' \
  -d '{"name":"현우B"}' | jq -r '.project.members[3].name')" "현우B"
check "미사용 인원 삭제 가능" "$(curl -s -X DELETE $API/api/settlement/$CODE/members/$M4 | jq '.project.members|length')" "3"
check "지출에 얽힌 인원 삭제 409" "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE $API/api/settlement/$CODE/members/$M2)" "409"

echo "9) 이름 변경 / 권한"
check "프로젝트 이름 변경" "$(curl -s -X PATCH $API/api/settlement/$CODE -H 'Content-Type: application/json' \
  -d '{"name":"이름 바꿈"}' | jq -r .project.name)" "이름 바꿈"
check "토큰 없이 삭제 401" "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE $API/api/settlement/$CODE)" "401"
check "틀린 토큰 삭제 401" "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE $API/api/settlement/$CODE \
  -H 'Authorization: Bearer wrongtoken')" "401"

echo "10) CORS"
check "preflight 204" "$(curl -s -o /dev/null -w '%{http_code}' -X OPTIONS $API/api/settlement \
  -H 'Origin: https://pure-blanche.com')" "204"
check "허용 Origin echo" "$(curl -s -D - -o /dev/null $API/api/settlement/$CODE -H 'Origin: http://localhost:8085' \
  | grep -i '^access-control-allow-origin' | tr -d '\r' | awk '{print $2}')" "http://localhost:8085"

echo "11) 방명록 회귀"
check "GET /api/guestbook 200" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/guestbook)" "200"
check "알 수 없는 경로 404" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/nope)" "404"

echo "12) 비밀 프로젝트(암호 잠금)"
check "공개 프로젝트는 locked=false" "$(curl -s $API/api/settlement/$CODE | jq -r .project.locked)" "false"
sleep 11   # 생성 rate limit 회피
P=$(curl -s -X POST $API/api/settlement -H 'Content-Type: application/json' \
  -d '{"name":"비밀 여행","members":["A","B","C"],"password":"tr1p2026"}')
PCODE=$(echo "$P" | jq -r .project.code); PTOK=$(echo "$P" | jq -r .accessToken)
POWN=$(echo "$P" | jq -r .ownerToken)
check "생성 시 locked=true" "$(echo "$P" | jq -r .project.locked)" "true"
check "생성 시 접근 토큰 발급" "$(echo -n "$PTOK" | wc -c | tr -d ' ')" "64"
check "토큰 없이 조회 → 401" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/settlement/$PCODE)" "401"
check "에러 코드 password_required" "$(curl -s $API/api/settlement/$PCODE | jq -r .error)" "password_required"
check "이름은 알려준다(입력 화면용)" "$(curl -s $API/api/settlement/$PCODE | jq -r .name)" "비밀 여행"
check "토큰으로 조회 성공" "$(curl -s $API/api/settlement/$PCODE -H "Authorization: Bearer $PTOK" | jq -r .project.name)" "비밀 여행"
check "틀린 암호 → 401" "$(curl -s -X POST $API/api/settlement/$PCODE/unlock \
  -H 'Content-Type: application/json' -d '{"password":"wrong"}' | jq -r .error)" "bad_password"
check "맞는 암호 → 같은 토큰" "$(curl -s -X POST $API/api/settlement/$PCODE/unlock \
  -H 'Content-Type: application/json' -d '{"password":"tr1p2026"}' | jq -r .accessToken)" "$PTOK"
PM1=$(curl -s $API/api/settlement/$PCODE -H "Authorization: Bearer $PTOK" | jq -r '.project.members[0].id')
check "토큰 없이 편집 → 401" "$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/settlement/$PCODE/expenses \
  -H 'Content-Type: application/json' -d "{\"title\":\"x\",\"amount\":1000,\"payerId\":\"$PM1\",\"participantIds\":[\"$PM1\"]}")" "401"
check "토큰으로 편집 성공" "$(curl -s -X POST $API/api/settlement/$PCODE/expenses \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $PTOK" \
  -d "{\"title\":\"x\",\"amount\":1000,\"payerId\":\"$PM1\",\"participantIds\":[\"$PM1\"]}" | jq '.project.expenses|length')" "1"
check "소유자 토큰으로도 열림" "$(curl -s $API/api/settlement/$PCODE -H "Authorization: Bearer $POWN" | jq -r .project.name)" "비밀 여행"
curl -s -o /dev/null -X DELETE $API/api/settlement/$PCODE -H "Authorization: Bearer $POWN"
sleep 11
check "짧은 암호 거부" "$(curl -s -X POST $API/api/settlement \
  -H 'Content-Type: application/json' -d '{"name":"x","members":["a","b"],"password":"1"}' | jq -r .error)" "bad_password"

echo "13) 소유자 토큰으로 삭제"
check "삭제 성공" "$(curl -s -X DELETE $API/api/settlement/$CODE -H "Authorization: Bearer $OWNER" | jq -r .ok)" "true"
check "삭제 후 404" "$(curl -s -o /dev/null -w '%{http_code}' $API/api/settlement/$CODE)" "404"

echo
echo "통과 $pass / 실패 $fail"
[ "$fail" -eq 0 ]
