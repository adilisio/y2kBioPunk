# WP-3 — Presentation: lighting, color language, enemy silhouettes, HUD legibility, pager messaging
Agent: agy / gemini-3.1-pro-high. Slot: CODE. Worktree `C:\y2k-biopunk-rpg\.worktrees\wp3` on branch `wp3-presentation` (branched from main AFTER WP-1 merged). Stay there.

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/AUDIT-FEEL.md` section 4 items 7, 9, 10 and the HUD row of the scorecard, then this brief. Look at `ops/runs/shots/greybox.0.png` to see what the player sees today.

## Why this matters
The level is grey boxes under one hard light; "neon" emissives read flat because there is no glow; enemies share the player's green; the roach is a dark blob on a dark floor; HUD text is 9–13 px at 1080p. The game cannot read as a game until the eye knows where to look. This packet is art direction through parameters, not new assets.

## Direction (Director's call — do not relitigate)
- Palette: the world is desaturated teal-grey concrete and dark flood water; **player and player effects = acid green**; **enemies and enemy projectiles = hot magenta / toxic orange**; **interactables (checkpoint, candy, rails) = cyan / yellow**; **red is reserved for danger telegraphs**. Y2K touch: translucent plastic (alpha ~0.6, slight fresnel) on kiosks and the checkpoint shell, emissive strip lights along the mezzanine edge.
- Mood: late-night flooded mall, emergency lighting. Dark enough that emissives pop, bright enough to read the floor.

## You own (allowed files)
- `scenes/FloodedMall_Greybox.tscn`: ONLY the `WorldEnvironment` resource/node and `DirectionalLight3D`. Do not touch Player, HUD, Enemies, triggers.
- `scripts/mall_greybox_builder.gd`: materials (`_create_material` and the mat_* block), wall heights for `Wall_South`/`Wall_East` (cutaway to 1.0 m), pillar fade (see below), and new emissive strip lights. NOT `_spawn_enemies`.
- Enemy visuals: `scenes/neon_cicada.tscn` (now under `scenes/` after WP-1) materials; the CSG build functions in `scripts/sludge_roach.gd`, `scripts/corrupted_kiosk_turret.gd`, `scripts/dial_up_queen.gd` (visual construction only — not AI, not `take_damage`, not `_die`); `scripts/turret_mortar.gd` color only.
- `scripts/hud.gd` and the HUD nodes in the mall scene: sizes/fonts/layout, a new adrenaline bar, a `page_message(text, seconds)` API that shows a one-line message in the pager with a short beep (reuse `player.play_sfx` if a suitable name exists, else a 2-note procedural beep in GDScript using the SIGNED 8-bit format: `byte = int(clampf(v,-1,1)*127) & 0xFF`). Do NOT change `_ready` save logic, `_on_player_died`, or the victory/boss-gate functions WP-1 added — call `page_message` from them is allowed via a tiny edit.
- `project.godot`: rendering section only (MSAA 3D 2x, optional `physics/common/physics_ticks_per_second = 120` is NOT yours — leave it).

## Do not touch
`src/**`, `scripts/isometric_camera.gd`, `scripts/save_manager.gd`, `scripts/checkpoint.gd` (visual: you may change its material via a one-line color edit only), enemy AI logic, `tests/` other than adding `tests/test_presentation.gd`.

## Scope
1. **Environment.** WorldEnvironment: `background_mode` color (dark teal-black ~ #06090c), ambient light color ~ #1c2a30 energy 0.6, `glow_enabled = true`, `glow_intensity 0.8`, `glow_bloom 0.1`, `glow_hdr_threshold 0.9`, `ssao_enabled = true`, `fog_enabled = true` with light teal fog density ~0.004 and `fog_sky_affect 0`, `tonemap_mode = ACES`, `adjustment_enabled` with saturation 1.1. DirectionalLight: cool (#a9c6d8), energy 0.7, 45° steep angle, shadows on, `shadow_blur 1.5`. Add 2–3 `OmniLight3D` emergency lights (orange #ff7a1a, range 9, energy 2) at the kiosks and 1 cyan over the checkpoint, built in the builder so they survive a rebuild.
2. **Materials/color language.** Floor albedo #2a3136 roughness 0.9; water #0a3a3a with alpha 0.85, metallic 0.2, roughness 0.1 (reflects glow); pillars #c9ced4; kiosks translucent plastic (alpha 0.6, albedo #d7a042, emission #ff7a1a × 0.3); rails: metallic 0, albedo #ffd23f, emission #ffd23f × 0.6 (so they read as the grind path); mezzanine edge strip light: thin CSG box emission cyan × 1.5. South/East perimeter walls 1.0 m high (cutaway toward camera); pillars that intersect the camera→player segment set `transparency 0.75` (cheap ray test in builder `_process` or a small script; keep under 0.1 ms).
3. **Enemy silhouettes (CSG only, no new assets).** Cicada: magenta body (#ff2fa0) with two emissive orange "modem LED" eyes and translucent wing planes; Roach: orange-brown (#c9541a) with a magenta underglow and a visible head wedge so facing reads; Turret: dark chassis with the existing screen ramp intact (green→yellow→red stays — it is a telegraph), add a magenta antenna light; Queen: keep her phase colors, but her idle body is magenta/violet, not green. Mortar projectile `Color(1, 0.15, 0.6)` with a trail. Minimum on-screen height for a roach ≈ 45 px at the current camera: scale its mesh ×1.4 if needed, keep collision.
4. **HUD legibility.** Remove the 0.7 `scale` on the pager and Walkman boxes; set minimum font size 20 px (pager body), 24 px (HP numbers), 16 px (buff line). Keep the layout (pager top-left, HP bottom-center, action bar + Walkman bottom-right). Add a thin adrenaline bar under HP driven by `adrenaline_changed`. Add radial/alpha cooldown indication on the evade and secondary icons if the player exposes `get_evade_cooldown` (it does). `page_message(text, secs)` with a queue; call it on level-up ("LEVEL 3 // +1 STAT PT [C]"), skates toggle, tape switch (name + buff), and leave hooks for WP-1's boss-gate and WP-6's tutorial lines. Stop rebuilding BBCode every frame in `_process`; update on signals only (keep the equalizer animation).
5. **Test.** `tests/test_presentation.gd`: loads the mall scene off-tree and asserts WorldEnvironment glow/ssao on, south/east wall height ≤ 1.1, rails emissive, no HUD control with `scale` < 1.0, and `page_message` exists. `quit(1)` on failure.

## Verification
- Headless tests (CONTEXT.md allowed list + yours) pass.
- Screenshots via the harness (window placed off-screen): `./Godot_v4.3-stable_win64.exe --path . --windowed --resolution 1280x720 --position 2000,2000 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/wp3 "steps=wait:1,shot,press:toggle_skates,hold:move_forward:2,shot,hold:move_left:2,shot"`. Look at them. Enemies must be identifiable at a glance as hostile and distinct from the player; rails must read as yellow lines; HUD text must be readable at 1280x720.
- Do not open the editor.

## Commits
On `wp3-presentation`, per scope item, trailers:
```
Agent: gemini/gemini-3.1-pro-high
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

## Report
`ops/reports/WP-3.md` with screenshot paths, parameter table (before → after), anything skipped.
