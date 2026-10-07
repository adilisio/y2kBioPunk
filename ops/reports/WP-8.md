# WP-8 Documentation Catch-up

- AGENTS.md: retained structure; corrected player states/momentum/hurt immunity, damage/XP contracts, camera, roster, runtime builder, save/session/victory semantics, directory inventory, build/test tooling and agent rules.
- README.md: Windows support, fresh clone and separately downloaded engine, intro/menu/mall route, controls, build/test commands and slice completion flow.
- GAME_SYNOPSIS.md: replaced current-state and remaining-work sections with ledger-verified work, outstanding WP-6, human taste decisions and deferred slice scope; corrected platform claim.
- music/CREDITS.md unchanged; no changed credit fact was identified.

Read ledger, shared context, WP-1 through WP-5 and WP-7 reports, WP-6 brief, native player header/bindings and script/tool/test inventory. WP-6 report does not exist in this checkout. WP-6 behavior is described as intended without claiming verification. No game code changed and no Godot instance was launched; documentation-only verification was appropriate.

Verification command and actual output:

```text
rg -n 'main.tscn|0 XP|no attack|16\.0|600 HP|30 HP|50 HP' AGENTS.md README.md GAME_SYNOPSIS.md
(no output; exit 1 = no matches)

git diff --check
(no output; exit 0)
```

One commit per documentation file with requested trailers. This report is intentionally uncommitted because the brief prohibits commits to ops/. The user's explicit commit instruction supersedes CONTEXT's historical Director-only commit rule.
