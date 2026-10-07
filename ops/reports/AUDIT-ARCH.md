# Architecture and correctness audit

2026-10-07 · Godot 4.3 · 15–30 minute vertical slice

Read AGENTS.md, ops/CONTEXT.md, the brief, all scoped native sources/headers, scripts, scene structures/resources, configuration and tests; followed live references into root files. No code edits, build, editor, windowed game or commit. This report is the only file written by this audit. Pre-existing `.gitignore` changes and other ops work were preserved.

The gameplay loop and combat contracts are the blockers; the language split itself is workable. Findings distinguish source-derived consequences from observed test results. Headless startup is not a playthrough.

## Top 10 findings, ranked by player impact

Critical prevents the intended slice; High breaks a core mechanic; Medium harms supported interaction. Cost: S localized change, M several components/integration checks, L substantial redesign. Risk concerns the proposed change.

### 1. Critical — Launch does not reach the mall

Evidence: `project.godot:15` launches `scenes/intro.tscn`. Neither it nor `scenes/main_menu.tscn:3` overrides destination properties. Native defaults are root `main_menu.tscn` (`src/intro_controller.hpp:27`) and root `main.tscn` (`src/menu_controller.hpp:19`); existing root files win (`src/menu_controller.cpp:49`). Root `main.tscn:22` is a Node2D prototype with the current CharacterBody3D player, Camera2D, 2D enemy and NPC (`:45`, `:52`, `:62`, `:69`), without a 3D floor/camera. A direct headless load confirmed those legacy classes instantiate. Even canonical fallback `scenes/main.tscn:608` is just a floor/player/HUD/candy; the boss/checkpoint live in the unreachable mall (`scenes/FloodedMall_Greybox.tscn:3629`). CONTEXT's canonical-main route claim is narrower than the source evidence; shipped DLL destination properties were not independently queried.

Fix: explicitly wire canonical intro/menu destinations and New Game to the mall; remove legacy fallback routes after a menu-to-mall check. **Cost S; risk low**, coupled to fresh/continue intent in finding 5.

### 2. High — Evade interruption can strand invincibility

Evidence: evade sets `is_invincible` (`src/player_controller.cpp:2302`); only the EVADING branch clears it (`:560`, `:574`). `attack()` accepts EVADING and overwrites state with ATTACKING (`:1128`, `:1133`), and render processing dispatches attack independently (`:968`). `try_start_grind()` also accepts evading/attacking/locked players (`:2011`, `:2090`). Damage rejects the stranded flag (`:1746`). Source-derived reproduction: evade, then LMB before the timer ends; normal evade cleanup is bypassed. Render attack can also bypass grind dismount/slam handling. Not reproduced through live input.

Fix: one native transition entry/exit path; reject or deliberately clean up attack/evade/grind cancellation, flags, timers and end signals. Dispatch input once in physics. **Cost M; risk medium** because cancellation timing affects feel.

### 3. High — Death replaces the checkpoint; restored health can be incomplete

Evidence: checkpoint saves a real spawn (`scripts/checkpoint.gd:63`), but HUD death saves without spawn (`scripts/hud.gd:491`), replacing it with ZERO via default argument (`scripts/save_manager.gd:22`, `:42`). Restore ignores near-origin positions (`:136`); native death reloads the whole scene (`src/player_controller.cpp:348`). Native READY fills the initial health pool (`:215`); later restoration changes VIT/tape (`scripts/save_manager.gd:125`, `:131`) without healing. Derived refresh only clamps HP (`src/player_controller.cpp:225`). Successful death save therefore discards checkpoint position; upgraded respawn can be 100/230 HP. Disk reproduction was blocked by storage permissions.

Fix: session/SaveManager preserves checkpoint identity/position during progression saves; remove saving from HUD, restore stats/tape before assigning intended respawn HP, allow explicit origin checkpoints, and define scene/world reset policy. **Cost M; risk medium**, including save migration.

### 4. High — Live mall kills award no XP

