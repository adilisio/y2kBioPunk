# VS11-OCC - General player-occlusion fading

Worktree: `C:\y2k-biopunk-rpg\.worktrees\vs11occ`; branch: `vs11-occlusion`.

## Design as built

The builder creates `OcclusionFader` at runtime before constructing geometry. Its old pillar-only `_process` and all per-frame material edits are removed. No scene, native source, HUD, enemy, or project-setting changes are required.

The registry contains **22 visuals** in the real mall: eight pillars, north/west perimeter walls, five storefront walls, the mezzanine deck and both guard walls, three kiosk meshes, and the fountain mesh. Boxes/cylinders taller than 1.2 m register on creation; `DeckFloor` and `DeckRail_*` explicitly register despite being shorter. Floors, ramps, curbs, planters, grind rails, and their supports stay excluded. Missing prop assets still use the registered CSG fallback.

Each entry stores a visual and a static world AABB. Primitive bounds come from their dimensions; prop bounds use `EnemyModel.bounds(root)` in parent space and are shared by every mesh in that prop, keeping multi-mesh props coherent. Bounds are transformed to world space once after construction. Offline editor/test geometry builds do not create a fader. The real mall always rebuilds inside the SceneTree in `_ready`, so every runtime build receives the complete registry.

Each physics tick tests the camera-to-player segment, ending 1 m above the player, against every valid registered AABB. Player/camera references are cached and refreshed only when invalid or detached. No per-tick physics queries or `get_nodes_in_group` calls occur. Godot 4.3's `AABB.intersects_segment` returns a hit Vector3 or null; the implementation explicitly tests against null.

Instance transparency approaches 0.7 at 8/s while intersecting and 0.0 at 5/s after a 0.15 s hold. Exponential weights use delta, so tick-rate changes preserve the response. Values within 0.001 of the target snap to that target, allowing exact opacity after the tail. Multiple intersecting entries fade independently. Materials are never modified.

On the first process frame after construction, one CSG box, one CSG cylinder, and one prop mesh receive instance transparency 0.01. The next process frame restores 0.0 and disables idle processing. Physics fading waits until warm-up completes. Headless tests verify the state transitions; they cannot prove shader compilation or visual quality.

`_exit_tree` restores surviving instances and clears registry/warm-up arrays. Builder clearing/rebuilding also explicitly restores and detaches the old fader before retiring geometry. Tests cover freeing the fader with visuals still alive, rebuilding, and freeing the entire mall.

## Adjustments to the brief

- Fader creation is limited to a runtime builder inside the SceneTree. The existing presentation test constructs geometry offline and exits without freeing it. Its first run with an offline fader passed assertions but crashed at shutdown (exit -1073741819). A diagnostic using the HEAD builder exited 0 with the same existing RID/resource leak warnings. Limiting the new runtime component to live scene builds made the unchanged presentation test exit 0; its pre-existing leaks are outside this packet's ownership.

- With camera forward defined as `-camera.global_basis.z`, the player must be placed **along** horizontal forward from the pillar (northwest), rather than subtracting it. The opposite placement puts the pillar behind the player. The real camera test uses pillar position plus normalized horizontal forward times 3 m; measured target transparency is 0.7000 and the unrelated pillar remains 0.0000.
- The builder now resolves its direct `Player` child before its existing sibling/current-scene fallbacks. The previous lookup missed the player when a mall was added before `current_scene` was assigned, leaving the group empty. This was observed in the first integration run (zero AABB tests); the corrected lookup permits the real mall test without manually inserting a player group.
- Director position checks are a separate, uncommitted diagnostic under `ops/runs/`, keeping the discovered regression suite below the packet's 20 s budget. An initial combined diagnostic/regression run hit the 20 s watchdog; the standalone diagnostic subsequently exited 0 with all six positions passing.

## Cost

Measured registry: **22 AABB tests per physics tick** (1,320/s at 60 Hz), one loop over 22 entries, and two exponential calculations per tick. The simultaneous-occlusion test temporarily adds two entries (24 tests/tick). Bounds and geometry traversal happen only at build/registration time.

No new arrays, dictionaries, registry entries, resources, or scene/group traversals are allocated in steady-state ticks. The preallocated entry and warm-up arrays are reused; hit Vector3/Variant and scalar/vector temporaries are engine value types. This is a source-level allocation assessment, not a heap-profiler measurement. No CPU/GPU timing or rendered performance claim is made.

