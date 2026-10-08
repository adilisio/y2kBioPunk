# VS11-WARM — Effect warm-up report

Worktree: `C:\y2k-biopunk-rpg\.worktrees\vs11warm`; branch: `vs11-warm`.

## Result and limits

Implemented the deferred mall warm-up, a reusable `firstuse` harness diagnostic, and the required headless safety test. The latest controlled, cooled five-run verification is below 25 ms: spawn **11.7 / 12.2 / 12.3 ms**, turrets **12.4 ms**, Queen **11.8 ms**. Later uncontrolled/hot-machine repeats failed; their full output is preserved below, followed by this final cooled proof. The full suite passes **22/22**, exit **0**.

The Director's original 131.4 ms cicada hitch was **not reproduced** in the three unmodified-scene baseline runs (worst 12.4, 11.7, 12.0 ms). These runs cannot establish a causal before/after fix for that specific event. The diagnostic did expose a **294.032 ms** first render wait for the native grind-slam material, followed by **7.672 ms** on repeat; its constructor took 0.356 ms. Several synthesized audio calls also exceeded 3 ms.

## Commands and measurement conditions

Read the packet's complete required source list and the Performance ledger. Stayed in the assigned worktree. No native source, builder, HUD, environment values, or project settings changed. Only the packet-authorized off-screen harness ran windowed; no editor or on-screen game was opened.

Rendered commands were launched through `Start-Process -WindowStyle Hidden -PassThru`, with stdout/stderr redirected under `ops/runs/vs11warm/`. The wrapper cached the process handle, waited for completion and printed its actual exit code. Every rendered process exited **0**.

```powershell
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=<steps>
```

The harness's `fps` / `firstuse` explicitly disable vsync. Measured 3D viewport: 1440x810, scale 0.75, Forward+, MSAA 2x, SSAO/glow/fog enabled.

- Baseline: `invuln:1,wait:1,fps:8`, three engine processes before adding the scene node.
- Attribution: `invuln:1,bench` and `invuln:1,firstuse`. For the latter, temporarily removed the appended scene node and restored it byte-for-byte after the process exited. Enemy behaviour files were never instrumented or changed.
- Final spawn runs 1–3: `invuln:1,wait:1,fps:8`.
- Final turrets: `invuln:1,tp:1:0.5:-10,wait:0.5,fps:8`.
- Final Queen: `invuln:1,tp:0:1:-21,wait:2,fps:8`.

Invulnerability prevents death/menu flow from terminating combat measurements. Final runs sampled `nvidia-smi --query-gpu=clocks.gr,temperature.gpu,pstate --format=csv,noheader` every two seconds. All samples were P0, but clocks varied and successive runs warmed toward 77–78 C. Average FPS changes are not evidence of a speedup or a constant-clock replication of the Director's visible-window run.

Exact engine argument lists for baseline/final spawn, attribution, turret and Queen runs (launched through the wrapper above):

```powershell
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=invuln:1,wait:1,fps:8
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=invuln:1,bench
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=invuln:1,firstuse
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=invuln:1,tp:1:0.5:-10,wait:0.5,fps:8
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 --resolution 1440x810 --disable-vsync -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn steps=invuln:1,tp:0:1:-21,wait:2,fps:8
```

| Earlier clock-monitored validation (before final hurt retention) | Graphics clock range | Temperature range | Worst frame |
|---|---:|---:|---:|
| Spawn 1 | 949–1657 MHz | 68–76 C | 22.4 ms |
| Spawn 2 | 1215–1670 MHz | 75–77 C | 12.3 ms |
| Spawn 3 | 898–1430 MHz | 76–77 C | 15.2 ms |
| Turrets | 1088–1265 MHz | 76–77 C | 18.2 ms |
| Queen | 746–1442 MHz | 76–78 C | 22.6 ms |

## Implementation

- Six enemy tint colour/alpha/energy combinations: cicada/roach/turret/Queen hits and Queen phase colours. Wind-up uses the hit tint; roach recovery untints; turret ramp changes its existing light. No separate vulnerable overlay or turret ramp shader exists in this checkout.
- Imported enemy mesh format plus primitive fallback. A duplicate of the player's real visuals/skeleton draws the native opaque unshaded hurt-overlay variant. Live player bones/materials are not modified.
- Six burst colour kits using the real cached particle process material and mesh. The only mortar helper edit exposes `_burst_kit` as `burst_kit`; ordinary burst behaviour is unchanged.
- Real mortar/disk script instances, disabled processing and zero collision layers/masks/monitoring both before insertion and immediately after their `_ready` methods set defaults. The mortar marker is matched without calling `setup`, which also starts audio and gameplay flight.
- Matching Queen torus outline/blast, CSG telegraph cylinder, and native grind-slam cylinder/material. Boss/slam gameplay methods are never called.
- Duplicate of the player's actual flame particles, including scene quad/material/process resources. Tiny simulation speed plus preprocessing keeps emitted particles at the frustum probe.
- All 12 enemy/mortar/burst synthesized sound recipes through a dedicated per-instance audio bus at -80 dB **and muted**. The bus is removed on teardown. Native player SFX already synthesize/cache in player `_ready`; no redundant calls through live player signals.

The scene diff is exactly three appended lines, using `script = Resource("res://scripts/effect_warmup.gd")`. `_ready` defers and waits a process frame for the parent mall build. Jobs yield after approximately 3 ms of script work; an atomic synthesis call can exceed that slice. Every probe survives at least two further process/render submissions, then the root frees itself.

Resources remain cached, including one independent material per warmed shader feature set. They are not handed to gameplay, where tint tweens must remain independent. Retention is bounded across level reloads.

Probes are scaled to 0.0001 and placed inside the camera's upper-left frustum at 1 m depth, underneath the pager. Position follows camera settling. They remain visible to the renderer. A rendered screenshot after warm-up was inspected (`ops/runs/shots/shot.0.png`): the player remained at 100 HP and no probe geometry remained. This is an off-screen rendered capture, not a headless presentation claim.

Temporary startup instrumentation, removed before commit:

```text
[EffectWarmup] 25 jobs; script work 41.27 ms (GPU time measured by harness only)
[EffectWarmup] 25 jobs; script work 41.70 ms elapsed 237.48 ms yields 9 (GPU time measured by harness only)
```

Measured script work is below 50 ms, spread across nine yields. Elapsed time includes ordinary startup/vsync frames and stays below the 1.5 s encounter window. **This does not establish a <50 ms combined CPU/GPU budget with cold driver pipelines.**

## Attribution and visibility

The `firstuse` diagnostic buffers output until measurements finish, avoiding stdout overhead. CPU creation/cache/play is timed separately from the maximum wait to `frame_post_draw` over three submissions. Draw waits include normal mall rendering; ordinary ~7–11 ms values are not wholly attributable to an effect. Probes accumulated as this diagnostic progressed; its 57.914 ms sum of first CPU calls is not the normal startup measurement above.

The initial attribution table used a lightweight player mesh probe; the final implementation duplicates the complete relative skeleton hierarchy for correct skinning. That diagnostic construction now costs 6.670/7.133 ms (first/repeat), with 9.407/9.067 ms draw waits. This is the duplicate construction cost, not the live player's hurt callback cost. The final diagnostic's artificial hidden/first-drawn/repeated check was 9.850/164.771/9.804 ms with 292/295/295 draw calls.

`player.take_damage(0)` in the existing bench is a no-op due to the native amount guard. It does not measure a real hurt flash; the warm-up submits the matching variant on duplicated visuals. Hit-stop is not artificially triggered, since it would change time scale/gameplay and no expensive resource first-use was established for it. A cosmetic tint tween initializes the ordinary Tween path.