Evidence: live death handlers print/free or animate/free with no reward (`scripts/neon_cicada.gd:256`, `scripts/sludge_roach.gd:298`, `scripts/corrupted_kiosk_turret.gd:316`, `scripts/dial_up_queen.gd:356`). Mall loads root `neon_cicada.tscn` (`scripts/mall_greybox_builder.gd:228`), whose root script also has no XP (`neon_cicada.gd:256`). Only legacy C++ enemy awards XP (`src/mutated_bug_enemy.cpp:115`). `tests/test_systems.gd:18` grants XP manually. Mall leveling/reward allocation cannot work despite that passing test.

Fix: one exactly-once death/reward notification for ordinary enemies and boss, with damage credit delivered to native `gain_xp`. **Cost S; risk low–medium**, especially duplicate hurtbox/body hits and damage over time.

### 5. High — New Game restores old saves; Load Game is a no-op

Evidence: Load Game only prints (`src/menu_controller.cpp:61`); New Game only changes scene (`:45`). Every HUD READY applies any existing save (`scripts/hud.gd:273`). Three headless gameplay-scene loads restored a pre-existing level-4 Metal save. Save data has no scene identity (`scripts/save_manager.gd:27`), truncates the sole file directly (`:50`), and validates JSON/root dictionary but not schema/version/types/ranges (`:87`, `:110`). Players cannot choose fresh versus continue; interrupted writes can lose continuation.

Fix: explicit session-owned New/Continue intent; HUD displays only. Validate a small versioned schema and replace the save only after a successful temporary write. Define fresh-run behavior without silently deleting existing saves; disable unfinished menu items. **Cost M; risk medium**, persistence compatibility.

### 6. High — Bat queries stale overlaps; flame/slam ignore cover and vertical separation

Evidence: bat moves its sensor then immediately reads cached overlaps (`src/player_controller.cpp:1186`, `:1189`). It collects world bodies/non-damageable parents (`:1192`, `:1203`), running cone fallback only if that unfiltered list is empty (`:1214`). Sensor includes world layer (`:195`) and radius 2.2 (`:206`), so floor overlap can suppress fallback. Overlap hits do not share fallback reach/cone rules (`:1250`, `:1285`). Flame/slam flatten vertical distance and have no cover query (`:2595`, `:2443`). Consequence: fast aim changes can hit old direction/miss new targets; flame/slam can hit through walls or across mezzanine height. Source-derived, not measured live-physics outcomes.

Fix: current-transform shape query with enemy/hurtbox mask; resolve/filter/deduplicate damage receivers before fallback and enforce intentional shared reach/height/cover rules. **Cost M; risk medium**, combat balance changes.

### 7. High — Knockback units conflict with the all-enemies-clear gate

Evidence: native slam passes direction ×12 (`src/player_controller.cpp:2478`), flame ×2 (`:2602`), disk ×8.5 (`scripts/disk_projectile.gd:90`). Cicada/roach multiply supplied vectors again by 7.5/10 without normalization (`scripts/neon_cicada.gd:248`, `scripts/sludge_roach.gd:269`): approximately 90/120 m/s slam knockback. Boss gate counts all living scene-group enemies (`scripts/boss_encounter_trigger.gd:50`), with no encounter bounds/off-level cleanup. Inaccessible or indefinitely falling survivors could block the boss; escape was not reproduced.

Fix: define unit direction plus receiver speed, or explicit velocity impulse, consistently at all callers. Bound encounter membership and recover/remove escaped enemies with a deliberate reward policy. **Cost M; risk medium**, knockback feel and completion semantics.

### 8. High — Boss defeat has no slice completion flow

Evidence: Queen emits defeat and disappears (`scripts/dial_up_queen.gd:356`); HUD displays a message then hides it after four seconds (`scripts/hud.gd:177`). Nothing records victory, opens an exit, returns to menu or stops summoned siblings (`scripts/dial_up_queen.gd:265`). Minions can continue fighting after the apparent win and death restarts the ordinary scene.

Fix: small GDScript encounter/session owner settles remaining threats, records completion and presents exit/replay. **Cost S–M; risk low–medium**, intended terminal/save behavior.

