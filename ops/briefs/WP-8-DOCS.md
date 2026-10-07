# WP-8 — Documentation catch-up: make AGENTS.md, README.md and GAME_SYNOPSIS.md true again
Agent: codex (gpt-6.1-sol, effort low). Slot: DOC. Worktree `C:\y2k-biopunk-rpg\.worktrees\wp8` on branch `wp8-docs`. Stay here.

Read `ops/DIRECTOR_LEDGER.md` (authoritative state), `ops/CONTEXT.md`, `ops/reports/WP-1.md` … `WP-7.md`, `ops/briefs/WP-6-ONBOARDING-AUDIO.md` (WP-6 is landing in parallel; describe its intended behavior as "onboarding hints via the pager; music/SFX buses; tape resume" without claiming test status), then the current code (`src/player_controller.hpp` for the state machine and signals, `scripts/*.gd` headers, `tests/`, `ops/tools/`).

## Why this matters
The three docs described a game that did not exist (XP on kill, cicada attacks, a reachable mall). The audits had to re-derive everything. A fresh agent or Anthony must be able to trust the docs again.

## You own (allowed files)
`AGENTS.md`, `README.md`, `GAME_SYNOPSIS.md`, `music/CREDITS.md` (only if a fact there is wrong). Nothing else. No code changes. No commits to `ops/`.

## Scope
1. **AGENTS.md** — keep the structure; fix facts: directory layout (no root duplicates; `scenes/neon_cicada.tscn`; `ops/` tree with CONTEXT, ledger, briefs, reports, tools; `tests/` list), build + test instructions (`ops/tools/run_tests.ps1`; headless single test command; `ops/tools/shot_harness.gd` screenshot harness; the worktree script; never run windowed Godot from an agent), the player state machine (`set_state` single transition path; evade→attack refused; hurt i-frames 0.6 s; momentum model; camera arm 12 m / FOV 45), the damage interfaces (native `take_damage(amount, knockback = Vector3())`; GDScript `take_damage(amount: int, dir: Vector3)` with the normalized-impulse contract; `gain_xp` on death exactly once), the save/session semantics (SaveManager `pending_load` / `respawn_pending` / `clear_save` / `mark_slice_complete`; New Game clears, Continue restores, death respawns at checkpoint), the boss gate (entry-triggered at z −19), the builder as runtime source of truth, and a short "Rules for agents" section distilled from `ops/CONTEXT.md` (headless only, honest reports with pasted output, commit before finishing, no `*.import` churn).
2. **README.md** — "Getting Started" must be correct for a fresh clone: engine exe not in repo, `git clone --recurse-submodules`, open in Godot 4.3, press F5 → intro → menu → New Game → mall; controls table; "Run the tests" section with the runner; a "Vertical Slice 1" paragraph describing what the slice contains and how it ends (Queen → victory card → menu). Remove the Linux badge or state Windows-only for now (no Linux manifest entry).
3. **GAME_SYNOPSIS.md** — rewrite section 3 "Current State of Development" to match reality as of today (use the ledger's Verified list); update section 5 "What's Still Missing" from the ledger's remaining-issues/deferred list (ask for nothing new; just mirror).
4. Keep every number you state traceable to code or the ledger; when unsure, omit rather than guess.

## Verification
Grep your edits for stale claims: `main.tscn`, "0 XP", "no attack", "16.0" camera, "600 HP" (Queen is 1500 now), "30 HP" roach (45), "50 HP" cicada (70). Paste the grep results (should be empty) in the report.

## Commits
On `wp8-docs`, one commit per file, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. COMMIT before finishing.

## Report
`ops/reports/WP-8.md`: what changed per file and the grep output.