## Director teleport checks

Run with the rendered shot harness after merge. Allow at least 1.2 s after each teleport for camera follow and fade recovery; these positions were verified headlessly with player physics enabled and encounter processing disabled. North guard-wall positioning settles slightly outward to z approximately -14.70009 through normal collision.

| Expected | Harness step | Intended visual |
|---|---|---|
| Fade | `tp:8.879:0.1:-9.121` | `Pillar_06` |
| Fade | `tp:-18.5:0.1:-14.65` | `DeckRail_North` |
| Fade | `tp:16:0.1:-15.2` | `Store_NE_FrontWall` |
| Fade | `tp:5.5:0.1:-17.2` | `Kiosk_NeonJulius` mesh |
| Opaque | `tp:0:0.1:18` | All registered visuals |
| Opaque | `tp:20:0.1:18` | All registered visuals |

## Verification

Initial full run: `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`, exit **1**. Presentation printed PASS but crashed on shutdown; e2e failed only its known step c checkpoint timing assertion. Log: `ops/runs/tests/20261008_133418.log`.

```text
[FAIL] test_presentation.gd             (Code: -1073741819, Time:  4.06s) - Process exited with code -1073741819
[FAIL] test_slice_e2e.gd                (Code:  1, Time: 22.42s) - Assertion checks failed (Exit 1)
[PASS] test_systems.gd                  (Code:  0, Time:  0.32s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.41s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  0.58s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status    ExitCode Time   Details
----                           ------    -------- ----   -------
test_3d_player.gd              PASS             0 5.02s  All checks passed
test_5_systems.gd              PASS             0 10.41s Passed (contains SKIP section)
test_candy_pickup.gd           PASS             0 1.47s  All checks passed
test_critical_path.gd          PASS             0 9.73s  All checks passed
test_cursor_aiming.gd          PASS             0 1.19s  All checks passed
test_encounters.gd             PASS             0 35.15s All checks passed
test_feel_combat.gd            PASS             0 3.32s  All checks passed
test_feel_movement.gd          PASS             0 8.7s   All checks passed
test_feel_traversal.gd         PASS             0 3s     All checks passed
test_flamethrower_particles.gd PASS             0 0.44s  All checks passed
test_gameplay_fixes.gd         PASS             0 1.42s  All checks passed
test_grinding.gd               PASS             0 4.76s  All checks passed
test_menu_flow.gd              PASS             0 4.44s  All checks passed
test_occlusion.gd              PASS             0 12s    All checks passed
test_onboarding.gd             PASS             0 8.28s  All checks passed
test_presentation.gd           FAIL   -1073741819 4.06s  Process exited with code -1073741819
test_slice_e2e.gd              FAIL             1 22.42s Assertion checks failed (Exit 1)
test_systems.gd                PASS             0 0.32s  All checks passed
test_tapes.gd                  PASS             0 0.41s  All checks passed
verify_camera_and_hud.gd       PASS             0 0.58s  All checks passed



Totals: 20 tests | 18 PASSED | 2 FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11occ\ops\runs\tests\20261008_133418.log

Test suite FAILED with 2 failure(s).
```

### Isolated e2e retry (before final full run)