### 9. Medium — Disks collide with rail sensors and risk tunneling

Evidence: disk moves by render-frame position increments at 24 m/s (`scripts/disk_projectile.gd:35`, `src/player_controller.cpp:2649`), without swept collision. Mask 7 (`scripts/disk_projectile.gd:20`) includes rail Area layer 4, also the enemy bit (`scenes/FloodedMall_Greybox.tscn:3499`, `:3590`). Area hits resolve parents and destroy the disk even without damage methods (`scripts/disk_projectile.gd:79`, `:86`). Rail detection volumes can swallow shots; at 30 FPS a step is 0.8 m, so thin-target tunneling is plausible but unmeasured.

Fix: separate rail/damage layers, ignore nonblocking sensors, simulate in physics and sweep traveled distance. **Cost M; risk medium**, coordinated layer changes.

### 10. Medium — Character-sheet clicks leak into combat; mappings resist rebinding

Evidence: sheet toggling changes only visibility (`scripts/hud.gd:532`); player globally polls LMB/movement (`src/player_controller.cpp:973`, `:310`), bypassing GUI consumption. Tape uses raw T (`:891`) despite `switch_tape` mapping (`project.godot:68`); NPC uses raw E (`src/stranded_soldier_npc.cpp:78`). Allocation clicks can swing; player stays exposed/moving during the modal. Remapping does not consistently remove original physical keys.

Fix: choose explicit modal pause/lock policy, gate gameplay input and dispatch action mappings once; keep only documented aliases. **Cost S–M; risk low–medium**, controller input/pause modes.

## Boundary inventory

Repeated call sites are grouped by complete method/signal family. Generic engine APIs are excluded; Queen velocity override is included because it changes native simulation state. Bound method definitions are in `src/player_controller.cpp:2674` onward.

