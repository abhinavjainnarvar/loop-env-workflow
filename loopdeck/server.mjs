#!/usr/bin/env node
// Loopdeck server — a LOCAL, READ-ONLY projection of the loop board.
//
// The model (docs/loopdeck-design.md): reader, never a second writer. This process
// only ever READS the board files and serves a derived JSON view + live-change events.
// It exposes NO write endpoint at all in this slice — the future "message the board"
// modal will append via system/inbox.sh, and lands only after read-only proves out.
//
// Zero dependencies on purpose: plain node http + fs. Live updates use SSE
// (Server-Sent Events), which needs no websocket library and auto-reconnects.
// Binds 127.0.0.1 only — this is a local console over local files.
//
// Usage: node server.mjs [--board DIR] [--port N]   (port 0 = pick a free one)

import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFile } from "node:child_process";

const args = process.argv.slice(2);
const arg = (name, dflt) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : dflt;
};
const BOARD = path.resolve(arg("--board", path.join(process.env.HOME ?? "", "planning/boards")));
const PORT = Number(arg("--port", "4820"));
const PUB = path.join(path.dirname(fileURLToPath(import.meta.url)), "public");

const readIf = (p, cap = 512 * 1024) => {
  try {
    const st = fs.statSync(p);
    if (!st.isFile()) return null;
    const buf = fs.readFileSync(p, "utf8");
    return buf.length > cap ? buf.slice(-cap) : buf; // tail-cap huge files (log.md)
  } catch {
    return null;
  }
};

