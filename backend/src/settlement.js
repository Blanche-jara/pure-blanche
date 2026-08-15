/**
 * 정산표 API — Cloudflare Worker 라우트.
 *
 * 계약: docs/SETTLEMENT_BACKEND.md (이 문서가 정답).
 * 분할·상계 계산은 전부 클라이언트(lib/apps/settlement/engine.dart)가 하고,
 * 서버는 원장(인원/지출/송금/입금처리)만 보관한다.
 *
 * 모든 변경 요청은 성공 시 갱신된 프로젝트 전체 `{project}` 를 돌려준다.
 * 클라이언트가 상태를 통째로 교체하면 되므로 동시 편집에도 화면이 어긋나지 않는다.
 */

import {
  bearerToken,
  errorResponse,
  ipHash,
  isAdmin,
  json,
  randomHex,
  safeEqual,
  sha256Hex,
} from "./common.js";

// 혼동하기 쉬운 문자(i, l, o, 0, 1)를 뺀 공유 코드 알파벳.
const CODE_ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789";
const CODE_LENGTH = 8;
const CODE_RE = /^[a-z0-9]{8}$/;

const PROJECT_NAME_MAX = 40;
const MEMBER_NAME_MAX = 12;
const EXPENSE_TITLE_MAX = 30;
const MEMO_MAX = 30;
const AMOUNT_MAX = 99999999;

const MEMBERS_MAX = 30;
const EXPENSES_MAX = 500;
const TRANSFERS_MAX = 500;
const LEGS_PER_REQUEST_MAX = 200;

const CREATE_TOO_FAST_SECONDS = 10;
const CREATE_DAILY_LIMIT = 30;

const PASSWORD_MIN = 4;
const PASSWORD_MAX = 32;
const PBKDF2_ITERATIONS = 100000;