The visibility check uses a unique artificial shader, independent of previously cached gameplay shaders. This is a draw-trigger verification, not an attribution to cicada behaviour:

```text
[FIRSTUSE] unique shader hidden draw_wait_max=7.103 ms draw_calls=312
[FIRSTUSE] unique shader first drawn draw_wait_max=181.821 ms draw_calls=315
[FIRSTUSE] unique shader drawn again draw_wait_max=7.197 ms draw_calls=315
```

The hidden node did not consume the first-draw cost: its subsequent first visible submission waited 181.821 ms, then returned to 7.197 ms. The final diagnostic freezes scene processing during this check to stabilize draw counts and waits for automatic warm-up teardown before probing. Godot 4.3's [Forward+ draw loop](https://github.com/godotengine/godot/blob/4.3-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp#L434) obtains/binds the render pipeline during actual submissions, supporting in-frustum probes instead of hidden nodes.

## Headless test

```powershell
./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_effect_warmup.gd
```

Standalone exit **0**, elapsed **5.72 s**, including engine load/cleanup. First suite run of this test: **5.04 s**; final complete suite: **5.13 s**. Both are below 15 s. The test uses `_test_util.gd` and checks the assigned scene script; after one second no warm-up/probe remains, player and all nine enemy health values are unchanged, no enemy was added/removed, the tree is unpaused, time scale stays 1, the temporary bus is removed, and all actual burst/sound cache entries exist.

Dummy skips drawing/skin probes because it has no GPU pipelines; it still executes real burst-cache/sound jobs. Headless cannot measure the rendering hitch.

## STOP items / unverified claims

1. Original cicada 131.4 ms event was not reproduced in three baseline runs. Shader/audio costs are established separately; claiming that specific event is definitively fixed would overstate the evidence.
2. A universal <50 ms cold combined CPU/GPU warm-up is not established. Script work was 41.70 ms; elapsed warm-up was 237.48 ms over nine yields. An individual first slam draw waited 294.032 ms. Godot 4.3 can block inside pipeline creation; yielding GDScript cannot subdivide that call. No renderer upgrade, native change, shared driver-cache deletion or project-setting change was attempted outside ownership.
3. All five final cooled segments meet worst-frame <25 ms. Earlier 21.7–22.6 ms slow frames remain individually unattributed; later hot-machine repeats failed with sustained low GPU clocks. Those failures are not discarded. No change here fixes machine clock/thermal variability.
4. Baseline and some rendered runs print ObjectDB/resource-in-use shutdown diagnostics. The standalone headless test prints one Dummy `mesh_get_surface_count` null-mesh diagnostic. Verbose runs also report a missing external Epic Vulkan layer manifest. These are recorded warnings/errors, not script assertion failures or a warning-free claim.

## Pasted evidence

The following sections contain actual output: attribution table, bench lines, all before/after `[FPS]` lines including every `SLOW FRAME`, standalone test output, final diagnostic excerpts, and full suite console output. Logs/screenshots stay under ignored `ops/runs/` and are not committed.

Console table padding at the ends of lines is trimmed; values and all evidence lines are preserved.

### Attribution table

| Effect / sound recipe | First CPU ms | Repeat CPU ms | First draw wait ms | Repeat draw wait ms |
|---|---:|---:|---:|---:|
| enemy overlays | 4.159 | 4.753 | 10.073 | 11.403 |
| player hurt overlay | 0.802 | 0.853 | 9.482 | 9.210 |
| mortar + landing marker | 1.943 | 1.890 | 9.465 | 9.510 |
| disk projectile | 0.168 | 0.211 | 9.057 | 8.898 |
| Queen outline + telegraph + blast rings | 1.146 | 1.021 | 8.529 | 8.940 |
| native grind slam material | 0.356 | 0.329 | 294.032 | 7.672 |
| player flamethrower particles | 0.414 | 0.347 | 7.596 | 7.637 |
| burst 1affb3 | 0.370 | 0.108 | 19.290 | 7.170 |
| burst 66b31a | 0.334 | 0.112 | 7.144 | 7.827 |
| burst ff800d | 0.417 | 0.090 | 7.115 | 7.674 |
| burst ff5905 | 0.399 | 0.073 | 7.611 | 7.113 |
| burst ff4d0d | 0.261 | 0.079 | 7.902 | 7.010 |
| burst ff1a80 | 0.220 | 0.096 | 7.672 | 7.616 |
| sound (0.16, 1800, 0.2) | 1.568 | 0.084 | 7.143 | 7.578 |
| sound (0.25, 1300, 0.85) | 2.409 | 0.104 | 7.599 | 7.589 |
| sound (0.35, 500, 0) | 3.632 | 0.084 | 7.950 | 8.040 |
| sound (0.35, 1000, 0) | 3.642 | 0.107 | 7.615 | 7.624 |
| sound (0.18, 90, 0.4) | 1.689 | 0.085 | 7.813 | 7.824 |
| sound (0.8, 1600, 0.35) | 7.974 | 0.066 | 7.398 | 7.675 |
| sound (0.25, 700, 0.65) | 3.054 | 0.073 | 7.977 | 7.651 |
| sound (0.25, 90, 0.65) | 2.856 | 0.102 | 7.537 | 7.632 |
| sound (0.25, 80, 0.65) | 6.789 | 0.106 | 7.353 | 7.888 |
| sound (0.25, 65, 0.65) | 4.873 | 0.097 | 6.822 | 7.653 |
| sound (0.35, 45, 0.65) | 4.855 | 0.093 | 7.691 | 7.470 |
| sound (0.25, 60, 0.65) | 3.584 | 0.106 | 8.003 | 7.632 |

### Existing bench (exit 0)

```text
[BENCH] rep 0: | tint_material+tint (new mat)=0.06 ms | untint=0.08 ms | tint (reused mat)=0.03 ms | sfx stream (cached) + play=2.21 ms | AudioStreamPlayer3D new+add+play=0.11 ms | print x3=10.81 ms | 2 tweens on model scale=0.04 ms | player.take_damage(0)=0.03 ms | FX.burst (cached kit)=2.25 ms
[BENCH] rep 1: | tint_material+tint (new mat)=0.07 ms | untint=0.09 ms | tint (reused mat)=0.03 ms | sfx stream (cached) + play=0.06 ms | AudioStreamPlayer3D new+add+play=0.06 ms | print x3=5.23 ms | 2 tweens on model scale=0.02 ms | player.take_damage(0)=0.02 ms | FX.burst (cached kit)=0.16 ms
[BENCH] rep 2: | tint_material+tint (new mat)=0.07 ms | untint=0.05 ms | tint (reused mat)=0.03 ms | sfx stream (cached) + play=0.04 ms | AudioStreamPlayer3D new+add+play=0.06 ms | print x3=4.93 ms | 2 tweens on model scale=0.02 ms | player.take_damage(0)=0.01 ms | FX.burst (cached kit)=0.16 ms
```

### Before: unmodified mall

Run 1, exit 0:

```text
[FPS] physics avg=1.64 ms max=4.16 ms | process max=17.42 ms | frames over 2x avg: 0 of 1076 | active_objects=10 collision_pairs=88 islands=33
[FPS] frames=1076 avg=134.4 fps (7.44 ms)  1%low=94.1 fps (10.63 ms)  worst=12.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.97 ms physics=0.97 ms render_cpu=0.30 ms render_gpu=7.26 ms objects=322 primitives=236710 draw_calls=316
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 2, exit 0:

```text
[FPS] physics avg=1.75 ms max=3.98 ms | process max=17.32 ms | frames over 2x avg: 0 of 1054 | active_objects=10 collision_pairs=85 islands=31
[FPS] frames=1054 avg=131.7 fps (7.59 ms)  1%low=96.0 fps (10.42 ms)  worst=11.7 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=8.29 ms physics=3.82 ms render_cpu=0.31 ms render_gpu=7.23 ms objects=322 primitives=216216 draw_calls=316
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 3, exit 0:

