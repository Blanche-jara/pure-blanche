/**
 * Pure Blanche 방명록 API — Cloudflare Worker (ES module).
 *
 * 계약: docs/GUESTBOOK_BACKEND.md (이 문서가 정답).
 *   - GET  /api/guestbook        → 200 {messages:[{id,name,message,created_at}]} (id DESC, ≤100)
 *   - POST /api/guestbook        → 201 {message:{...}}  / 4xx,5xx {error,detail}
 *   - GET  / 또는 /health        → 200 {ok:true,service:"pure-blanche-guestbook"}
 *   - OPTIONS                    → 204 (CORS preflight)
 *
 * D1 바인딩: env.DB   /   IP_SALT: Worker secret.
 */

const SERVICE = "pure-blanche-guestbook";

// 허용 Origin 목록. localhost/127.0.0.1 은 임의 포트를 허용한다.
const EXACT_ORIGINS = new Set([
  "https://pure-blanche.com",
  "https://www.pure-blanche.com",
]);
const LOCAL_ORIGIN_RE = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
const DEFAULT_ORIGIN = "https://pure-blanche.com";

// 스팸(링크) 탐지 규칙.
const SPAM_RES = [/https?:\/\//i, /\bwww\.\w/i, /\[url[=\]]/i];

const NAME_MAX = 30;
const MESSAGE_MAX = 500;
const TOO_FAST_SECONDS = 30;
const DAILY_LIMIT = 20;

// ── CORS ──────────────────────────────────────────────────────────────
function resolveOrigin(request) {
  const origin = request.headers.get("Origin");
  if (origin && (EXACT_ORIGINS.has(origin) || LOCAL_ORIGIN_RE.test(origin))) {
    return origin;
  }
  return DEFAULT_ORIGIN;
}

function corsHeaders(request) {
  return {
    "Access-Control-Allow-Origin": resolveOrigin(request),
    "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    Vary: "Origin",
  };
}

function json(body, status, request) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...corsHeaders(request),
    },
  });
}

function errorResponse(status, code, detail, request) {
  return json({ error: code, detail }, status, request);
}

