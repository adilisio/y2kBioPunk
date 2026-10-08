# VS11-OCC — General player-occlusion fading
Agent: codex (gpt-6.1-sol, effort high). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11occ` on branch `vs11-occlusion` (from main). Stay there. Run Godot headless only (never the editor, never a windowed game).

Read `AGENTS.md`, `ops/CONTEXT.md`, `scripts/mall_greybox_builder.gd` (especially `_process`, `_add_box`, `_add_cylinder`, `_add_prop`), `scripts/isometric_camera.gd`, `scripts/enemy_model.gd`, `tests/test_presentation.gd` and `tests/_test_util.gd` (style), then this brief.

## Why this matters
VS1.1 is the "showable build" milestone. The clearest open presentation defect is that pillars, the mezzanine deck/rails, storefront walls and kiosk props can hide the player from the fixed 45° camera (12 m arm, pitch -45°, yaw 45°; the camera sits south-east of the player looking north-west). The current `_process` in the builder is a crude binary pillar-only hack that flips `material.transparency` (which forces a shader-variant recompile hitch on first use) and snaps between 0.25 and 1.0 alpha. Replace it with a clean general system.

## You own
- New: `scripts/occlusion_fader.gd`, `tests/test_occlusion.gd`, `ops/reports/VS11-OCC.md`.
- Edit: `scripts/mall_greybox_builder.gd` (remove the old `_process` fade; register occluders). Prefer creating the fader from the builder at runtime so the builder stays the source of truth; edit `scenes/FloodedMall_Greybox.tscn` only if a node must be added.
- Do NOT touch `src/`, `scripts/hud.gd`, enemy scripts, `project.godot`.

## Design (follow unless you find a measured reason not to; justify any deviation in the report)
1. **Registry, not physics.** The builder registers every potentially occluding visual when it creates it: `_add_box` / `_add_cylinder` for anything taller than 1.2 m (walls, pillars, kiosk fallback boxes, storefront walls, the mezzanine `DeckFloor` and both `DeckRail_*`, `FountainSpire` fallback), and `_add_prop` for the Meshy kiosks and the fountain sculpture. Each entry = the `GeometryInstance3D` (CSG node, or every `MeshInstance3D` under the prop root) plus a world-space AABB (computed once after the build; props: use `EnemyModel.bounds`). Floors, ramps, basin curbs, planters (0.85 m) and rails are NOT registered.
2. **Test per physics tick** (or every 2nd tick) the segment from the camera position to the player position + (0, 1.0, 0) against each registered AABB (`AABB.intersects_segment`). ~30 AABBs: no allocations per frame beyond reusing preallocated arrays; no `get_nodes_in_group` per frame; cache the player and camera references and refresh them only when invalid.
3. **Fade with `GeometryInstance3D.transparency`** (per-instance; does not touch materials), target 0.7 when occluding, 0.0 when not, smoothed with an exponential approach (~8/s in, ~5/s out) so there is no popping. Add a short hysteresis (keep an occluder faded for >= 0.15 s after it stops intersecting) to kill flicker when the segment grazes an edge. Multiple simultaneous occluders must all fade.
4. **Warm-up**: on the first frame after the build, set `transparency = 0.01` on one registered instance of each material kind (CSG box, CSG cylinder, a Meshy prop mesh) for one frame and restore it, so the transparent shader variant is compiled before combat.
5. **Restore reliably**: when the fader is freed or the scene changes, every instance returns to `transparency = 0.0`. Nothing may permanently alter a material or leave a node faded after the player moves away.
6. **Perimeter**: the camera looks from +x+z toward -x-z, so the south and east perimeter walls (1 m) are harmless, but `Wall_North` / `Wall_West` (4.5 m) and `Store_*` walls are not. They go through the same AABB test; do not special-case them.

## Tests (`tests/test_occlusion.gd`, headless, uses `_test_util.gd`, < 20 s)
- Load the real mall; assert the fader exists and registered >= 20 occluders including every `Pillar_*`, `Wall_North`, `Wall_West`, `DeckFloor`, both `DeckRail_*`, all `Store_*` walls, and the three kiosk props' meshes.
- Place the player so a known pillar (e.g. `Pillar_06` at (11, 2.5, -7)) sits between it and the camera (compute the position from the camera basis: player = pillar_pos - camera_forward * 3 m, on the floor); step physics >= 1 s; assert that pillar's `transparency` > 0.5 and that an unrelated pillar stays at 0.0.
- Move the player 10 m away; step >= 1 s; assert the pillar is back below 0.05.
- Two occluders at once (find a spot behind a storefront wall and a pillar; otherwise construct the case through the builder's registration API) both fade.
- Free the mall scene; assert no script errors and that the fader cleaned up.
The runner discovers `test_*.gd` automatically.

## Verification (paste real output)
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` — all suites PASS (20 with yours). `test_slice_e2e.gd` step c has a known timing flake under CPU load; if it fails, rerun it alone and paste that too.
- Headless cannot prove the fade visually. The Director will take screenshots with `ops/tools/shot_harness.gd` on merge. Give the Director a list of 4 `tp:x:y:z` player positions that should each produce a fade (pillar, mezzanine rail, storefront wall, kiosk prop) and 2 that must not.

## Commits
On `vs11-occlusion`, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Do not commit `*.import` changes or anything under `ops/runs/`. COMMIT BEFORE FINISHING — an uncommitted tree is a failed packet.

## Report
`ops/reports/VS11-OCC.md`: design as built, per-frame cost (count of AABB tests, allocations), pasted test output, the tp positions, STOP items.