| Caller → callee | Mechanism / methods or signals | Evidence / assessment |
|---|---|---|
| HUD → player | `call`: `spend_stat_point`, `get_level`, `get_current_xp`, `get_xp_to_level`, `get_unspent_stat_points` | `scripts/hud.gd:497`, `:547`, `:556`, `:688`; valid bound APIs. |
| HUD → player | `call`: base/effective getters for strength/agility/vitality/vibe, `get_movement_speed`, `get_max_health` | `scripts/hud.gd:573`; copied bat formula at `:575` should use native `get_effective_bat_damage`. |
| HUD → player | `call/get`: `is_dead`, `get_secondary_weapon_name`, `current_health`, `max_health`, `current_tape`, `get_effective_vibe`, `set_movement_locked(false)` | `scripts/hud.gd:626`, `:645`, `:658`, `:667`, `:699`, `:714`, `:734`; sheet never locks. |
| SaveManager → player | Progression/base-stat getters and `current_tape`; `set_level`, `set_current_xp`, `set_xp_to_level`, `set_unspent_stat_points`, `set_strength`, `set_agility`, `set_vitality`, `set_vibe`, `switch_tape` via `call/get` | `scripts/save_manager.gd:32`, `:112`; sets global_position at `:137`. No health/secondary/skates/world-state restore. |
| Candy → player | Direct bound `get_current_health`, `get_max_health`, `heal`, `play_sfx("yum")`; property fallback | `scripts/health_candy_pickup.gd:127`, `:140`, `:151`; direct-callback healing passes. |
| Roach / mortar / Queen → player | `has_method` + `call("take_damage", amount)` | `scripts/sludge_roach.gd:190`, `scripts/turret_mortar.gd:61`, `scripts/dial_up_queen.gd:222`; correctly matches one float argument. |
| Queen → player body | Engine `set_velocity` | `scripts/dial_up_queen.gd:302`; directly overrides player velocity outside its impulse/state contract. |
| Mall builder → player | `has_method` + `call("try_start_grind", Path3D)` from body_entered | `scripts/mall_greybox_builder.gd:429`; duplicates native sensor/polling detection (`src/player_controller.cpp:163`, `:712`). |
| Boss trigger → player identity | `has_method("switch_tape" / "get_effective_strength")`, no invocation | `scripts/boss_encounter_trigger.gd:36`; name/group/type fallbacks. |
| Player → scripted enemies | `has_method` + two-argument `call("take_damage", int(amount), Vector3)` for bat/slam/flame/disk fallback | `src/player_controller.cpp:1286`, `:2478`, `:2602`, `:2662`; live signatures accept this; knockback units conflict. Dedup at `:1271`. |
| Player → scripted disk | Load/attach script then `call("setup_projectile", direction, 24, damage, shooter)` | `src/player_controller.cpp:2635`, `:2649`; root-script/hitscan fallbacks mask wiring defects. |
| Disk → native damageable, potentially | Generic two-argument `call("take_damage", int(damage), direction*8.5)` | `scripts/disk_projectile.gd:90`; shooter excluded and live targets are scripted. Another native player would fail one-argument signature. Repeated-predicate one-argument fallback `:94` is unreachable. |
| Player → HUD | `health_changed(float,float)`, `stats_changed()`, `tape_switched(string,string)`, `skates_toggled(bool)`, `xp_changed(int,int,int)`, `leveled_up(int,int)`, `stat_point_spent(string,int)`, `secondary_weapon_switched(int,string)`, `player_died()` | Registered `src/player_controller.cpp:2868`; connected `scripts/hud.gd:276`; signatures match. Restore occurs before connections, followed by explicit refresh. |
| Player → no shipped GDScript listener | `attack_executed(float)`, `adrenaline_changed(float,float)`, `grind_started(Path3D,float)`, `grind_ended(Vector3)`, `grind_slam_executed(Vector3,Vector3,float)`, `evade_started(Vector3,float)`, `evade_ended()`, `secondary_fired(int,Vector3,Vector3,float)` | Registered `src/player_controller.cpp:2867`, `:2875`; unused does not mean non-emitting. Cursor test's secondary signal spy is never reached. |
| Soldier → HUD; HUD → soldier | `dialogue_opened(Object)`; `get_npc_name`, `get_already_persuaded`, `evaluate_vibe_check(player)` | `src/stranded_soldier_npc.cpp:100`; `scripts/hud.gd:298`, `:605`, `:611`, `:642`; absent in canonical scenes, present in root main. Soldier→player lock/vibe calls are C++→C++. |
| Intro/menu ↔ scenes | Engine video `finished`, button `pressed` → bound native callbacks | `scenes/intro.tscn:50`, `scenes/main_menu.tscn:138`; native fallback connections guard duplicates. No GDScript calls in these controllers. |
| Tests → native constructors | ClassDB instantiates PlayerController, StrandedSoldierNPC | `tests/test_systems.gd:7`, `:44`; pure NPC check, not proximity integration. |
| Tests → native methods | Progression/tape/stat/health/audio APIs above; `get_current_tape`, `get_gravity`, `get_skate_speed`, `get_is_attacking`, `get_is_skating`, `get_is_equipped_skates`, `set_is_skating`, `get/set_facing_direction`, `get_movement_locked`, `get_visuals`, `get_animation_player`, `get_flame_particles`, `get_cursor_world_position`, `orient_towards_point`, `orient_towards_cursor`, `set_secondary_weapon`, `fire_disk_launcher`, `attack`, `simulate_physics`, `try_start_grind`, `is_grinding`, `get_movement_state`, `get/set_current_adrenaline`, `get_max_adrenaline`, `set_max_health`, `set_current_health` | Direct and `call` forms across `tests/test_systems.gd:12`, `test_tapes.gd:11`, `test_3d_player.gd:38`, `test_cursor_aiming.gd:33`, `test_grinding.gd:16`, `test_candy_pickup.gd:41`, `test_gameplay_fixes.gd:44`. Inventory includes unreachable later assertions. Unbound `_ready`/`_physics_process` attempts at `test_3d_player.gd:37`, `test_cursor_aiming.gd:29` fail. |