// ── board.md → projection ────────────────────────────────────────────────
// A group = a `### ` heading. A row = a top-level `- **KEY**` bullet under it;
// its indented sub-bullets are detail lines. State = the first `backticked`
// token on the row line; per-PR badges are derived from #NNNN mentions.
export function parseBoard(md) {
  const groups = [];
  let g = null;
  let row = null;
  const clean = (s) =>
    s.replace(/\[↗\]\([^)]*\)/g, "").replace(/`[^`]*`/g, "").replace(/\*\*/g, "").replace(/\s+/g, " ").trim();
  for (const line of (md ?? "").split("\n")) {
    const h = line.match(/^###\s+(.*)$/);
    if (h) {
      g = { title: h[1].trim(), rows: [] };
      groups.push(g);
      row = null;
      continue;
    }
    // an h1/h2 ("## State legend", "## Not tracked") ends the group scope — its
    // bullets are documentation, not board rows (they rendered as ghost rows once)
    if (/^##?\s/.test(line)) {
      g = null;
      row = null;
      continue;
    }
    const r = line.match(/^-\s+\*\*(.+?)\*\*\s*(.*)$/);
    if (r && g) {
      const rest = r[2];
      row = {
        key: r[1].trim(),
        state: (rest.match(/`([^`]+)`/) ?? [])[1] ?? null,
        next: clean(rest.split("·").slice(2).join("·")) || null,
        link: (rest.match(/\[↗\]\(([^)]+)\)/) ?? [])[1] ?? null,
        prs: [],
        details: [],
      };
      g.rows.push(row);
      continue;
    }
    if (row && /^\s+-\s+/.test(line)) row.details.push(line.trim().replace(/^-\s*/, ""));
  }
  // PR badges: distinct #NNNN across the row line's own text + details
  for (const grp of groups)
    for (const r of grp.rows) {
      const seen = new Set();
      for (const s of [r.next ?? "", ...r.details])
        for (const m of s.matchAll(/#(\d{2,6})\b/g)) seen.add(m[1]);
      r.prs = [...seen].map((n) => `#${n}`);
    }
  return groups;
}

const jsonIf = (p) => {
  try {
    return JSON.parse(readIf(p) ?? "");
  } catch {
    return null;
  }
};

function boardProjection() {
  const md = readIf(path.join(BOARD, "board.md"));
  const log = readIf(path.join(BOARD, "system/log.md")) ?? "";
  return {
    generatedAt: new Date().toISOString(),
    board: BOARD,
    groups: md === null ? [] : parseBoard(md),
    state: jsonIf(path.join(BOARD, "system/state.json")), // the loop's heartbeat (may be null)
    lock: readIf(path.join(BOARD, "system/loop.lock")),
    brief: readIf(path.join(BOARD, "brief.md")),
    logTail: log
      .split("\n")
      .filter(Boolean)
      .slice(-12)
      .map((l) => l.replace(/^[-#\s]+/, "").trim()),
  };
}

// ── ticket detail: the per-dimension files, verbatim (no distillation) ───
const SAFE_KEY = /^[\w.@-]+$/; // path-traversal guard: one plain path segment only
function ticketDetail(key) {
  if (!SAFE_KEY.test(key)) return null;
  const dir = path.join(BOARD, "tickets", key);
  if (!path.resolve(dir).startsWith(path.resolve(path.join(BOARD, "tickets")) + path.sep)) return null;
  let names;
  try {
    names = fs.readdirSync(dir).filter((f) => f.endsWith(".md"));
  } catch {
    return null;
  }
  const files = {};
  for (const f of names.sort()) files[f] = readIf(path.join(dir, f), 256 * 1024);
  return { key, files };
}

// ── SSE: one event stream, fired (debounced) on any board-dir change ─────
const clients = new Set();
let debounce = null;
function broadcast() {
  clearTimeout(debounce);
  debounce = setTimeout(() => {
    const msg = `data: ${JSON.stringify({ changed: true, at: Date.now() })}\n\n`;
    for (const res of clients) res.write(msg);
  }, 300);
}
try {
  fs.watch(BOARD, { recursive: true }, (_e, f) => {
    // ignore churn that isn't board content (lockfiles, sockets)
    if (f && /\.lck$|\.loop-lock\.mutex|loop\.lock\.tmp/.test(f)) return;
    broadcast();
  });
} catch {
  // fs.watch recursive is supported on macOS/Windows; degrade to poll elsewhere
  setInterval(broadcast, 5000);
}

// ── the ONE write path: queue an inbox command, exactly like /update-board ──
// Never writes any file itself — delegates to system/inbox.sh (the locked appender),
// so Loopdeck stays a producer, never a second writer of board state. Verbs are
// whitelisted server-side (same set parse_cmd.sh accepts): a gate can only be an
// explicit verb, never parsed out of prose (design-review rule).
const VERBS = new Set(["ingest", "approve", "reject", "changes", "hold", "resume", "retry", "priority", "drop", "ask", "recompute", "note"]);
const INBOX_SH = [path.join(BOARD, "system/inbox.sh"), path.join(path.dirname(fileURLToPath(import.meta.url)), "../system/inbox.sh")].find((p) => fs.existsSync(p));
function queueCommand(body, res) {
  let cmd;
  try {
    cmd = JSON.parse(body);
  } catch {
    return void res.writeHead(400).end("bad json");
  }
  const verb = String(cmd.verb ?? "").toLowerCase();
  const key = String(cmd.key ?? "").trim();
  const text = String(cmd.text ?? "").replace(/[\r\n]+/g, " ").trim(); // one command per line, always
  if (!VERBS.has(verb)) return void res.writeHead(400).end(`unknown verb '${verb}' — allowed: ${[...VERBS].join(" ")}`);
  // keys like `narvar/denali#3496` are legit (slash + hash), but never `..`
  if (!/^[\w#/.@-]+$/.test(key) || key.includes("..")) return void res.writeHead(400).end("bad key");
  if (!INBOX_SH) return void res.writeHead(500).end("system/inbox.sh not found");
  const line = [verb, key, text].filter(Boolean).join(" ");
  execFile("bash", [INBOX_SH, "append", "--inbox", path.join(BOARD, "inbox.md"), "--actor", "loopdeck", line], (err, _o, stderr) => {
    if (err) res.writeHead(500).end(`append failed: ${stderr || err.message}`);
    else res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify({ queued: line }));
  });
}

// ── http ─────────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  if (req.method === "POST" && url.pathname === "/api/inbox") {
    let body = "";
    req.on("data", (c) => (body += c).length > 16384 && req.destroy());
    req.on("end", () => queueCommand(body, res));
    return;
  }
  if (req.method !== "GET") {
    // everything else is read-only — /api/inbox above is the ONLY write, and it
    // only ever appends one inbox line via the locked helper
    res.writeHead(405, { Allow: "GET" }).end("read-only");
    return;
  }
  if (url.pathname === "/api/board") {
    res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(boardProjection()));
  } else if (url.pathname.startsWith("/api/ticket/")) {
    const t = ticketDetail(decodeURIComponent(url.pathname.slice("/api/ticket/".length)));
    if (t) res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(t));
    else res.writeHead(404).end("no such ticket");
  } else if (url.pathname === "/events") {
    res.writeHead(200, { "content-type": "text/event-stream", "cache-control": "no-cache", connection: "keep-alive" });
    res.write(`data: ${JSON.stringify({ hello: true })}\n\n`);
    clients.add(res);
    req.on("close", () => clients.delete(res));
  } else {
    const file = url.pathname === "/" ? "index.html" : url.pathname.slice(1);
    const fp = path.join(PUB, path.normalize(file));
    if (!fp.startsWith(PUB) || !fs.existsSync(fp)) return void res.writeHead(404).end("not found");
    const type = fp.endsWith(".html") ? "text/html" : fp.endsWith(".js") ? "text/javascript" : "text/plain";
    res.writeHead(200, { "content-type": type }).end(fs.readFileSync(fp));
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`loopdeck listening on http://127.0.0.1:${server.address().port} (board: ${BOARD})`);
});