// ── 비밀 프로젝트(암호 잠금) ──────────────────────────────────────────
// 암호는 원문을 저장하지 않는다. 프로젝트마다 다른 솔트로 PBKDF2-SHA256 10만 회.
async function hashPassword(password, saltHex) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: new TextEncoder().encode(saltHex),
      iterations: PBKDF2_ITERATIONS,
      hash: "SHA-256",
    },
    key,
    256
  );
  return [...new Uint8Array(bits)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * 암호를 통과한 뒤 브라우저가 들고 다니는 열쇠.
 * 서버 시크릿(IP_SALT)이 있어야 만들 수 있고, 암호가 바뀌면 pass_hash 가 바뀌어
 * 예전 열쇠는 저절로 무효가 된다. 별도 토큰 테이블이 필요 없다.
 */
async function accessTokenFor(env, project) {
  const secret = env.IP_SALT || "dev-salt";
  return await sha256Hex(`${secret}:access:${project.id}:${project.pass_hash}`);
}

/** 이 프로젝트를 열 권한이 있는가 (접근 토큰 / 소유자 토큰 / 관리자). */
async function isAuthorized(env, request, project) {
  if (!project.pass_hash) return true; // 공개 프로젝트
  if (isAdmin(env, request)) return true;

  const token = bearerToken(request);
  if (!token) return false;

  if (safeEqual(token, await accessTokenFor(env, project))) return true;
  if (project.owner_hash && safeEqual(await sha256Hex(token), project.owner_hash)) {
    return true;
  }
  return false;
}

// ── 값 검증 ───────────────────────────────────────────────────────────
function trimmed(v) {
  return typeof v === "string" ? v.trim() : "";
}

function isAmount(v) {
  return Number.isInteger(v) && v >= 1 && v <= AMOUNT_MAX;
}

/** SQLite `datetime('now')` 문자열 → UTC ISO8601. */
function iso(sqliteUtc) {
  if (!sqliteUtc) return null;
  return `${String(sqliteUtc).replace(" ", "T")}Z`;
}

function legKey(expenseId, debtorId) {
  return `${expenseId}::${debtorId}`;
}

// ── 프로젝트 로드 ─────────────────────────────────────────────────────
/** 공유 코드로 프로젝트 전체를 조립한다. 없으면 null. */
async function loadProject(env, code) {
  const row = await env.DB.prepare(
    "SELECT id, code, name, pass_hash, created_at, updated_at FROM settle_projects WHERE code = ?"
  )
    .bind(code)
    .first();
  if (!row) return null;
  return await buildProject(env, row);
}

/** settle_projects 행 하나로부터 응답용 프로젝트 객체를 만든다. */
async function buildProject(env, row) {
  // rowid 를 보조 정렬키로 써서 같은 초에 들어온 항목의 입력 순서를 지킨다.
  const members = await env.DB.prepare(
    "SELECT id, name FROM settle_members WHERE project_id = ? ORDER BY sort_order, rowid"
  )
    .bind(row.id)
    .all();
  const expenses = await env.DB.prepare(
    "SELECT id, title, amount, payer_id, participants, created_at FROM settle_expenses WHERE project_id = ? ORDER BY created_at, rowid"
  )
    .bind(row.id)
    .all();
  const transfers = await env.DB.prepare(
    "SELECT id, from_id, to_id, amount, applied, memo, created_at FROM settle_transfers WHERE project_id = ? ORDER BY created_at, rowid"
  )
    .bind(row.id)
    .all();
  const legs = await env.DB.prepare(
    "SELECT expense_id, debtor_id FROM settle_legs WHERE project_id = ?"
  )
    .bind(row.id)
    .all();

  return {
    id: row.id,
    code: row.code,
    name: row.name,
    locked: !!row.pass_hash,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
    members: (members.results ?? []).map((m) => ({ id: m.id, name: m.name })),
    expenses: (expenses.results ?? []).map((e) => ({
      id: e.id,
      title: e.title,
      amount: e.amount,
      payerId: e.payer_id,
      participantIds: safeParseIds(e.participants),
      createdAt: iso(e.created_at),
    })),
    transfers: (transfers.results ?? []).map((t) => ({
      id: t.id,
      fromId: t.from_id,
      toId: t.to_id,
      amount: t.amount,
      applied: t.applied ?? 0,
      memo: t.memo ?? "",
      createdAt: iso(t.created_at),
    })),
    settledLegs: (legs.results ?? []).map((l) =>
      legKey(l.expense_id, l.debtor_id)
    ),
  };
}

function safeParseIds(text) {
  try {
    const v = JSON.parse(text);
    return Array.isArray(v) ? v.filter((x) => typeof x === "string") : [];
  } catch {
    return [];
  }
}

/** 변경 후 updated_at 갱신 + 최신 프로젝트 응답. */
async function touchAndRespond(env, request, projectRow) {
  await env.DB.prepare(
    "UPDATE settle_projects SET updated_at = datetime('now') WHERE id = ?"
  )
    .bind(projectRow.id)
    .run();
  const fresh = await env.DB.prepare(
    "SELECT id, code, name, pass_hash, created_at, updated_at FROM settle_projects WHERE id = ?"
  )
    .bind(projectRow.id)
    .first();
  return json({ project: await buildProject(env, fresh) }, 200, request);
}

async function readJson(request) {
  try {
    const body = await request.json();
    return body !== null && typeof body === "object" ? body : null;
  } catch {
    return null;
  }
}

/** 프로젝트의 인원 id 집합. */
async function memberIds(env, projectId) {
  const { results } = await env.DB.prepare(
    "SELECT id FROM settle_members WHERE project_id = ?"
  )
    .bind(projectId)
    .all();
  return new Set((results ?? []).map((r) => r.id));
}

// ── 생성 ──────────────────────────────────────────────────────────────
function randomCode() {
  const buf = new Uint8Array(CODE_LENGTH);
  crypto.getRandomValues(buf);
  let out = "";
  for (const b of buf) out += CODE_ALPHABET[b % CODE_ALPHABET.length];
  return out;
}

async function handleCreate(env, request) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }

  const name = trimmed(body.name);
  if (!name) {
    return errorResponse(400, "empty", "필요한 값을 입력해주세요.", request);
  }
  if (name.length > PROJECT_NAME_MAX) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }

  const rawMembers = Array.isArray(body.members) ? body.members : null;
  if (!rawMembers) {
    return errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request);
  }
  const names = rawMembers.map(trimmed);
  if (names.length < 2 || names.length > MEMBERS_MAX) {
    return errorResponse(400, "bad_request", "인원은 2~30명이어야 합니다.", request);
  }
  if (names.some((n) => !n)) {
    return errorResponse(400, "empty", "모든 인원의 이름을 입력해주세요.", request);
  }
  if (names.some((n) => n.length > MEMBER_NAME_MAX)) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }

  // 비밀 프로젝트: 암호를 주면 잠긴다. 안 주면 지금까지처럼 링크만으로 열린다.
  // (해시 계산은 무겁지만 rate limit 통과 후에 하므로 남용 비용은 낮다)
  const password =
    typeof body.password === "string" ? body.password : "";
  if (password && (password.length < PASSWORD_MIN || password.length > PASSWORD_MAX)) {
    return errorResponse(400, "bad_password", "암호는 4~32자로 입력해주세요.", request);
  }

  // Rate limit (IP 해시 기준)
  const hash = await ipHash(env, request);
  const recent = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM settle_projects WHERE ip_hash = ? AND created_at > datetime('now', ?)"
  )
    .bind(hash, `-${CREATE_TOO_FAST_SECONDS} seconds`)
    .first();
  if ((recent?.c ?? 0) > 0) {
    return errorResponse(429, "too_fast", "잠시 후 다시 시도해주세요.", request);
  }
  const daily = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM settle_projects WHERE ip_hash = ? AND created_at > datetime('now', '-24 hours')"
  )
    .bind(hash)
    .first();
  if ((daily?.c ?? 0) >= CREATE_DAILY_LIMIT) {
    return errorResponse(429, "daily_limit", "하루 생성 한도를 초과했습니다.", request);
  }

  let passSalt = null;
  let passHash = null;
  if (password) {
    passSalt = randomHex(16);
    passHash = await hashPassword(password, passSalt);
  }

  const id = crypto.randomUUID();
  const ownerToken = randomHex(16); // 32자 hex
  const ownerHash = await sha256Hex(ownerToken);

  // 공유 코드 충돌 시 재시도(UNIQUE 제약이 최종 방어선).
  let code = null;
  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = randomCode();
    try {
      await env.DB.prepare(
        "INSERT INTO settle_projects (id, code, name, owner_hash, pass_salt, pass_hash, ip_hash) VALUES (?, ?, ?, ?, ?, ?, ?)"
      )
        .bind(id, candidate, name, ownerHash, passSalt, passHash, hash)
        .run();
      code = candidate;
      break;
    } catch (err) {
      if (!/UNIQUE/i.test(String(err))) throw err;
    }
  }
  if (!code) {
    return errorResponse(500, "server_error", "서버 오류가 발생했습니다.", request);
  }

  await env.DB.batch(
    names.map((n, i) =>
      env.DB.prepare(
        "INSERT INTO settle_members (id, project_id, name, sort_order) VALUES (?, ?, ?, ?)"
      ).bind(crypto.randomUUID(), id, n, i)
    )
  );

  const project = await loadProject(env, code);
  const row = await env.DB.prepare(
    "SELECT id, pass_hash FROM settle_projects WHERE id = ?"
  )
    .bind(id)
    .first();
  const accessToken = passHash ? await accessTokenFor(env, row) : null;

  return json({ project, ownerToken, accessToken }, 201, request);
}

