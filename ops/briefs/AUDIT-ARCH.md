# AUDIT-ARCH — Architecture & correctness audit (READ-ONLY)
Agent: codex. Effort: high. Slot: REVIEW (no code edits).

Read `AGENTS.md`, `ops/CONTEXT.md`, then this brief.

## Goal
Produce an evidence-based audit of the codebase's correctness and architecture so the Director can decide what to fix, cut or restructure for a 15–30 minute vertical slice. You are a critic, not a fixer.

## Scope (read everything in these)
- `src/*.cpp|hpp` (especially `player_controller.cpp`, 2884 lines), `register_types.cpp`
- `scripts/*.gd`, `scenes/*.tscn` (node structure, signal wiring, collision layers/masks), `project.godot`, `biopunk.gdextension`, `SConstruct`
- `tests/*.gd` — determine what each test actually proves vs. what its name claims. Run each headless (command in CONTEXT.md) and record pass/fail/crash.
- You MAY run the game headless. Do NOT open the editor or a windowed game.

## Questions to answer, with file:line evidence
1. C++ <-> GDScript boundary: list every call across the boundary (GDScript calling player methods, C++ calling into GDScript via `call`/`has_method`, signals). Is the split sound or accidental? Which responsibilities are duplicated or misplaced? Would moving anything materially improve reliability or iteration speed? Be concrete and conservative; do not propose refactors for elegance.
2. Bugs and logic errors that affect play: death/respawn, save/load, boss trigger, checkpoint, damage interfaces (`take_damage` signatures differ between C++ player (float) and GDScript enemies (int, dir)), collision layer/mask mismatches, signal connections that never fire, nodes looked up by name that don't exist in the shipped scenes, input actions referenced in code but not defined.
3. Dead code and cruft: unused classes, unreachable scenes, root-level duplicates, defensive fallback chains that mask real wiring errors.
4. Test suite: coverage map (system -> test), what is fake (asserts on constants), what would catch a real regression, what's missing for the critical path.
5. Build/tooling risk: anything that would break a fresh clone.

## Output
Write `ops/reports/AUDIT-ARCH.md`:
- Top 10 findings ranked by player impact, each with: severity, evidence (file:line), proposed fix, estimated cost (S/M/L), risk.
- Boundary table (caller -> callee -> mechanism).
- Test results table.
- One paragraph: your recommendation on the C++/GDScript split for this slice.
Keep it under 400 lines. No marketing language. Do not modify any file other than the report.