`.\Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd` - exit **1**. Godot was launched with PowerShell `Start-Process`, output redirected, and its cached process handle used to obtain the exit code.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
FAIL: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 21.88s < 60s
RESULT: FAIL (1 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

### HEAD-builder comparison

`.\Godot_v4.3-stable_win64.exe --headless --path . -s ops/runs/occlusion-baseline-e2e.gd` - exit **0**. Godot was launched with PowerShell `Start-Process`, output redirected, and its cached process handle used to obtain the exit code.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 22.41s < 60s
RESULT: PASS (0 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

### Director-position diagnostic

`.\Godot_v4.3-stable_win64.exe --headless --path . -s ops/runs/occlusion-probes.gd` - exit **0**. Godot was launched with PowerShell `Start-Process`, output redirected, and its cached process handle used to obtain the exit code.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PROBE tp:8.87899971008301:0.10000000149012:-9.12100028991699 settled=(8.879, 0.000602, -9.121) faded=["StructuralPillars/Pillar_06"]
PROBE tp:-18.5:0.10000000149012:-14.6499996185303 settled=(-18.5, 0.000098, -14.70009) faded=["MezzanineTerrace/DeckRail_North"]
PROBE tp:16:0.10000000149012:-15.1999998092651 settled=(16, -0.000115, -15.2) faded=["StorefrontAlcoves/Store_NE_FrontWall"]
PROBE tp:5.5:0.10000000149012:-17.2000007629395 settled=(5.5, 0.000098, -17.2) faded=["DerelictKiosks/Kiosk_NeonJulius/mall_kiosk/Mesh"]
PROBE tp:0:0.10000000149012:18 settled=(0, 0.000098, 18) faded=[]
PROBE tp:20:0.10000000149012:18 settled=(20, 0.000098, 18) faded=[]
KIOSK bounds=[P: (3.708105, 0, -16.15038), S: (3.58379, 2.8, 2.300766)]
RESULT: PASS
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

### Presentation retry after runtime-only creation

`.\Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_presentation.gd` - exit **0**. Godot was launched with PowerShell `Start-Process`, output redirected, and its cached process handle used to obtain the exit code.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

--- Running WP-3 Presentation Tests ---
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
Mall children: [&"WorldEnvironment", &"DirectionalLight3D", &"Player", &"HUD", &"BossEncounterTrigger", &"BioCheckpoint", &"FruitCandyPickup_01", &"FruitCandyPickup_02", &"LevelGeometry", &"Enemies"]
LevelGeo children: [&"MainFloor", &"Wall_North", &"Wall_South", &"Wall_West", &"Wall_East", &"SunkenAtriumBasin", &"MezzanineTerrace", &"StructuralPillars", &"DerelictKiosks", &"EmergencyLights", &"PlantersAndCurbs", &"StorefrontAlcoves", &"GrindRails"]
Rail node children: [RailMesh:<CSGPolygon3D#41087403906>, PathFollow3D:<PathFollow3D#41104181123>, GrindArea:<Area3D#41120958340>, SupportPost_00:<CSGCylinder3D#41439725463>, SupportPost_01:<CSGCylinder3D#41456502680>, SupportPost_02:<CSGCylinder3D#41473279897>, SupportPost_03:<CSGCylinder3D#41490057114>, SupportPost_04:<CSGCylinder3D#41506834331>]
RESULT: PASS
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: 47 RID allocations of type 'P11GodotBody3D' were leaked at exit.
ERROR: 9 RID allocations of type 'P11GodotArea3D' were leaked at exit.
ERROR: 54 RID allocations of type 'P12GodotShape3D' were leaked at exit.
WARNING: 1 RID of type "Canvas" was leaked.
     at: _free_rids (servers/rendering/renderer_canvas_cull.cpp:2483)
WARNING: 68 RIDs of type "CanvasItem" were leaked.
     at: _free_rids (servers/rendering/renderer_canvas_cull.cpp:2485)
ERROR: Pages in use exist at exit in PagedAllocator: N20RasterizerSceneDummy21GeometryInstanceDummyE
   at: ~PagedAllocator (./core/templates/paged_allocator.h:170)
ERROR: 1 RID allocations of type 'N26RendererEnvironmentStorage11EnvironmentE' were leaked at exit.
ERROR: 16 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.
ERROR: 53 RID allocations of type 'N13RendererDummy11MeshStorage9DummyMeshE' were leaked at exit.
ERROR: 7 RID allocations of type 'N13RendererDummy15MaterialStorage11DummyShaderE' were leaked at exit.
ERROR: 71 RID allocations of type 'N17RendererSceneCull8InstanceE' were leaked at exit.
ERROR: 1 RID allocations of type 'N17RendererSceneCull6CameraE' were leaked at exit.
ERROR: 36 RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit.
ERROR: 1 RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit.
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
     at: cleanup (core/object/object.cpp:2284)
ERROR: 69 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:604)
```

### Final full runner after runtime-only creation

`powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` - exit **1**. All suites except the known step c checkpoint assertion pass, including presentation and the 11.9 s occlusion suite. The runner prints an empty failed-count field for a single failure (PowerShell scalar `.Count` formatting); its last line and exit code correctly report one failure.

```text
[FAIL] test_slice_e2e.gd                (Code:  1, Time: 22.12s) - Assertion checks failed (Exit 1)
[PASS] test_systems.gd                  (Code:  0, Time:  0.32s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.41s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  0.57s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status ExitCode Time   Details
----                           ------ -------- ----   -------
test_3d_player.gd              PASS          0 4.76s  All checks passed
test_5_systems.gd              PASS          0 5.03s  Passed (contains SKIP section)
test_candy_pickup.gd           PASS          0 0.76s  All checks passed
test_critical_path.gd          PASS          0 4.42s  All checks passed
test_cursor_aiming.gd          PASS          0 0.95s  All checks passed
test_encounters.gd             PASS          0 27.42s All checks passed
test_feel_combat.gd            PASS          0 3.24s  All checks passed
test_feel_movement.gd          PASS          0 7.95s  All checks passed
test_feel_traversal.gd         PASS          0 2.11s  All checks passed
test_flamethrower_particles.gd PASS          0 0.45s  All checks passed
test_gameplay_fixes.gd         PASS          0 1.41s  All checks passed
test_grinding.gd               PASS          0 4.29s  All checks passed
test_menu_flow.gd              PASS          0 3.91s  All checks passed
test_occlusion.gd              PASS          0 11.9s  All checks passed
test_onboarding.gd             PASS          0 8.38s  All checks passed
test_presentation.gd           PASS          0 2.14s  All checks passed
test_slice_e2e.gd              FAIL          1 22.12s Assertion checks failed (Exit 1)
test_systems.gd                PASS          0 0.32s  All checks passed
test_tapes.gd                  PASS          0 0.41s  All checks passed
verify_camera_and_hud.gd       PASS          0 0.57s  All checks passed



Totals: 20 tests | 19 PASSED |  FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11occ\ops\runs\tests\20261008_133950.log

Test suite FAILED with 1 failure(s).
```

### Final occlusion suite output

```text
--- START: tests/test_occlusion.gd ---
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_occlusion ===
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
REGISTRY visuals=22 kiosk_meshes=3 warm_kinds=3
PILLAR faded=0.7000 unrelated=0.0000 tests/tick=22
PILLAR restored=0.0034
SIMULTANEOUS a=0.7000 b=0.7000
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
CLEANUP fader_freed=true
RESULT: PASS

ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)

--- END: tests/test_occlusion.gd (ExitCode: 0, Time: 11.9s) ---
```

### Additional isolated e2e retry 2

`.\Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd` - exit **1**. Checkpoint step c passed, but Continue visibility at step g failed.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
FAIL: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 22.24s < 60s
RESULT: FAIL (1 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

### Additional isolated e2e retry 3

`.\Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd` - exit **1**. Checkpoint step c failed; all remaining assertions passed. The engine additionally reported one leaked resource at shutdown.

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
FAIL: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 21.65s < 60s
RESULT: FAIL (1 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
     at: cleanup (core/object/object.cpp:2284)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:604)
```


## STOP items / limitations

- **Verification STOP: the 20/20 all-green runner gate is not achieved.** The final full run is 19/20, exit 1. The brief identifies checkpoint step c as a known timing flake; the required isolated retry also failed c. Additional isolated runs showed c passing with a g Continue-visibility failure, then c failing with g passing. The HEAD-builder comparison passed. These results show variable e2e outcomes, but do not establish the root cause or rule out every interaction. Stabilizing the e2e test/menu/save timing is outside the packet's file ownership; no unrelated source or test was changed to force a pass. Director review is required before claiming a fully green merge gate.
- Implementation and all scoped tests are complete; no uncommitted packet work remains after the required commit.
- Director rendered screenshots/playtest remain necessary to assess the fade and first-use shader behavior. No editor or windowed engine was launched by the agent.
- The headless dummy renderer emits `ERROR: Parameter "m" is null` from `mesh_get_surface_count`; the same diagnostic appeared with the original HEAD builder, and existing presentation RID/resource leak warnings persist; the actual output is pasted above. No claim of warning-free rendering is made.
- The pre-existing untracked `bin/libbiopunk.windows.template_release.x86_64.dll` is excluded from the commit, as are all `ops/runs/` artifacts and import files.