// ── 잠금 해제 ─────────────────────────────────────────────────────────
/** POST /unlock — 암호를 확인하고 접근 토큰을 발급한다. */
async function handleUnlock(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  if (!project.pass_hash) {
    // 암호가 없는 프로젝트 — 그냥 열어준다.
    return json(
      { project: await buildProject(env, project), accessToken: null },
      200,
      request
    );
  }

  const password = typeof body.password === "string" ? body.password : "";
  if (!password) {
    return errorResponse(400, "empty", "암호를 입력해주세요.", request);
  }

  const attempt = await hashPassword(password, project.pass_salt || "");
  if (!safeEqual(attempt, project.pass_hash)) {
    return errorResponse(401, "bad_password", "암호가 올바르지 않습니다.", request);
  }

  return json(
    {
      project: await buildProject(env, project),
      accessToken: await accessTokenFor(env, project),
    },
    200,
    request
  );
}

// ── 프로젝트 단위 ─────────────────────────────────────────────────────
async function handleRename(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  const name = trimmed(body.name);
  if (!name) {
    return errorResponse(400, "empty", "필요한 값을 입력해주세요.", request);
  }
  if (name.length > PROJECT_NAME_MAX) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }
  await env.DB.prepare("UPDATE settle_projects SET name = ? WHERE id = ?")
    .bind(name, project.id)
    .run();
  return await touchAndRespond(env, request, project);
}

