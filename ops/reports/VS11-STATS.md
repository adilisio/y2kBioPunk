# VS11-STATS

Worktree: `C:\y2k-biopunk-rpg\.worktrees\vs11stats`, branch `vs11-stats`.

## Changes and formulas

The player now carries a wooden tapered bat with a dark grip and a small emissive cyan tape band, attached to the imported right-hand bone by `HandBatAttachment` / `HeldBat`. The existing animations and melee hit registration are unchanged. The model's GLB names the bone `mixamorig:RightHand`; the runtime imported bone name is recorded below after verification.

All formulas use effective, tape-adjusted stats:

| Effect | Before | After |
| --- | --- | --- |
| Strike damage | `15 + 2.5 * STR` | `15 + 4 * STR` |
| Walking speed | `base_movement_speed + 0.15 * AGI` | `(base_movement_speed + 2.7) * 1.03^(AGI - 18)` |
| Skating speed | `skate_speed` | `skate_speed * 1.03^(AGI - 18)` |
| Maximum HP | `10 * VIT` | `max(1, 100 + 12 * (VIT - 10))` |
| Disk damage | `25 + 2.2 * AGI` | Unchanged; shared native getter also feeds the sheet |
| Critical chance | No combat effect | `clamp(0.02 * VIBE, 0, 1)` |
| Critical strike | None | Melee damage ×1.75, then truncation through existing integer enemy damage interface; +40 ms hit-stop; cached synthesized 80 ms `crit_pop` |
| Summoned roach / cicada XP | 15 / 10 | 0 / 0 |
| Normal roach / cicada XP | 15 / 10 | Unchanged, once per death |
| Queen XP | 250 | 120, once per death |

Movement is anchored at the shipped starting Bubblegum stats (18 effective AGI): 8.7 m/s walking and 12 m/s skating. Each additional point multiplies either speed by exactly 1.03. VIT 10 still gives 100 HP; ordinary point spending adds 12 HP. Melee rolls once per strike, preserving the combo's existing ×1.5 third-hit multiplier. VIBE 0 never crits and effective VIBE 50 always crits. The damage interface has no colour parameter; the brief's sound + hit-stop fallback is used, leaving enemy flash behaviour unchanged.

The sheet shows effective STR / AGI / VIT / VIBE, live strike / speed / disk / HP / critical numbers, per-point gains, and the tape explanation. Its width is 820 pixels, with 16-pixel stat labels. Unspent points retain the existing yellow highlight. Level-up pages state the newly earned +1 point and invite pressing C.

## XP computation

The curve remains integer-truncated ×1.5: 50, 75, 112, 168, …

- Plaza: `170 - 50 - 75 = 45`, so level 3 with 45/112 XP before the arena.
- Summoned minions: any number of kills adds 0 XP.
- Queen: `45 + 120 - 112 = 53`, so level 4 with 53/168 XP after defeat.
- Total 290 XP is below the level-5 cumulative threshold `50 + 75 + 112 + 168 = 405`. The Queen encounter therefore adds exactly one level after a full plaza clear.

`tests/test_stats.gd` verifies these values through native progression and actual enemy death methods, including repeated death calls. It also checks per-point effects, forced melee crits against a roach, the pop cue, sheet text and the real hand attachment.

## Verification

Pending build, headless suite and the two brief-authorized off-screen shots.

## STOP items

Pending verification. The existing combat regression hard-codes pre-change damage; permission to update that file beyond the packet's listed test ownership was requested separately.