```text
[FPS] physics avg=1.43 ms max=3.78 ms | process max=17.60 ms | frames over 2x avg: 0 of 1064 | active_objects=10 collision_pairs=93 islands=37
[FPS] frames=1064 avg=132.9 fps (7.52 ms)  1%low=97.8 fps (10.23 ms)  worst=12.0 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.97 ms physics=1.27 ms render_cpu=0.40 ms render_gpu=7.13 ms objects=322 primitives=216216 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

### Initial warm-up runs before final retention/camera/skeleton refinements

Run 1, exit 0:

```text
[FPS] physics avg=0.88 ms max=1.18 ms | process max=23.17 ms | frames over 2x avg: 0 of 1086 | active_objects=10 collision_pairs=80 islands=30
[FPS] frames=1086 avg=135.7 fps (7.37 ms)  1%low=101.7 fps (9.83 ms)  worst=11.9 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.78 ms physics=0.96 ms render_cpu=0.35 ms render_gpu=6.70 ms objects=298 primitives=216168 draw_calls=291
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 2, exit 0:

```text
[FPS] physics avg=1.30 ms max=3.88 ms | process max=17.69 ms | frames over 2x avg: 0 of 968 | active_objects=10 collision_pairs=95 islands=39
[FPS] frames=968 avg=121.0 fps (8.27 ms)  1%low=92.7 fps (10.79 ms)  worst=12.9 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=10.10 ms physics=1.05 ms render_cpu=0.34 ms render_gpu=9.54 ms objects=322 primitives=257204 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 3, exit 0:

```text
[FPS] physics avg=1.20 ms max=4.21 ms | process max=19.19 ms | frames over 2x avg: 0 of 821 | active_objects=10 collision_pairs=93 islands=37
[FPS] frames=821 avg=102.6 fps (9.75 ms)  1%low=81.8 fps (12.22 ms)  worst=16.9 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=10.36 ms physics=0.68 ms render_cpu=0.31 ms render_gpu=9.72 ms objects=322 primitives=216216 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 4, exit 0:

```text
[FPS] physics avg=2.46 ms max=4.85 ms | process max=18.41 ms | frames over 2x avg: 0 of 782 | active_objects=10 collision_pairs=88 islands=37
[FPS] frames=782 avg=97.6 fps (10.24 ms)  1%low=71.0 fps (14.08 ms)  worst=16.8 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=11.03 ms physics=0.89 ms render_cpu=0.31 ms render_gpu=9.27 ms objects=307 primitives=217540 draw_calls=299
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 5, exit 0:

```text
[FPS] physics avg=3.13 ms max=4.94 ms | process max=22.05 ms | frames over 2x avg: 0 of 733 | active_objects=11 collision_pairs=79 islands=29
[FPS] frames=733 avg=91.6 fps (10.92 ms)  1%low=71.4 fps (14.01 ms)  worst=16.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=13.25 ms physics=4.39 ms render_cpu=0.62 ms render_gpu=8.45 ms objects=360 primitives=212956 draw_calls=358
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

### Earlier clock-monitored implementation validation

Run 1, exit 0:

```text
[FPS] SLOW FRAME t=6.66s 22.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.06s 22.4 ms (objects=317 draw_calls=311)
[FPS] physics avg=9.00 ms max=14.97 ms | process max=17.37 ms | frames over 2x avg: 10 of 1073 | active_objects=10 collision_pairs=82 islands=29
[FPS] frames=1073 avg=134.0 fps (7.46 ms)  1%low=70.6 fps (14.17 ms)  worst=22.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=12.80 ms physics=14.97 ms render_cpu=0.29 ms render_gpu=6.58 ms objects=297 primitives=205921 draw_calls=292
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 2, exit 0:

```text
[FPS] physics avg=0.87 ms max=1.06 ms | process max=19.97 ms | frames over 2x avg: 0 of 934 | active_objects=10 collision_pairs=93 islands=38
[FPS] frames=934 avg=116.7 fps (8.57 ms)  1%low=89.9 fps (11.13 ms)  worst=12.3 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=10.56 ms physics=0.92 ms render_cpu=0.39 ms render_gpu=9.70 ms objects=323 primitives=226463 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 3, exit 0:

```text
[FPS] physics avg=0.83 ms max=1.06 ms | process max=19.43 ms | frames over 2x avg: 0 of 809 | active_objects=10 collision_pairs=93 islands=37
[FPS] frames=809 avg=101.1 fps (9.89 ms)  1%low=73.0 fps (13.70 ms)  worst=15.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=13.19 ms physics=1.06 ms render_cpu=0.29 ms render_gpu=12.42 ms objects=322 primitives=216216 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 4, exit 0:

```text
[FPS] physics avg=1.87 ms max=5.21 ms | process max=20.45 ms | frames over 2x avg: 0 of 745 | active_objects=10 collision_pairs=82 islands=33
[FPS] frames=745 avg=93.0 fps (10.75 ms)  1%low=65.9 fps (15.19 ms)  worst=18.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=11.11 ms physics=0.77 ms render_cpu=0.28 ms render_gpu=10.18 ms objects=306 primitives=207293 draw_calls=299
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Run 5, exit 0:

```text
[FPS] SLOW FRAME t=1.74s 21.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.52s 22.6 ms (objects=360 draw_calls=359)
[FPS] physics avg=2.32 ms max=5.58 ms | process max=30.76 ms | frames over 2x avg: 0 of 581 | active_objects=11 collision_pairs=87 islands=34
[FPS] frames=581 avg=72.5 fps (13.79 ms)  1%low=50.2 fps (19.91 ms)  worst=22.6 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=21.85 ms physics=4.91 ms render_cpu=0.29 ms render_gpu=14.34 ms objects=360 primitives=212956 draw_calls=359
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

### Standalone safety test (exit 0)

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[EffectWarmup] lifecycle, player/enemy health, time scale and cached resources checked after 1 s
RESULT: PASS
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

### Final diagnostic (exit 0)

```text
[FIRSTUSE] unique shader hidden draw_wait_max=9.850 ms draw_calls=292
[FIRSTUSE] unique shader first drawn draw_wait_max=164.771 ms draw_calls=295
[FIRSTUSE] unique shader drawn again draw_wait_max=9.804 ms draw_calls=295
[FIRSTUSE] player hurt overlay rep=0 cpu=6.670 ms draw_wait_max=9.407 ms
[FIRSTUSE] player hurt overlay rep=1 cpu=7.133 ms draw_wait_max=9.067 ms
[FIRSTUSE] native grind slam material rep=0 cpu=0.401 ms draw_wait_max=8.809 ms
[FIRSTUSE] native grind slam material rep=1 cpu=0.524 ms draw_wait_max=8.543 ms
[FIRSTUSE] sound (0.8, 1600, 0.35) rep=0 cpu=0.186 ms draw_wait_max=7.709 ms
[FIRSTUSE] sound (0.8, 1600, 0.35) rep=1 cpu=0.125 ms draw_wait_max=7.665 ms
```

### Full suite

No other Godot process was present immediately before launch; waited for the other worktree suite to finish. Command:

```powershell
powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1
```

Actual runner exit **0**. All 22 suites pass, including e2e; no isolated e2e rerun was needed.

```text
=================================================================
 Y2K BIO-PUNK ARPG - TEST SUITE RUNNER
 Engine : C:\y2k-biopunk-rpg\.worktrees\vs11warm\Godot_v4.3-stable_win64.exe
 Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11warm
 Timeout: 120s per test
