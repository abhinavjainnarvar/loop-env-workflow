# Loopdeck — the local read-only board console

Slice 1 of `docs/loopdeck-design.md`: a zero-dependency local server + single-file SPA.

```
node loopdeck/server.mjs                 # board: ~/planning/boards, port 4820
node loopdeck/server.mjs --board DIR --port N
open http://127.0.0.1:4820
```

- **One write path, and it isn't a writer** — `POST /api/inbox` (the "✉ message the
  board" modal) appends ONE command line via `system/inbox.sh` (the locked helper),
  exactly like `/update-board`. Verbs are whitelisted server-side (parse_cmd's set),
  newlines are stripped (one command per line, no smuggling), and every other non-GET
  is 405. Loopdeck never touches `board.md`.
- **Live** — SSE over an `fs.watch` on the board dir; any file change refreshes the view.
- **One card per ticket** in its least-advanced column, per-PR badges (the engine's
  multi-PR rule; see tickets/loop-kernel decisions).
- **Verbatim ticket files** in the drawer — no summarizing layer (per the design review:
  no LLM distillation of journal/decisions).
- Binds 127.0.0.1 only; path-traversal-guarded; heartbeat from `system/state.json`,
  lease from `system/loop.lock`.

Implementation note: the design sketch said React+Vite; slice 1 ships as a no-build
vanilla SPA (`public/index.html`) — same architecture (local server + browser + live
push), zero node_modules. Move to a build only if the UI outgrows one file.