/** 프로젝트 삭제는 소유자 토큰 보유자 또는 관리자만. */
async function handleDeleteProject(env, request, project) {
  let allowed = isAdmin(env, request);
  if (!allowed) {
    const token = bearerToken(request);
    if (token && project.owner_hash) {
      allowed = safeEqual(await sha256Hex(token), project.owner_hash);
    }
  }
  if (!allowed) {
    return errorResponse(401, "unauthorized", "권한이 없습니다.", request);
  }

  await env.DB.batch([
    env.DB.prepare("DELETE FROM settle_legs WHERE project_id = ?").bind(project.id),
    env.DB.prepare("DELETE FROM settle_transfers WHERE project_id = ?").bind(project.id),
    env.DB.prepare("DELETE FROM settle_expenses WHERE project_id = ?").bind(project.id),
    env.DB.prepare("DELETE FROM settle_members WHERE project_id = ?").bind(project.id),
    env.DB.prepare("DELETE FROM settle_projects WHERE id = ?").bind(project.id),
  ]);
  return json({ ok: true, deleted: project.code }, 200, request);
}

// ── 인원 ──────────────────────────────────────────────────────────────
async function handleAddMember(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  const name = trimmed(body.name);
  if (!name) {
    return errorResponse(400, "empty", "필요한 값을 입력해주세요.", request);
  }
  if (name.length > MEMBER_NAME_MAX) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }

  const count = await env.DB.prepare(
    "SELECT COUNT(*) AS c, MAX(sort_order) AS mx FROM settle_members WHERE project_id = ?"
  )
    .bind(project.id)
    .first();
  if ((count?.c ?? 0) >= MEMBERS_MAX) {
    return errorResponse(409, "limit_exceeded", "한도를 초과했습니다.", request);
  }

  await env.DB.prepare(
    "INSERT INTO settle_members (id, project_id, name, sort_order) VALUES (?, ?, ?, ?)"
  )
    .bind(crypto.randomUUID(), project.id, name, (count?.mx ?? -1) + 1)
    .run();
  return await touchAndRespond(env, request, project);
}

async function handleRenameMember(env, request, project, memberId) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  const name = trimmed(body.name);
  if (!name) {
    return errorResponse(400, "empty", "필요한 값을 입력해주세요.", request);
  }
  if (name.length > MEMBER_NAME_MAX) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }
  const res = await env.DB.prepare(
    "UPDATE settle_members SET name = ? WHERE id = ? AND project_id = ?"
  )
    .bind(name, memberId, project.id)
    .run();
  if ((res.meta?.changes ?? 0) === 0) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }
  return await touchAndRespond(env, request, project);
}

/** 지출·송금에 얽힌 인원은 삭제하지 않는다(원장 정합성). */
async function handleDeleteMember(env, request, project, memberId) {
  const exists = await env.DB.prepare(
    "SELECT id FROM settle_members WHERE id = ? AND project_id = ?"
  )
    .bind(memberId, project.id)
    .first();
  if (!exists) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }

  const { results } = await env.DB.prepare(
    "SELECT payer_id, participants FROM settle_expenses WHERE project_id = ?"
  )
    .bind(project.id)
    .all();
  const usedInExpense = (results ?? []).some(
    (e) => e.payer_id === memberId || safeParseIds(e.participants).includes(memberId)
  );
  const usedInTransfer = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM settle_transfers WHERE project_id = ? AND (from_id = ? OR to_id = ?)"
  )
    .bind(project.id, memberId, memberId)
    .first();

  if (usedInExpense || (usedInTransfer?.c ?? 0) > 0) {
    return errorResponse(
      409,
      "member_in_use",
      "지출에 참여한 인원은 삭제할 수 없습니다.",
      request
    );
  }

  await env.DB.prepare("DELETE FROM settle_members WHERE id = ? AND project_id = ?")
    .bind(memberId, project.id)
    .run();
  return await touchAndRespond(env, request, project);
}