=================================================================
Discovered 22 test suite files.
[PASS] test_3d_player.gd                (Code:  0, Time:  4.76s) - All checks passed
[PASS] test_5_systems.gd                (Code:  0, Time:  5.13s) - Passed (contains SKIP section)
[PASS] test_candy_pickup.gd             (Code:  0, Time:  0.86s) - All checks passed
[PASS] test_character_sheet.gd          (Code:  0, Time:   9.4s) - All checks passed
[PASS] test_critical_path.gd            (Code:  0, Time:  4.53s) - All checks passed
[PASS] test_cursor_aiming.gd            (Code:  0, Time:  0.85s) - All checks passed
[PASS] test_effect_warmup.gd            (Code:  0, Time:  5.04s) - All checks passed
[PASS] test_encounters.gd               (Code:  0, Time: 27.22s) - All checks passed
[PASS] test_feel_combat.gd              (Code:  0, Time:  3.32s) - All checks passed
[PASS] test_feel_movement.gd            (Code:  0, Time:  8.01s) - All checks passed
[PASS] test_feel_traversal.gd           (Code:  0, Time:  2.16s) - All checks passed
[PASS] test_flamethrower_particles.gd   (Code:  0, Time:  0.43s) - All checks passed
[PASS] test_gameplay_fixes.gd           (Code:  0, Time:   1.5s) - All checks passed
[PASS] test_grinding.gd                 (Code:  0, Time:  4.39s) - All checks passed
[PASS] test_menu_flow.gd                (Code:  0, Time:  4.45s) - All checks passed
[PASS] test_occlusion.gd                (Code:  0, Time: 12.74s) - All checks passed
[PASS] test_onboarding.gd               (Code:  0, Time: 10.09s) - All checks passed
[PASS] test_presentation.gd             (Code:  0, Time:  4.81s) - All checks passed
[PASS] test_slice_e2e.gd                (Code:  0, Time: 34.23s) - All checks passed
[PASS] test_systems.gd                  (Code:  0, Time:  0.73s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.83s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  1.52s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status ExitCode Time   Details
----                           ------ -------- ----   -------
test_3d_player.gd              PASS          0 4.76s  All checks passed
test_5_systems.gd              PASS          0 5.13s  Passed (contains SKIP section)
test_candy_pickup.gd           PASS          0 0.86s  All checks passed
test_character_sheet.gd        PASS          0 9.4s   All checks passed
test_critical_path.gd          PASS          0 4.53s  All checks passed
test_cursor_aiming.gd          PASS          0 0.85s  All checks passed
test_effect_warmup.gd          PASS          0 5.04s  All checks passed
test_encounters.gd             PASS          0 27.22s All checks passed
test_feel_combat.gd            PASS          0 3.32s  All checks passed
test_feel_movement.gd          PASS          0 8.01s  All checks passed
test_feel_traversal.gd         PASS          0 2.16s  All checks passed
test_flamethrower_particles.gd PASS          0 0.43s  All checks passed
test_gameplay_fixes.gd         PASS          0 1.5s   All checks passed
test_grinding.gd               PASS          0 4.39s  All checks passed
test_menu_flow.gd              PASS          0 4.45s  All checks passed
test_occlusion.gd              PASS          0 12.74s All checks passed
test_onboarding.gd             PASS          0 10.09s All checks passed
test_presentation.gd           PASS          0 4.81s  All checks passed
test_slice_e2e.gd              PASS          0 34.23s All checks passed
test_systems.gd                PASS          0 0.73s  All checks passed
test_tapes.gd                  PASS          0 0.83s  All checks passed
verify_camera_and_hud.gd       PASS          0 1.52s  All checks passed



Totals: 22 tests | 22 PASSED | 0 FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11warm\ops\runs\tests\20261008_140612.log

Test suite PASSED successfully.
SUITE exit=0
```

## Repeat after retaining the player hurt material

Review found that the player hurt material should also remain in the bounded shader-resource cache. Added that retention, then repeated all five segments. This repeat was contaminated by another rendered benchmark from the main checkout. Read-only process inventory during the repeat showed:

```text
C:\y2k-biopunk-rpg\Godot_v4.3-stable_win64.exe --path . --windowed --resolution 1920x1080 --position 2000,2000 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/vs11/perf2 steps=invuln:1,wait:1,fps:6,tp:8.879:0.1:-9.121,wait:0.5,fps:6,tp:0:1:-21,wait:2,fps:12
nvidia-smi: 139 MHz, 77 C, P2, 100% utilization, 25.09 W
```

This was sustained GPU slowdown, not a single first-use outlier: one run ended at render_gpu=96.19 ms while render_cpu=0.33 ms. No other process was stopped. These failed repeat measurements are preserved below; they do not satisfy the <25 ms gate. The earlier passing set above preceded only the additional player hurt-material retention. Another isolated verification is recorded separately after cooling.

Contaminated repeat 1, exit 0:

```text
[FPS] SLOW FRAME t=0.45s 22.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.34s 24.5 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=3.75s 32.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.86s 109.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.00s 137.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.11s 115.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.23s 112.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.33s 101.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.44s 112.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.55s 112.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.66s 108.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.76s 103.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.87s 107.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.98s 110.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.09s 105.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.19s 105.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.30s 111.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.42s 116.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.54s 119.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.66s 116.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.77s 116.6 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.88s 104.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=5.98s 104.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.09s 107.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.21s 118.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.32s 110.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.42s 104.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.54s 116.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.66s 123.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.79s 122.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=6.94s 158.6 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=7.08s 135.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=7.23s 146.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=7.33s 103.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=7.45s 115.0 ms (objects=298 draw_calls=292)
[FPS] SLOW FRAME t=7.57s 125.7 ms (objects=298 draw_calls=292)
[FPS] SLOW FRAME t=7.67s 103.3 ms (objects=298 draw_calls=292)
[FPS] SLOW FRAME t=7.80s 121.7 ms (objects=298 draw_calls=292)
[FPS] SLOW FRAME t=7.91s 115.1 ms (objects=299 draw_calls=292)
[FPS] SLOW FRAME t=8.01s 99.8 ms (objects=299 draw_calls=292)
[FPS] physics avg=1.66 ms max=2.34 ms | process max=157.89 ms | frames over 2x avg: 37 of 271 | active_objects=10 collision_pairs=80 islands=29
[FPS] frames=271 avg=33.8 fps (29.56 ms)  1%low=7.3 fps (137.78 ms)  worst=158.6 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=140.43 ms physics=1.12 ms render_cpu=0.33 ms render_gpu=96.19 ms objects=299 primitives=226415 draw_calls=292
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Contaminated repeat 2, exit 0:

```text
[FPS] physics avg=0.90 ms max=1.04 ms | process max=174.07 ms | frames over 2x avg: 0 of 639 | active_objects=10 collision_pairs=85 islands=31
[FPS] frames=639 avg=79.8 fps (12.53 ms)  1%low=60.6 fps (16.49 ms)  worst=19.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=13.93 ms physics=0.93 ms render_cpu=0.31 ms render_gpu=11.98 ms objects=322 primitives=236710 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Contaminated repeat 3, exit 0:

```text
[FPS] SLOW FRAME t=0.08s 75.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.14s 61.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.20s 62.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.26s 56.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.31s 58.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.37s 55.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.42s 51.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.47s 53.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.53s 53.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.58s 53.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.64s 58.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.70s 62.7 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.76s 61.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.82s 55.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.87s 52.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.93s 55.7 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.98s 51.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.03s 51.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.08s 51.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.13s 52.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.18s 52.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.24s 52.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.29s 54.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.34s 50.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.39s 51.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.44s 50.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.49s 51.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.54s 50.6 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=1.60s 51.5 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=1.65s 51.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=1.76s 114.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=1.86s 99.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=1.93s 73.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.09s 155.6 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.22s 128.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.39s 168.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.54s 155.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.71s 171.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=2.87s 160.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.03s 156.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.19s 157.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.34s 155.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.50s 157.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.66s 156.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.81s 156.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=3.99s 172.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.15s 166.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.31s 157.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.49s 178.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.65s 164.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.75s 96.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=4.91s 160.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.07s 163.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.23s 160.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.40s 166.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.57s 174.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.75s 175.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.92s 171.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.04s 113.6 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.07s 38.5 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.11s 35.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.14s 32.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.18s 36.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.21s 36.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.25s 34.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.28s 28.6 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.31s 30.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.34s 30.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.37s 29.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.39s 27.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.42s 30.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.45s 30.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.48s 29.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.52s 31.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.54s 27.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.57s 27.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.60s 29.5 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.63s 31.6 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.66s 27.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.69s 30.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.72s 30.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.75s 29.5 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.77s 24.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.80s 26.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.83s 27.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.86s 26.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.88s 26.3 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.91s 30.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.94s 24.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.97s 30.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.00s 30.5 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.03s 27.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.06s 31.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.09s 29.4 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.11s 28.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.15s 31.7 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.18s 31.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=7.21s 28.8 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.24s 33.1 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.27s 29.7 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.30s 29.1 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.33s 29.5 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.36s 27.6 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.39s 30.3 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.42s 29.9 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.44s 28.2 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.47s 29.4 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.50s 29.9 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.53s 26.3 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.56s 32.2 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.59s 30.1 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.62s 31.7 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.65s 29.8 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.68s 31.1 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.71s 30.5 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.74s 27.6 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.77s 26.3 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.80s 29.8 ms (objects=322 draw_calls=315)
[FPS] SLOW FRAME t=7.83s 31.5 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=7.86s 30.3 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=7.89s 27.4 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=7.92s 29.4 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=7.95s 32.6 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=7.98s 25.9 ms (objects=323 draw_calls=315)
[FPS] SLOW FRAME t=8.00s 27.5 ms (objects=323 draw_calls=315)
[FPS] physics avg=0.91 ms max=1.35 ms | process max=172.71 ms | frames over 2x avg: 24 of 125 | active_objects=10 collision_pairs=97 islands=40
[FPS] frames=125 avg=15.6 fps (64.02 ms)  1%low=5.7 fps (175.93 ms)  worst=178.3 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=32.03 ms physics=0.86 ms render_cpu=0.32 ms render_gpu=25.46 ms objects=323 primitives=226463 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Contaminated repeat 4, exit 0:

```text
[FPS] SLOW FRAME t=0.03s 34.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.07s 33.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.10s 34.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.14s 34.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.17s 33.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.20s 34.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.24s 33.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.28s 38.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=0.30s 28.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.34s 33.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.37s 33.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.41s 37.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.44s 32.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.48s 33.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.51s 34.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.55s 36.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.58s 35.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.62s 37.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.65s 35.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.69s 36.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.73s 34.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.76s 35.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.79s 34.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.83s 37.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.87s 37.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.91s 38.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.94s 34.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=0.98s 32.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.01s 34.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.04s 35.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.08s 34.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.11s 34.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.15s 33.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.18s 32.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.21s 35.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.25s 31.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.28s 34.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.31s 31.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.34s 32.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.38s 33.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.41s 33.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.44s 35.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.48s 32.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.51s 32.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.54s 31.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.57s 33.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.61s 32.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.64s 30.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.67s 34.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.70s 33.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.74s 32.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.77s 35.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.80s 30.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.84s 35.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.87s 35.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.91s 35.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.95s 36.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.98s 37.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.02s 36.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.06s 36.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.09s 31.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.12s 34.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.15s 32.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.19s 35.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.22s 33.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.26s 40.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.30s 39.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.35s 41.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.39s 41.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.43s 40.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.48s 52.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.53s 53.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.58s 49.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.63s 50.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.68s 50.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.73s 42.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.77s 39.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.81s 44.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.85s 42.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.89s 43.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.93s 34.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.96s 35.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.00s 33.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.03s 32.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.06s 32.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.10s 35.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.13s 34.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.16s 30.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.19s 31.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.23s 36.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.26s 32.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.30s 35.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.33s 35.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.37s 35.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.40s 30.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.44s 35.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.47s 33.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.50s 31.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.54s 36.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.57s 33.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.60s 33.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.63s 28.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.67s 33.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.70s 34.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.73s 33.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.77s 33.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.80s 33.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.84s 34.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.87s 36.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.91s 36.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.94s 34.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.98s 36.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.02s 37.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.05s 35.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.09s 40.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.12s 27.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.16s 35.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.19s 37.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.23s 36.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.27s 34.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.30s 34.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.34s 36.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.37s 36.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.41s 33.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.44s 33.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.48s 36.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.51s 35.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.77s 35.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.81s 36.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.84s 37.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.88s 37.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.92s 36.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.95s 33.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.99s 36.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.02s 33.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.06s 37.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.09s 33.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.12s 33.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.16s 33.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.19s 33.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.23s 33.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.26s 34.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.30s 35.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.33s 35.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.37s 35.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.40s 35.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.44s 38.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.48s 36.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.51s 34.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.55s 35.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.58s 36.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.62s 33.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.65s 32.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.68s 34.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.72s 32.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.75s 34.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.79s 35.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.82s 31.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.85s 30.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.88s 32.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.91s 32.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.94s 31.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=5.98s 35.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.01s 32.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.05s 36.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.08s 29.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.12s 35.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.15s 36.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.19s 34.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.22s 36.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.25s 31.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.29s 33.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.32s 29.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.35s 33.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.38s 31.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.42s 33.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.45s 35.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.49s 36.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.52s 33.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.55s 30.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.59s 33.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.62s 36.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.70s 32.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.74s 36.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.77s 34.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.80s 33.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.84s 32.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.87s 33.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.90s 34.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.94s 38.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.98s 35.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.01s 37.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.05s 34.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.08s 35.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.11s 29.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.14s 29.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.18s 34.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.21s 33.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.24s 33.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.28s 31.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.31s 29.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.34s 30.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.37s 32.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.40s 32.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.44s 33.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.47s 32.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.50s 31.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.53s 31.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.57s 35.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.60s 34.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.63s 31.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.67s 38.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.70s 30.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.74s 36.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.77s 35.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.80s 31.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.84s 33.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.87s 33.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.91s 36.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=7.94s 32.1 ms (objects=314 draw_calls=307)
[FPS] SLOW FRAME t=7.97s 31.7 ms (objects=314 draw_calls=307)
[FPS] SLOW FRAME t=8.01s 35.5 ms (objects=314 draw_calls=307)
[FPS] physics avg=1.97 ms max=5.63 ms | process max=120.68 ms | frames over 2x avg: 0 of 239 | active_objects=10 collision_pairs=85 islands=36
[FPS] frames=239 avg=29.9 fps (33.50 ms)  1%low=19.8 fps (50.59 ms)  worst=53.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=36.78 ms physics=0.79 ms render_cpu=0.31 ms render_gpu=32.82 ms objects=314 primitives=244503 draw_calls=307
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Contaminated repeat 5, exit 0:

```text
[FPS] SLOW FRAME t=0.81s 30.2 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=0.86s 46.9 ms (objects=358 draw_calls=357)
[FPS] SLOW FRAME t=0.91s 53.3 ms (objects=355 draw_calls=354)
[FPS] SLOW FRAME t=0.96s 50.1 ms (objects=355 draw_calls=354)
[FPS] SLOW FRAME t=1.01s 48.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.05s 47.2 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.10s 47.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.15s 47.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.20s 48.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.25s 48.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.29s 48.5 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.34s 48.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.39s 48.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.44s 48.6 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.49s 49.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.54s 52.5 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.59s 49.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.64s 51.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.70s 53.2 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.75s 53.5 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.80s 53.6 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.86s 55.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.91s 53.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=1.97s 53.5 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.02s 54.6 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.08s 57.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.13s 54.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.18s 52.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.24s 52.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.29s 52.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.34s 53.2 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.40s 53.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=2.45s 52.8 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.50s 51.6 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.55s 51.9 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.61s 54.0 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.66s 48.9 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.70s 48.2 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.75s 47.8 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.80s 47.3 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.85s 46.7 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.89s 47.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.94s 46.5 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=2.99s 47.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.04s 50.2 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.08s 42.2 ms (objects=358 draw_calls=357)
[FPS] SLOW FRAME t=3.13s 47.0 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=3.18s 49.2 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=3.22s 46.5 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=3.27s 48.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.32s 48.5 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.37s 50.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.42s 52.4 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.47s 47.9 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.50s 26.7 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.52s 22.6 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.74s 24.0 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.76s 22.3 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.79s 22.0 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.81s 23.5 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.85s 21.7 ms (objects=357 draw_calls=356)
[FPS] physics avg=2.33 ms max=5.57 ms | process max=71.12 ms | frames over 2x avg: 53 of 465 | active_objects=11 collision_pairs=86 islands=34
[FPS] frames=465 avg=58.1 fps (17.22 ms)  1%low=18.5 fps (53.99 ms)  worst=57.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=14.18 ms physics=4.59 ms render_cpu=0.28 ms render_gpu=11.40 ms objects=357 primitives=210076 draw_calls=356
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

## GPU-isolated repeat and suite interruption

The optional suite rerun was stopped before e2e when a main-checkout headless suite appeared after launch. Only this worktree runner and its own child were stopped, using parent IDs anchored to this worktree Godot command line. The original complete 22/22 pass remains above. The interrupted rerun was not a passing full suite:

```text
=================================================================
 Y2K BIO-PUNK ARPG - TEST SUITE RUNNER
 Engine : C:\y2k-biopunk-rpg\.worktrees\vs11warm\Godot_v4.3-stable_win64.exe
 Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11warm
 Timeout: 120s per test
=================================================================
Discovered 22 test suite files.
[PASS] test_3d_player.gd                (Code:  0, Time:  4.76s) - All checks passed
[PASS] test_5_systems.gd                (Code:  0, Time:  5.31s) - Passed (contains SKIP section)
[PASS] test_candy_pickup.gd             (Code:  0, Time:  0.76s) - All checks passed
[PASS] test_character_sheet.gd          (Code:  0, Time:  9.69s) - All checks passed
[PASS] test_critical_path.gd            (Code:  0, Time:  5.08s) - All checks passed
[PASS] test_cursor_aiming.gd            (Code:  0, Time:  0.95s) - All checks passed
[PASS] test_effect_warmup.gd            (Code:  0, Time:  5.31s) - All checks passed
[PASS] test_encounters.gd               (Code:  0, Time: 28.35s) - All checks passed
[PASS] test_feel_combat.gd              (Code:  0, Time:  3.33s) - All checks passed
[PASS] test_feel_movement.gd            (Code:  0, Time:  8.63s) - All checks passed
[PASS] test_feel_traversal.gd           (Code:  0, Time:  3.62s) - All checks passed
[PASS] test_flamethrower_particles.gd   (Code:  0, Time:  0.91s) - All checks passed
[PASS] test_gameplay_fixes.gd           (Code:  0, Time:  2.94s) - All checks passed
[PASS] test_grinding.gd                 (Code:  0, Time: 12.33s) - All checks passed
[PASS] test_menu_flow.gd                (Code:  0, Time: 11.53s) - All checks passed
[PASS] test_occlusion.gd                (Code:  0, Time: 23.51s) - All checks passed
SUITE RETAINED exit=-1 (owned runner intentionally interrupted)
```

A further five rendered processes were checked before each launch and every two seconds for competing rendered Godot instances. No competing rendered instance was logged. A main-checkout headless suite was still running. Clocks nevertheless fell to 139 MHz at 77 C during later segments; these runs also fail the <25 ms gate. This is sustained hardware/driver variability, not a proven shader first-use event. A subsequent idle-time query reported SW/HW thermal slowdown Not Active; it is not a contemporaneous proof of the reason for each clock drop. No GPU/power/thermal settings were changed.

GPU-isolated repeat 1, exit 0:

```text
[FPS] physics avg=1.54 ms max=2.11 ms | process max=24.31 ms | frames over 2x avg: 0 of 1034 | active_objects=10 collision_pairs=79 islands=28
[FPS] frames=1034 avg=129.2 fps (7.74 ms)  1%low=99.4 fps (10.06 ms)  worst=10.3 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=9.11 ms physics=1.46 ms render_cpu=0.73 ms render_gpu=8.07 ms objects=322 primitives=236710 draw_calls=316
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Clock samples:

```text
1265 MHz, 72, P0
949 MHz, 72, P0
822 MHz, 72, P2
822 MHz, 72, P3
784 MHz, 72, P5
1657 MHz, 76, P0
1645 MHz, 77, P0
1569 MHz, 77, P0
1404 MHz, 77, P0
```

GPU-isolated repeat 2, exit 0:

```text
[FPS] SLOW FRAME t=3.51s 22.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.89s 21.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.43s 22.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.73s 22.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.01s 22.2 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.22s 22.0 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.42s 21.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.72s 21.8 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=5.82s 22.1 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.60s 21.9 ms (objects=318 draw_calls=311)
[FPS] SLOW FRAME t=6.84s 21.7 ms (objects=319 draw_calls=311)
[FPS] SLOW FRAME t=7.08s 21.8 ms (objects=319 draw_calls=311)
[FPS] SLOW FRAME t=7.38s 21.8 ms (objects=319 draw_calls=311)
[FPS] physics avg=1.50 ms max=1.76 ms | process max=33.93 ms | frames over 2x avg: 0 of 565 | active_objects=10 collision_pairs=94 islands=39
[FPS] frames=565 avg=70.6 fps (14.16 ms)  1%low=45.5 fps (21.99 ms)  worst=22.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=20.54 ms physics=1.53 ms render_cpu=0.55 ms render_gpu=19.70 ms objects=323 primitives=226463 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Clock samples:

```text
1493 MHz, 76, P0
1493 MHz, 76, P0
1493 MHz, 76, P0
1493 MHz, 76, P0
1645 MHz, 77, P0
1177 MHz, 77, P0
582 MHz, 77, P2
556 MHz, 77, P2
594 MHz, 77, P3
```

GPU-isolated repeat 3, exit 0:

```text
[FPS] SLOW FRAME t=0.51s 22.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.54s 36.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.61s 64.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.70s 87.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.82s 121.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=0.93s 114.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.05s 113.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.16s 118.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.27s 105.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.38s 109.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.48s 101.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.60s 117.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.71s 111.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.81s 103.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=1.92s 111.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.03s 103.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.13s 104.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.24s 105.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.34s 102.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.46s 120.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.58s 117.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.70s 116.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.81s 114.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=2.92s 107.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.03s 113.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.14s 109.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.25s 114.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.37s 112.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.47s 106.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.58s 109.0 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.69s 104.2 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.79s 106.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=3.90s 104.7 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.00s 105.1 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.12s 118.6 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.24s 120.8 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.36s 117.5 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.48s 116.9 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.58s 108.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.70s 115.3 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.80s 104.4 ms (objects=318 draw_calls=312)
[FPS] SLOW FRAME t=4.92s 115.8 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.03s 110.7 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.14s 107.7 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.25s 112.2 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.35s 104.9 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.46s 104.8 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.57s 106.5 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.67s 106.4 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.79s 114.4 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=5.91s 119.6 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.03s 120.9 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.14s 111.3 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.25s 110.0 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.36s 116.3 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.47s 106.9 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.59s 115.8 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.70s 116.1 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.81s 106.4 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=6.93s 119.0 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.04s 108.4 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.10s 58.6 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.14s 48.9 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.17s 28.9 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.20s 25.0 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.22s 22.2 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.24s 22.6 ms (objects=319 draw_calls=312)
[FPS] SLOW FRAME t=7.65s 22.4 ms (objects=323 draw_calls=316)
[FPS] SLOW FRAME t=7.68s 22.5 ms (objects=323 draw_calls=316)
[FPS] SLOW FRAME t=7.70s 23.2 ms (objects=323 draw_calls=316)
[FPS] SLOW FRAME t=7.72s 22.2 ms (objects=323 draw_calls=316)
[FPS] SLOW FRAME t=7.74s 22.3 ms (objects=323 draw_calls=316)
[FPS] physics avg=1.51 ms max=1.77 ms | process max=114.55 ms | frames over 2x avg: 57 of 161 | active_objects=10 collision_pairs=90 islands=34
[FPS] frames=161 avg=20.1 fps (49.74 ms)  1%low=8.3 fps (120.94 ms)  worst=121.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=101.86 ms physics=1.31 ms render_cpu=0.90 ms render_gpu=13.55 ms objects=323 primitives=226463 draw_calls=316
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Clock samples:

```text
1265 MHz, 77, P0
1265 MHz, 77, P0
1265 MHz, 77, P0
1265 MHz, 77, P0
1025 MHz, 77, P0
139 MHz, 77, P2
139 MHz, 77, P3
151 MHz, 77, P3
1265 MHz, 77, P0
```

GPU-isolated repeat 4, exit 0:

```text
[FPS] SLOW FRAME t=0.83s 23.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=1.14s 61.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.26s 122.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.38s 121.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.49s 107.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.60s 107.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.70s 102.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.81s 109.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=1.92s 111.2 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=2.02s 101.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=2.12s 101.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=2.23s 102.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=2.33s 105.6 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=2.44s 108.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.54s 104.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.66s 112.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.77s 112.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.88s 112.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=2.99s 109.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.10s 108.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.20s 102.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.30s 102.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.42s 113.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.53s 108.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.63s 105.8 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.73s 102.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.84s 104.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=3.94s 104.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.04s 101.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.15s 108.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.26s 108.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.37s 112.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.48s 109.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.60s 112.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.72s 126.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=4.81s 89.3 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=4.92s 104.7 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.02s 103.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.14s 120.8 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.26s 119.4 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.37s 107.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.48s 109.5 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.58s 104.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.68s 102.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.79s 109.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=5.90s 105.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.01s 109.0 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.12s 115.9 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.24s 112.1 ms (objects=310 draw_calls=303)
[FPS] SLOW FRAME t=6.35s 116.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.45s 102.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.56s 102.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.66s 102.4 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.77s 115.0 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=6.89s 115.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.00s 105.7 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.10s 100.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.20s 101.9 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.30s 100.6 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.40s 103.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.51s 107.1 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.61s 100.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.71s 103.2 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.82s 104.5 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=7.92s 101.3 ms (objects=306 draw_calls=299)
[FPS] SLOW FRAME t=8.02s 106.4 ms (objects=310 draw_calls=303)
[FPS] physics avg=3.04 ms max=11.74 ms | process max=113.65 ms | frames over 2x avg: 10 of 142 | active_objects=10 collision_pairs=83 islands=35
[FPS] frames=142 avg=17.7 fps (56.51 ms)  1%low=8.2 fps (122.48 ms)  worst=126.7 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=108.12 ms physics=2.61 ms render_cpu=0.73 ms render_gpu=104.98 ms objects=310 primitives=207301 draw_calls=303
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Clock samples:

```text
1265 MHz, 77, P0
961 MHz, 77, P0
INTERFERENCE: another rendered Godot process appeared
961 MHz, 77, P0
INTERFERENCE: another rendered Godot process appeared
961 MHz, 77, P0
961 MHz, 77, P0
822 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
```

GPU-isolated repeat 5, exit 0:

```text
[FPS] SLOW FRAME t=0.11s 105.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.21s 108.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.33s 114.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.44s 113.2 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.55s 107.9 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.65s 101.9 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.76s 106.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=0.87s 109.9 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=0.97s 105.3 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=1.07s 94.9 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=1.16s 95.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=1.26s 92.6 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=1.36s 105.2 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=1.44s 81.4 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=1.55s 102.9 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=1.66s 111.1 ms (objects=359 draw_calls=358)
[FPS] SLOW FRAME t=1.80s 143.4 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=1.90s 103.6 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.01s 110.0 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.15s 133.0 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.26s 117.5 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.37s 107.1 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.47s 97.2 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.57s 103.2 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.68s 109.0 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.79s 107.4 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.89s 101.9 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=2.99s 101.3 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=3.09s 103.1 ms (objects=355 draw_calls=354)
[FPS] SLOW FRAME t=3.20s 106.2 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.29s 91.1 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.38s 93.6 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.48s 93.3 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.57s 89.4 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.66s 93.4 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.76s 97.3 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.85s 91.4 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=3.94s 89.8 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=4.03s 91.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.12s 92.2 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.21s 91.0 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.32s 102.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.41s 91.6 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.50s 93.6 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.60s 95.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.69s 95.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.79s 98.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.89s 103.5 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=4.99s 99.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=5.09s 98.9 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=5.20s 111.9 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=5.30s 93.2 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=5.41s 109.7 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=5.51s 103.0 ms (objects=356 draw_calls=355)
[FPS] SLOW FRAME t=5.62s 107.2 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=5.71s 95.1 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=5.81s 96.7 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=5.91s 100.7 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=6.02s 107.4 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=6.11s 95.7 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=6.20s 91.1 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=6.30s 91.4 ms (objects=360 draw_calls=359)
[FPS] SLOW FRAME t=6.39s 96.5 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=6.49s 94.9 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=6.58s 89.3 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=6.67s 94.4 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=6.77s 94.2 ms (objects=357 draw_calls=356)
[FPS] SLOW FRAME t=6.86s 92.3 ms (objects=355 draw_calls=354)
[FPS] SLOW FRAME t=6.95s 93.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.05s 99.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.15s 95.0 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.24s 94.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.34s 95.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.43s 95.4 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.53s 98.1 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.63s 104.9 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.73s 99.7 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.83s 99.3 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=7.94s 101.8 ms (objects=353 draw_calls=352)
[FPS] SLOW FRAME t=8.04s 100.3 ms (objects=356 draw_calls=355)
[FPS] physics avg=4.44 ms max=11.35 ms | process max=130.93 ms | frames over 2x avg: 0 of 80 | active_objects=11 collision_pairs=85 islands=35
[FPS] frames=80 avg=10.0 fps (100.44 ms)  1%low=7.0 fps (143.42 ms)  worst=143.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=98.49 ms physics=1.56 ms render_cpu=0.70 ms render_gpu=98.85 ms objects=356 primitives=212444 draw_calls=355
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Clock samples:

```text
139 MHz, 77, P0
151 MHz, 77, P0
151 MHz, 77, P0
151 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
139 MHz, 77, P0
151 MHz, 77, P2
```

## Final cooled verification of committed code

After the final suite passed, waited for GPU temperature <=66 C before each rendered process. No other rendered Godot process was present at launch or detected during two-second inventory sampling. A separate headless suite was present during some early render checks; this was not a concurrent run of this worktree test suite, and the harness made no save/checkpoint/victory writes. Shader/bus/material code is the final version, with temporary instrumentation removed. Every process exited 0. All five worst frames are below 25 ms.

| Segment | Start temperature | Graphics-clock sample range | Temperature sample range | Worst frame |
|---|---:|---:|---:|---:|
| Spawn 1 | 56 C | 898–1670 MHz | 58–65 C | 11.7 ms |
| Spawn 2 | 65 C | 1657–1670 MHz | 64–70 C | 12.2 ms |
| Spawn 3 | 66 C | 949–1670 MHz | 67–72 C | 12.3 ms |
| Turrets | 66 C | 949–1670 MHz | 66–72 C | 12.4 ms |
| Queen | 66 C | 949–1670 MHz | 67–74 C | 11.8 ms |

Same scene/window/steps as above. Only cooldown and render-process inventory were added; no machine setting or project setting was modified. All FPS lines:

Final cooled run 1, exit 0:

```text
[FPS] physics avg=0.93 ms max=1.24 ms | process max=18.24 ms | frames over 2x avg: 0 of 1101 | active_objects=10 collision_pairs=84 islands=31
[FPS] frames=1101 avg=137.5 fps (7.27 ms)  1%low=107.4 fps (9.31 ms)  worst=11.7 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.61 ms physics=1.07 ms render_cpu=0.30 ms render_gpu=7.12 ms objects=298 primitives=216168 draw_calls=292
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Final cooled run 2, exit 0:

```text
[FPS] physics avg=0.85 ms max=1.00 ms | process max=17.96 ms | frames over 2x avg: 0 of 1082 | active_objects=10 collision_pairs=87 islands=32
[FPS] frames=1082 avg=135.2 fps (7.39 ms)  1%low=104.6 fps (9.56 ms)  worst=12.2 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.89 ms physics=0.94 ms render_cpu=0.33 ms render_gpu=6.77 ms objects=322 primitives=236710 draw_calls=316
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Final cooled run 3, exit 0:

```text
[FPS] physics avg=0.80 ms max=0.94 ms | process max=18.19 ms | frames over 2x avg: 0 of 1085 | active_objects=10 collision_pairs=85 islands=32
[FPS] frames=1085 avg=135.5 fps (7.38 ms)  1%low=103.0 fps (9.71 ms)  worst=12.3 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.68 ms physics=0.81 ms render_cpu=0.26 ms render_gpu=6.63 ms objects=323 primitives=226463 draw_calls=315
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Final cooled run 4, exit 0:

```text
[FPS] physics avg=1.81 ms max=4.59 ms | process max=18.14 ms | frames over 2x avg: 0 of 1077 | active_objects=10 collision_pairs=85 islands=36
[FPS] frames=1077 avg=134.6 fps (7.43 ms)  1%low=92.4 fps (10.82 ms)  worst=12.4 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.84 ms physics=0.96 ms render_cpu=0.32 ms render_gpu=7.03 ms objects=306 primitives=207293 draw_calls=299
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

Final cooled run 5, exit 0:

```text
[FPS] physics avg=2.42 ms max=4.73 ms | process max=16.78 ms | frames over 2x avg: 0 of 1161 | active_objects=11 collision_pairs=84 islands=31
[FPS] frames=1161 avg=145.0 fps (6.89 ms)  1%low=105.1 fps (9.51 ms)  worst=11.8 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=7.30 ms physics=4.53 ms render_cpu=0.30 ms render_gpu=6.70 ms objects=360 primitives=212956 draw_calls=359
[FPS] env ssao=true glow=true fog=true
[FPS] lights=10 shadow_casting=1
```

## Final full suite on final code

Before launch, checked that no other Godot process was present. The suite completed with all 22 PASS; test_slice_e2e passed without an isolated rerun. No competing suite was observed during this final run. Command:

```powershell
powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1
```

```text
=================================================================
 Y2K BIO-PUNK ARPG - TEST SUITE RUNNER
 Engine : C:\y2k-biopunk-rpg\.worktrees\vs11warm\Godot_v4.3-stable_win64.exe
 Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11warm
 Timeout: 120s per test
=================================================================
Discovered 22 test suite files.
[PASS] test_3d_player.gd                (Code:  0, Time:   5.1s) - All checks passed
[PASS] test_5_systems.gd                (Code:  0, Time: 10.16s) - Passed (contains SKIP section)
[PASS] test_candy_pickup.gd             (Code:  0, Time:  0.88s) - All checks passed
[PASS] test_character_sheet.gd          (Code:  0, Time:   9.4s) - All checks passed
[PASS] test_critical_path.gd            (Code:  0, Time:  4.52s) - All checks passed
[PASS] test_cursor_aiming.gd            (Code:  0, Time:  0.85s) - All checks passed
[PASS] test_effect_warmup.gd            (Code:  0, Time:  5.13s) - All checks passed
[PASS] test_encounters.gd               (Code:  0, Time: 27.19s) - All checks passed
[PASS] test_feel_combat.gd              (Code:  0, Time:  3.27s) - All checks passed
[PASS] test_feel_movement.gd            (Code:  0, Time:  7.99s) - All checks passed
[PASS] test_feel_traversal.gd           (Code:  0, Time:   2.1s) - All checks passed
[PASS] test_flamethrower_particles.gd   (Code:  0, Time:  0.44s) - All checks passed
[PASS] test_gameplay_fixes.gd           (Code:  0, Time:  1.41s) - All checks passed
[PASS] test_grinding.gd                 (Code:  0, Time:  4.19s) - All checks passed
[PASS] test_menu_flow.gd                (Code:  0, Time:  3.82s) - All checks passed
[PASS] test_occlusion.gd                (Code:  0, Time:  11.8s) - All checks passed
[PASS] test_onboarding.gd               (Code:  0, Time:  8.19s) - All checks passed
[PASS] test_presentation.gd             (Code:  0, Time:  1.96s) - All checks passed
[PASS] test_slice_e2e.gd                (Code:  0, Time: 21.92s) - All checks passed
[PASS] test_systems.gd                  (Code:  0, Time:  0.32s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.41s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  0.58s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status ExitCode Time   Details
----                           ------ -------- ----   -------
test_3d_player.gd              PASS          0 5.1s   All checks passed
test_5_systems.gd              PASS          0 10.16s Passed (contains SKIP section)
test_candy_pickup.gd           PASS          0 0.88s  All checks passed
test_character_sheet.gd        PASS          0 9.4s   All checks passed
test_critical_path.gd          PASS          0 4.52s  All checks passed
test_cursor_aiming.gd          PASS          0 0.85s  All checks passed
test_effect_warmup.gd          PASS          0 5.13s  All checks passed
test_encounters.gd             PASS          0 27.19s All checks passed
test_feel_combat.gd            PASS          0 3.27s  All checks passed
test_feel_movement.gd          PASS          0 7.99s  All checks passed
test_feel_traversal.gd         PASS          0 2.1s   All checks passed
test_flamethrower_particles.gd PASS          0 0.44s  All checks passed
test_gameplay_fixes.gd         PASS          0 1.41s  All checks passed
test_grinding.gd               PASS          0 4.19s  All checks passed
test_menu_flow.gd              PASS          0 3.82s  All checks passed
test_occlusion.gd              PASS          0 11.8s  All checks passed
test_onboarding.gd             PASS          0 8.19s  All checks passed
test_presentation.gd           PASS          0 1.96s  All checks passed
test_slice_e2e.gd              PASS          0 21.92s All checks passed
test_systems.gd                PASS          0 0.32s  All checks passed
test_tapes.gd                  PASS          0 0.41s  All checks passed
verify_camera_and_hud.gd       PASS          0 0.58s  All checks passed



Totals: 22 tests | 22 PASSED | 0 FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11warm\ops\runs\tests\20261008_142131.log

Test suite PASSED successfully.
SUITE FINAL exit=0
```