GDScript-only seams: checkpoint→SaveManager.save_player_data (`checkpoint.gd:63`); HUD→SaveManager.has_save_data/apply_save_data_to_player/save_player_data (`hud.gd:273`, `:491`); trigger→HUD.setup_boss_bar (`boss_encounter_trigger.gd:146`); turret→mortar.setup (`corrupted_kiosk_turret.gd:219`). Boss health/defeat→HUD connects at `hud.gd:152`, `:155`. Boss phase_changed emits (`dial_up_queen.gd:283`) without a consumer, while health emission precedes phase advancement (`:322`, `:326`), leaving the label stale until another damage event. SaveManager game_saved/game_loaded (`save_manager.gd:8`) have no shipped consumers; ordinary enemies have no progression death/reward signal.

AGENTS.md's player-damage example `(amount, knockback)` conflicts with native `take_damage(float)`. Current live attacks correctly use one argument; document distinct contracts or deliberately add an optional native knockback parameter. Do not label the existing one-argument enemy attacks broken.

## Wiring, cruft and bounded issues

- Legacy MutatedBugEnemy is CharacterBody2D (`src/mutated_bug_enemy.hpp:13`), soldier is Area2D (`src/stranded_soldier_npc.hpp:15`); both registered (`src/register_types.cpp:22`) and **present in root main**, contrary to CONTEXT's blanket unused-scene claim. They have no canonical 3D placement. After fixing launch, cut those classes/obsolete dialogue UI for this slice unless that encounter is explicitly required; a 3D NPC port is separate work.
- Root `neon_cicada.tscn:3` is a unique live dependency of the mall. Repoint/move it before deleting root files. Root cicada/roach/turret scripts and main_menu are byte-identical to canonical copies; root disk/mortar/Queen scripts and Queen/player/intro/main scenes differ. Default trigger constructs a scripted body (`scripts/boss_encounter_trigger.gd:124`), not the canonical Queen scene.
- Player/HUD are duplicated in main and mall (`scenes/main.tscn:79`, `:146`; `scenes/FloodedMall_Greybox.tscn:2309`, `:2766`). Mall embeds mesh/skin data, two skeletons and animation players (`:84`, `:203`, `:2350`, `:2556`, `:2754`, `:2761`). Reusable `scenes/player.tscn` changes need not reach gameplay. Consolidate player/HUD scenes after identifying required mall animation overrides; preserve Skate_Grind.
- Hidden Polygon2D BatSwingVisual remains in 3D player (`scenes/player.tscn:63`). Optional StatsLabel/EquipLabel/SheetPromptLabel HUD lookups have no canonical nodes; soldier lookup (`scripts/hud.gd:295`) is absent there. Null fallbacks silently hide stale UI features. Required scene contracts should fail visibly.
- Player layer is 1|2 (`src/player_controller.cpp:53`), default body mask 1; enemies layer 4/mask 3 and aggro mask 2; mortar/candy mask 3, checkpoint 2, trigger 7. AttackSensor includes world/player/enemy/bit8; GrindSensor includes world/enemy/bit8 (`:169`, `:195`). Rails share enemy bit 4. No player group is authored or added natively, so names/types compensate. Define layer constants and intentional group membership, rather than claiming all detection is broken.
- Rail group is generated non-persistently (`scripts/mall_greybox_builder.gd:367`), absent from packed GrindAreas (`scenes/FloodedMall_Greybox.tscn:3498`, `:3589`); runtime reconnect (`scripts/mall_greybox_builder.gd:415`) does not restore it. Layer-4 fallback/body_entered still allow grinding: failed group assertion does not prove all rails unusable.
- Defensive chains exist in native animations/sensors (`src/player_controller.cpp:68`, `:1175`, `:2120`), disk spawning (`:2635`), enemy loading (`scripts/mall_greybox_builder.gd:228`), HUD/autoload recovery (`scripts/hud.gd:267`) and trigger counting. Canonicalize live dependencies before removing compatibility fallbacks. Native damage branches for MutatedBugEnemy are unreachable for normal 3D receiver lists; the class is 2D and already exposes take_damage.
- Active action names are defined (`project.godot:33`). Missing dodge is guarded (`src/player_controller.cpp:686`); ui_accept is built in. secondary_cycle is an unused empty alias (`project.godot:120`). toggle_skates/switch_tape/interact coexist with equip_skates/raw keys: rebinding inconsistency, not undefined-action startup failures.
- Candy immediately sets monitoring inside body callback, then also defers it (`scripts/health_candy_pickup.gd:135`), risking query-flush error in actual physics delivery; use deferred mutation only. Trigger sets triggered before validating spawn (`scripts/boss_encounter_trigger.gd:117`) and disables even on failure (`:148`); trigger_once=false never resets triggered. Queen thresholds are 396/198 HP (`scripts/dial_up_queen.gd:326`), not documented 400/200. Native speed includes AGI (`src/player_controller.cpp:287`); observed default walking 8.7 m/s, not advertised 6.