// ── 지출 ──────────────────────────────────────────────────────────────
/** 지출 본문 공통 검증. 성공 시 {title, amount, payerId, participantIds}. */
async function parseExpenseBody(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return { error: errorResponse(400, "invalid_json", "잘못된 요청입니다.", request) };
  }
  const title = trimmed(body.title);
  if (!title) {
    return { error: errorResponse(400, "empty", "필요한 값을 입력해주세요.", request) };
  }
  if (title.length > EXPENSE_TITLE_MAX) {
    return { error: errorResponse(400, "too_long", "입력이 너무 깁니다.", request) };
  }
  if (!isAmount(body.amount)) {
    return { error: errorResponse(400, "bad_amount", "금액이 올바르지 않습니다.", request) };
  }

  const ids = await memberIds(env, project.id);
  const payerId = typeof body.payerId === "string" ? body.payerId : "";
  if (!ids.has(payerId)) {
    return { error: errorResponse(400, "bad_member", "인원 정보가 올바르지 않습니다.", request) };
  }

  const raw = Array.isArray(body.participantIds) ? body.participantIds : null;
  if (!raw || raw.length === 0) {
    return { error: errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request) };
  }
  // 중복 제거하되 입력 순서는 유지(나머지 1원 배분이 순서를 따른다).
  const participantIds = [...new Set(raw)];
  if (participantIds.some((p) => typeof p !== "string" || !ids.has(p))) {
    return { error: errorResponse(400, "bad_member", "인원 정보가 올바르지 않습니다.", request) };
  }

  return { title, amount: body.amount, payerId, participantIds };
}

async function handleAddExpense(env, request, project) {
  const parsed = await parseExpenseBody(env, request, project);
  if (parsed.error) return parsed.error;

  const count = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM settle_expenses WHERE project_id = ?"
  )
    .bind(project.id)
    .first();
  if ((count?.c ?? 0) >= EXPENSES_MAX) {
    return errorResponse(409, "limit_exceeded", "한도를 초과했습니다.", request);
  }

  await env.DB.prepare(
    "INSERT INTO settle_expenses (id, project_id, title, amount, payer_id, participants) VALUES (?, ?, ?, ?, ?, ?)"
  )
    .bind(
      crypto.randomUUID(),
      project.id,
      parsed.title,
      parsed.amount,
      parsed.payerId,
      JSON.stringify(parsed.participantIds)
    )
    .run();
  return await touchAndRespond(env, request, project);
}

/**
 * 지출 수정. 참여자에서 빠졌거나 결제자가 된 사람의 입금 처리 기록은
 * 근거를 잃으므로 함께 지운다(프론트 updateExpense 와 같은 규칙).
 */
async function handleUpdateExpense(env, request, project, expenseId) {
  const exists = await env.DB.prepare(
    "SELECT id FROM settle_expenses WHERE id = ? AND project_id = ?"
  )
    .bind(expenseId, project.id)
    .first();
  if (!exists) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }

  const parsed = await parseExpenseBody(env, request, project);
  if (parsed.error) return parsed.error;

  const kept = parsed.participantIds.filter((id) => id !== parsed.payerId);
  await env.DB.prepare(
    "UPDATE settle_expenses SET title = ?, amount = ?, payer_id = ?, participants = ? WHERE id = ? AND project_id = ?"
  )
    .bind(
      parsed.title,
      parsed.amount,
      parsed.payerId,
      JSON.stringify(parsed.participantIds),
      expenseId,
      project.id
    )
    .run();

  const placeholders = kept.map(() => "?").join(", ");
  const sql = kept.length
    ? `DELETE FROM settle_legs WHERE project_id = ? AND expense_id = ? AND debtor_id NOT IN (${placeholders})`
    : "DELETE FROM settle_legs WHERE project_id = ? AND expense_id = ?";
  await env.DB.prepare(sql)
    .bind(project.id, expenseId, ...kept)
    .run();

  return await touchAndRespond(env, request, project);
}

async function handleDeleteExpense(env, request, project, expenseId) {
  const res = await env.DB.prepare(
    "DELETE FROM settle_expenses WHERE id = ? AND project_id = ?"
  )
    .bind(expenseId, project.id)
    .run();
  if ((res.meta?.changes ?? 0) === 0) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }
  await env.DB.prepare(
    "DELETE FROM settle_legs WHERE project_id = ? AND expense_id = ?"
  )
    .bind(project.id, expenseId)
    .run();
  return await touchAndRespond(env, request, project);
}

