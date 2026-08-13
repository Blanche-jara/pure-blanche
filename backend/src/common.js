/**
 * Worker 공용 유틸 — CORS / JSON 응답 / IP 해시 / 관리자 인증.
 *
 * 방명록(index.js)과 정산표(settlement.js)가 함께 쓴다.
 * 계약: docs/GUESTBOOK_BACKEND.md 3.4(CORS), docs/SETTLEMENT_BACKEND.md 2장(권한).
 */

// 허용 Origin 목록. localhost/127.0.0.1 은 임의 포트를 허용한다.
const EXACT_ORIGINS = new Set([
  "https://pure-blanche.com",
  "https://www.pure-blanche.com",
]);
const LOCAL_ORIGIN_RE = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
const DEFAULT_ORIGIN = "https://pure-blanche.com";

export function resolveOrigin(request) {
  const origin = request.headers.get("Origin");
  if (origin && (EXACT_ORIGINS.has(origin) || LOCAL_ORIGIN_RE.test(origin))) {
    return origin;
  }
  return DEFAULT_ORIGIN;
}

export function corsHeaders(request) {
  return {
    "Access-Control-Allow-Origin": resolveOrigin(request),
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    Vary: "Origin",
  };
}

export function json(body, status, request) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...corsHeaders(request),
    },
  });
}

export function errorResponse(status, code, detail, request) {
  return json({ error: code, detail }, status, request);
}

/** SHA-256 → hex. */
export async function sha256Hex(text) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text)
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** rate-limit·순방문 계산용 IP 해시. 원본 IP는 남기지 않는다. */
export async function ipHash(env, request) {
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const salt = env.IP_SALT || "dev-salt"; // 로컬 개발 fallback. 프로덕션은 secret 주입.
  return await sha256Hex(`${salt}:${ip}`);
}

// 길이를 먼저 비교하므로 길이는 노출되나, 192bit+ 랜덤 토큰엔 무의미.
export function safeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

/** `Authorization: Bearer <토큰>` 에서 토큰만 꺼낸다. 없으면 null. */
export function bearerToken(request) {
  const auth = request.headers.get("Authorization") || "";
  const m = auth.match(/^Bearer\s+(.+)$/i);
  return m ? m[1] : null;
}

/** Bearer 토큰이 Worker secret(ADMIN_TOKEN)과 일치하면 관리자. */
export function isAdmin(env, request) {
  const expected = env.ADMIN_TOKEN;
  if (!expected) return false; // 시크릿 미설정 시 관리자 기능 비활성(안전 기본값).
  const token = bearerToken(request);
  return token ? safeEqual(token, expected) : false;
}

/** 무작위 hex 문자열(바이트 수 × 2 길이). */
export function randomHex(bytes) {
  const buf = new Uint8Array(bytes);
  crypto.getRandomValues(buf);
  return [...buf].map((b) => b.toString(16).padStart(2, "0")).join("");
}