## Tests and coverage

Used existing Windows Godot 4.3/DLL, a waiting .NET process wrapper, and controlled invocation:

`Godot_v4.3-stable_win64.exe --headless --path . --log-file ops/reports/AUDIT-ARCH.md --quit-after 3 -s tests/<name>.gd`

The report temporarily held logs and was replaced by this document. Default user-data logging was denied; using reserved NUL as a log filename also caused logger/startup signal-11 failures before useful script execution. Those crashes are not attributed to individual gameplay tests. Controlled runs had no process crashes/timeouts but **all returned 0**, including assertion/runtime failures terminated by quit-after. PASS means assertions reached the script's success marker, not clean integration. Certificate-store errors were common environment noise; synthetic tests also produced null-tree/transform/physics errors and leaked-object/resource warnings.

CONTEXT.md was updated during this audit to quarantine player/cursor/grinding tests for teardown crashes. Already-collected controlled results are retained; no further runs followed reading that warning. These results do not establish safe ordinary teardown.

| Script / system | Result | Actual coverage and limits |
|---|---|---|
| test_systems.gd / progression, stats, NPC | **PASS assertions** | Real native XP accumulation/leveling/stat mutation/lock and pure Vibe check; manually grants XP (`:18`), no kill/reward or dialogue integration. |
| test_tapes.gd / tapes | **PASS assertions** | Effective getters for eight tapes and wrap (`:11`, `:59`); useful native balance test, no live audio, HP transition or motion. |
| test_candy_pickup.gd / candy | **PASS assertions** | Manual callbacks cover heal/cap/full-health rejection/one-time consumption and placement (`:45`, `:93`, `:110`). Manual READY, no real overlap/query flush/timer deletion. SFX sample/hook checks (`:79`) do not prove audibility. |
| test_flamethrower_particles.gd / particles | **PASS assertions** | Serialized quad/material/gradient/curve/spread configuration; no GPU render/alignment or damage. |
| verify_camera_and_hud.gd / scene metadata | **PASS assertions** | Off-tree scene loading, camera mask/pager size flags (`:7`); no rendered viewport, tracking, cursor ray or HUD runtime validation. |
| test_gameplay_fixes.gd / inputs, flame, boss/gate | **PASS assertions** | Bindings/manual particle stepping, direct boss phases/collision configuration, synthetic dummy-enemy gate (`:18`, `:44`, `:95`). No authored enemy-clear run or real hit/evade/checkpoint/victory sequence; phase samples skip exact boundaries. |
| test_3d_player.gd / locomotion | **FAIL runtime** at `:37`: nonexistent `_ready` | Only instantiation/type checks run. `_ready` and later `_physics_process` unbound. Later stale assertions require attack immobility (`:202`) and skating speed_scale=2 (`:170`). Quarantined. |
| test_cursor_aiming.gd / aiming/disk | **FAIL runtime** at `:29`: nonexistent `_ready` | Aim/combat checks never run. Later enum 1 at `:100` selects flame, not disk (2, `src/player_controller.hpp:57`). Some later assertions only verify types. Quarantined. |
| test_grinding.gd / synthetic and authored rails | **FAIL assertion** at `:111`: missing grindable group | Earlier synthetic entry/progression/adrenaline/end momentum assertions pass; packed group check catches real persistence discrepancy. No physical entry, cancellation or landing slam. Quarantined. |
| test_5_systems.gd / camera/audio/boss/aggro/save | **ENVIRONMENT BLOCKED** at `:154` | Save WRITE code 12 under restricted user-data permissions; roundtrip `:156` onward unexecuted. First four sections print pass, but Walkman fallback can accept SFXAudio (`:51`), UI assertions can skip (`:81`), no trigger instantiated, aggro manual (`:128`). Uses production save path: isolate before routine use. |
| build_greybox.gd / generator | **NOT RUN: mutates shipped scene** | ResourceSaver overwrites mall (`:71`), prohibited by brief. Copies player/HUD from main (`:45`, `:55`) without preserving trigger/checkpoint/candies. Generator, not read-only verification. |