// ── 직접 송금 ─────────────────────────────────────────────────────────
async function handleAddTransfer(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  if (!isAmount(body.amount)) {
    return errorResponse(400, "bad_amount", "금액이 올바르지 않습니다.", request);
  }
  const memo = trimmed(body.memo);
  if (memo.length > MEMO_MAX) {
    return errorResponse(400, "too_long", "입력이 너무 깁니다.", request);
  }

  const ids = await memberIds(env, project.id);
  const fromId = typeof body.fromId === "string" ? body.fromId : "";
  const toId = typeof body.toId === "string" ? body.toId : "";
  if (!ids.has(fromId) || !ids.has(toId)) {
    return errorResponse(400, "bad_member", "인원 정보가 올바르지 않습니다.", request);
  }
  if (fromId === toId) {
    return errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request);
  }

  const count = await env.DB.prepare(
    "SELECT COUNT(*) AS c FROM settle_transfers WHERE project_id = ?"
  )
    .bind(project.id)
    .first();
  if ((count?.c ?? 0) >= TRANSFERS_MAX) {
    return errorResponse(409, "limit_exceeded", "한도를 초과했습니다.", request);
  }

  // 이 송금이 덮는 채무 건들 — 클라이언트가 계산해서 함께 보낸다.
  // (분할 규칙은 engine.dart 한 곳에만 둔다.) 여기서는 정합성만 검증한다.
  const rawLegs = Array.isArray(body.legs) ? body.legs : [];
  if (rawLegs.length > LEGS_PER_REQUEST_MAX) {
    return errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request);
  }
  const parsed = await parseLegs(env, request, project, rawLegs);
  if (parsed.error) return parsed.error;
  // 정산 처리되는 건은 반드시 "보낸 사람이 받는 사람에게" 갚는 건이어야 한다.
  if (parsed.legs.some((l) => l.debtorId !== fromId)) {
    return errorResponse(400, "bad_member", "인원 정보가 올바르지 않습니다.", request);
  }

  const applied = Number.isInteger(body.applied) ? body.applied : 0;
  if (applied < 0 || applied > body.amount) {
    return errorResponse(400, "bad_amount", "금액이 올바르지 않습니다.", request);
  }

  await env.DB.batch([
    env.DB.prepare(
      "INSERT INTO settle_transfers (id, project_id, from_id, to_id, amount, applied, memo) VALUES (?, ?, ?, ?, ?, ?, ?)"
    ).bind(
      crypto.randomUUID(),
      project.id,
      fromId,
      toId,
      body.amount,
      applied,
      memo
    ),
    ...parsed.legs.map((l) =>
      env.DB.prepare(
        "INSERT OR IGNORE INTO settle_legs (project_id, expense_id, debtor_id) VALUES (?, ?, ?)"
      ).bind(project.id, l.expenseId, l.debtorId)
    ),
  ]);
  return await touchAndRespond(env, request, project);
}

async function handleDeleteTransfer(env, request, project, transferId) {
  const res = await env.DB.prepare(
    "DELETE FROM settle_transfers WHERE id = ? AND project_id = ?"
  )
    .bind(transferId, project.id)
    .run();
  if ((res.meta?.changes ?? 0) === 0) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }
  return await touchAndRespond(env, request, project);
}

/**
 * 채무 건 목록을 검증한다. 실재하는 지출의, 실재하는 참여자에 대한 건만 통과.
 * 성공하면 `{legs}`, 실패하면 `{error: Response}`.
 */
async function parseLegs(env, request, project, raw) {
  const legs = [];
  for (const l of raw) {
    const expenseId = typeof l?.expenseId === "string" ? l.expenseId : "";
    const debtorId = typeof l?.debtorId === "string" ? l.debtorId : "";
    if (!expenseId || !debtorId) {
      return {
        error: errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request),
      };
    }
    legs.push({ expenseId, debtorId });
  }

  const { results } = await env.DB.prepare(
    "SELECT id, payer_id, participants FROM settle_expenses WHERE project_id = ?"
  )
    .bind(project.id)
    .all();
  const byExpense = new Map(
    (results ?? []).map((e) => [
      e.id,
      { payerId: e.payer_id, participants: safeParseIds(e.participants) },
    ])
  );
  for (const l of legs) {
    const e = byExpense.get(l.expenseId);
    if (!e || l.debtorId === e.payerId || !e.participants.includes(l.debtorId)) {
      return {
        error: errorResponse(400, "bad_member", "인원 정보가 올바르지 않습니다.", request),
      };
    }
  }
  return { legs };
}