// ── 유틸 ──────────────────────────────────────────────────────────────
async function ipHash(env, request) {
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const salt = env.IP_SALT || "dev-salt"; // 로컬 개발 fallback. 프로덕션은 secret 주입.
  const data = new TextEncoder().encode(`${salt}:${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function isSpam(text) {
  return SPAM_RES.some((re) => re.test(text));
}

// ── 관리자 인증 ───────────────────────────────────────────────────────
// 길이를 먼저 비교하므로 길이는 노출되나, 192bit+ 랜덤 토큰엔 무의미.
function safeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

// Authorization: Bearer <ADMIN_TOKEN> 가 Worker secret 과 일치하면 관리자.
function isAdmin(env, request) {
  const expected = env.ADMIN_TOKEN;
  if (!expected) return false; // 시크릿 미설정 시 관리자 기능 비활성(안전 기본값).
  const auth = request.headers.get("Authorization") || "";
  const m = auth.match(/^Bearer\s+(.+)$/i);
  return m ? safeEqual(m[1], expected) : false;
}

// ── 핸들러 ────────────────────────────────────────────────────────────
async function handleList(env, request) {
  const { results } = await env.DB.prepare(
    "SELECT id, name, message, created_at FROM messages ORDER BY id DESC LIMIT 100"
  ).all();
  return json({ messages: results ?? [] }, 200, request);
}

async function handleCreate(env, request) {
  // 1) JSON 파싱
  let body;
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  if (body === null || typeof body !== "object") {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";
  const message = typeof body.message === "string" ? body.message.trim() : "";

  // 2) 검증
  if (name.length === 0 || message.length === 0) {
    return errorResponse(400, "empty", "이름과 메시지를 모두 입력해주세요.", request);
  }
  if (name.length > NAME_MAX) {
    return errorResponse(400, "name_too_long", "이름은 30자 이하로 입력해주세요.", request);
  }
  if (message.length > MESSAGE_MAX) {
    return errorResponse(400, "message_too_long", "메시지는 500자 이하로 입력해주세요.", request);
  }

  // 3) 스팸(링크)
  if (isSpam(name) || isSpam(message)) {
    return errorResponse(422, "spam", "링크는 작성할 수 없습니다.", request);
  }

  // 4) Rate limit (IP 해시 기준)
  const hash = await ipHash(env, request);

  const recent = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM messages WHERE ip_hash = ? AND created_at > datetime('now', ?)"
  )
    .bind(hash, `-${TOO_FAST_SECONDS} seconds`)
    .first();
  if ((recent?.c ?? 0) > 0) {
    return errorResponse(429, "too_fast", "잠시 후 다시 시도해주세요.", request);
  }

  const daily = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM messages WHERE ip_hash = ? AND created_at > datetime('now', '-24 hours')"
  )
    .bind(hash)
    .first();
  if ((daily?.c ?? 0) >= DAILY_LIMIT) {
    return errorResponse(429, "daily_limit", "하루 작성 한도를 초과했습니다.", request);
  }

  // 5) 저장 + 생성 객체 반환 (원본 IP 미저장 — ip_hash만)
  const row = await env.DB.prepare(
    "INSERT INTO messages (name, message, ip_hash) VALUES (?, ?, ?) RETURNING id, name, message, created_at"
  )
    .bind(name, message, hash)
    .first();

  return json({ message: row }, 201, request);
}

// 관리자 전용: 글 삭제. DELETE /api/guestbook/:id
async function handleDelete(env, request, id) {
  if (!isAdmin(env, request)) {
    return errorResponse(401, "unauthorized", "관리자 인증이 필요합니다.", request);
  }
  const res = await env.DB.prepare("DELETE FROM messages WHERE id = ?")
    .bind(id)
    .run();
  if ((res.meta?.changes ?? 0) === 0) {
    return errorResponse(404, "not_found", "해당 글을 찾을 수 없습니다.", request);
  }
  return json({ ok: true, deleted: id }, 200, request);
}

// 관리자 전용: 글 수정(name/message). PATCH /api/guestbook/:id
// 관리자는 신뢰 주체이므로 스팸/링크 필터는 적용하지 않는다.
async function handleUpdate(env, request, id) {
  if (!isAdmin(env, request)) {
    return errorResponse(401, "unauthorized", "관리자 인증이 필요합니다.", request);
  }
  let body;
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  if (body === null || typeof body !== "object") {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }

  const sets = [];
  const binds = [];
  if (typeof body.name === "string") {
    const name = body.name.trim();
    if (name.length === 0)
      return errorResponse(400, "empty", "이름을 입력해주세요.", request);
    if (name.length > NAME_MAX)
      return errorResponse(400, "name_too_long", "이름은 30자 이하로 입력해주세요.", request);
    sets.push("name = ?");
    binds.push(name);
  }
  if (typeof body.message === "string") {
    const message = body.message.trim();
    if (message.length === 0)
      return errorResponse(400, "empty", "메시지를 입력해주세요.", request);
    if (message.length > MESSAGE_MAX)
      return errorResponse(400, "message_too_long", "메시지는 500자 이하로 입력해주세요.", request);
    sets.push("message = ?");
    binds.push(message);
  }
  if (sets.length === 0) {
    return errorResponse(400, "empty", "수정할 내용이 없습니다.", request);
  }

  binds.push(id);
  const row = await env.DB.prepare(
    `UPDATE messages SET ${sets.join(", ")} WHERE id = ? RETURNING id, name, message, created_at`
  )
    .bind(...binds)
    .first();
  if (!row) {
    return errorResponse(404, "not_found", "해당 글을 찾을 수 없습니다.", request);
  }
  return json({ message: row }, 200, request);
}

// ── 라우터 ────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }

    try {
      if (path === "/" || path === "/health") {
        if (request.method === "GET") {
          return json({ ok: true, service: SERVICE }, 200, request);
        }
      }

      // 관리자 비밀번호 확인용. 성공 시 200 {ok:true}, 실패 401.
      if (path === "/api/admin/verify") {
        if (request.method === "GET" || request.method === "POST") {
          return isAdmin(env, request)
            ? json({ ok: true }, 200, request)
            : errorResponse(401, "unauthorized", "비밀번호가 올바르지 않습니다.", request);
        }
      }

      if (path === "/api/guestbook") {
        if (request.method === "GET") return await handleList(env, request);
        if (request.method === "POST") return await handleCreate(env, request);
      }

      // /api/guestbook/:id — 관리자 삭제/수정.
      const idMatch = path.match(/^\/api\/guestbook\/(\d+)$/);
      if (idMatch) {
        const id = Number(idMatch[1]);
        if (request.method === "DELETE") return await handleDelete(env, request, id);
        if (request.method === "PATCH") return await handleUpdate(env, request, id);
      }

      return errorResponse(404, "not_found", "요청하신 경로를 찾을 수 없습니다.", request);
    } catch (err) {
      console.error("server_error", err);
      return errorResponse(500, "server_error", "서버 오류가 발생했습니다.", request);
    }
  },
};