Totals: **6 assertion passes, 3 code/scene failures, 1 storage-blocked, 1 mutating generator skipped**. Initial logging crashes excluded from script attribution. No unrestricted save-write retry. No successful test save write occurred.

Additional smoke loads of root main, canonical main and mall each exited 0 after 90 frames, restored pre-existing save and emitted exit leak/resource warnings. Establishes current-workspace loadability, not launch correctness, fresh-clone import or gameplay completion.

Missing critical coverage: real scene-tree sequence intro/menu → fresh/continue → overlap damage → kill XP → checkpoint → death/reload at same checkpoint/intended HP → enemy clear → boss → victory/exit. Add focused physics checks for evade cancellation, bat aiming with floor overlap, disk crossing rails/thin targets and bounded knockback. Await normal READY/physics frames, free objects, treat script errors as failures and use disposable save storage. Native simulate_physics can call READY again when required nodes are absent (`src/player_controller.cpp:2259`), resetting health and hiding initialization defects. Constant/resource checks may remain, but cannot support claims of full gameplay validation.

## Build and fresh-clone risk

- Debug Windows DLL is tracked and loaded successfully. Release DLL named in `biopunk.gdextension:9` is absent; release export needs template_release build. Manifest has only Windows entries despite README Linux badge (`README.md:7`): a Linux build alone will not load without matching manifest entries. Declare Windows-only slice delivery or supply platform entries/artifacts.
- godot-cpp pinned at d5cc777a89d899665fb61f1650ef0dc0cf6488c4 (`.gitmodules:1`); extension API identifies 4.3 stable (`godot-cpp/gdextension/extension_api.json:3`). No evidence of wrong binding version. Source build requires submodule initialization before root SConstruct:6 can load its script.
- Engine executable/imported .godot cache are not supplied by Git. Fresh headless tests need asset/extension import. Tracked GLB/textures/music/intro video/Skate_Grind are present; cache absence is not missing-source evidence. These runs used current cache/DLL; clean import/source build remain unverified.
- Preserve MSVC /MT compatibility (`SConstruct:11`) across bindings/application runtime options. Default static runtime is consistent; do not switch only one side. DLL locks remain operational risk. No build attempted.
- SCons documented (`README.md:121`) but no root dependency pin, export preset or automated gate. Before delivery, build debug/release against pinned bindings, import with 4.3 in a fresh workspace, then run corrected isolated tests. Keep scene generators out of automatic test enumeration.

## Conservative split recommendation

Keep native player physics/state transitions/rails/health and effective-stat math; a rewrite adds risk without fixing the loop. Keep AI/projectiles/encounters/save/session/HUD in GDScript. Repair native state exits and define damage/knockback contracts first; give a small GDScript session/encounter owner New/Continue, checkpoint respawn and victory, removing those choices from HUD/native menu defaults. Expose computed combat values instead of copying formulas in HUD; move only tape names/buffs/audio paths and reward/encounter tuning into Resources if rebuilds impede iteration. Consolidate reusable player/HUD scenes and canonicalize live root references before cutting legacy 2D enemy/NPC/dialogue. This is a few explicit contracts and one flow owner, not a wholesale migration.