// ── 입금 처리 ─────────────────────────────────────────────────────────
/** PUT /legs — "입금했습니다"(settled:true) / 취소(false). */
async function handleLegs(env, request, project) {
  const body = await readJson(request);
  if (!body) {
    return errorResponse(400, "invalid_json", "잘못된 요청입니다.", request);
  }
  const settled = body.settled === true;
  const raw = Array.isArray(body.legs) ? body.legs : null;
  if (!raw || raw.length === 0 || raw.length > LEGS_PER_REQUEST_MAX) {
    return errorResponse(400, "bad_request", "요청이 올바르지 않습니다.", request);
  }

  const parsed = await parseLegs(env, request, project, raw);
  if (parsed.error) return parsed.error;
  const legs = parsed.legs;

  await env.DB.batch(
    legs.map((l) =>
      settled
        ? env.DB.prepare(
            "INSERT OR IGNORE INTO settle_legs (project_id, expense_id, debtor_id) VALUES (?, ?, ?)"
          ).bind(project.id, l.expenseId, l.debtorId)
        : env.DB.prepare(
            "DELETE FROM settle_legs WHERE project_id = ? AND expense_id = ? AND debtor_id = ?"
          ).bind(project.id, l.expenseId, l.debtorId)
    )
  );
  return await touchAndRespond(env, request, project);
}

// ── 라우터 ────────────────────────────────────────────────────────────
/**
 * 정산표 경로를 처리한다. 이 라우터가 맡을 경로가 아니면 null 을 돌려
 * 호출부(index.js)가 계속 매칭하게 한다.
 */
export async function routeSettlement(env, request, path) {
  const method = request.method;

  if (path === "/api/settlement") {
    if (method === "POST") return await handleCreate(env, request);
    return null;
  }

  const m = path.match(/^\/api\/settlement\/([^/]+)(?:\/([^/]+))?(?:\/([^/]+))?$/);
  if (!m) return null;

  const [, code, section, itemId] = m;
  if (!CODE_RE.test(code)) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }

  const project = await env.DB.prepare(
    "SELECT id, code, name, owner_hash, pass_salt, pass_hash, created_at, updated_at FROM settle_projects WHERE code = ?"
  )
    .bind(code)
    .first();
  if (!project) {
    return errorResponse(404, "not_found", "정산표를 찾을 수 없습니다.", request);
  }

  // 잠금 해제 요청은 가드보다 먼저 처리한다(암호를 확인하는 문 자체이므로).
  if (section === "unlock" && !itemId && method === "POST") {
    return await handleUnlock(env, request, project);
  }

  // 비밀 프로젝트: 조회든 편집이든 열쇠가 있어야 한다.
  if (!(await isAuthorized(env, request, project))) {
    return json(
      {
        error: "password_required",
        detail: "암호가 필요한 정산표입니다.",
        name: project.name, // 암호 입력 화면에 이름은 보여준다
      },
      401,
      request
    );
  }

  // /api/settlement/:code
  if (!section) {
    if (method === "GET") {
      return json({ project: await buildProject(env, project) }, 200, request);
    }
    if (method === "PATCH") return await handleRename(env, request, project);
    if (method === "DELETE") return await handleDeleteProject(env, request, project);
    return null;
  }

  // /api/settlement/:code/<section>[/:itemId]
  if (section === "members") {
    if (!itemId && method === "POST") return await handleAddMember(env, request, project);
    if (itemId && method === "PATCH")
      return await handleRenameMember(env, request, project, itemId);
    if (itemId && method === "DELETE")
      return await handleDeleteMember(env, request, project, itemId);
    return null;
  }

  if (section === "expenses") {
    if (!itemId && method === "POST") return await handleAddExpense(env, request, project);
    if (itemId && method === "PATCH")
      return await handleUpdateExpense(env, request, project, itemId);
    if (itemId && method === "DELETE")
      return await handleDeleteExpense(env, request, project, itemId);
    return null;
  }

  if (section === "transfers") {
    if (!itemId && method === "POST") return await handleAddTransfer(env, request, project);
    if (itemId && method === "DELETE")
      return await handleDeleteTransfer(env, request, project, itemId);
    return null;
  }

  if (section === "legs" && !itemId && method === "PUT") {
    return await handleLegs(env, request, project);
  }

  return null;
}
