# Ricochet shards — 2026-10-29

The maintainer explicitly authorized step 13 after the guard-blade checkpoint. The family is implemented locally, with no commit or push requested.

Main/side cannons and escort bolts may emit one independent pooled shard on their first accepted impact. Ranks reach at most 1/2/3 additional groups, at 55% modified pre-critical damage initially and 80% retention per accepted rebound. Flight uses 300 px/s, 88px nearest visible acquisition, a 1.2-second lifetime, four active/reserved shards per owner and a 0.40-second cooldown independent of fire rate. Flight values and capacity are authored in the upgrade's embedded WeaponDefinition. Unsupported sources and all secondary hits cannot emit shards.

Shards sweep a center ray through actual physics surfaces each tick; their small diamond and trail are decorative around that point footprint. Armor blocks travel even if it appears after acquisition. Root history excludes previously accepted groups, including every part of a visited boss. Lost targets can reacquire without resetting lifetime or budget. Existing shards may finish after owner death; world cancellation invalidates their root. Pool release clears ownership, history references, target, timer and animation state before deferred parking. The existing generic ProjectilePool reset hook needs no additional branch.

The live catalog has 21 entries and retains three offensive plus three utility slots. Both teams have a new card/miniature column, and selection copy shows target count, initial damage, retained damage and cooldown.

## Verification

- Dedicated fixture: 101 headless / 103 native checks, zero failures. It covers rank damage and budgets, source compatibility, critical isolation, real cannon collisions for both owners, pause, owner death, saturation, missing targets, armor introduced during flight, pooled cleanup, boss exclusion, combined chain/explosion/critical roots and catalog acquisition.
- Upgrade offers: 4,923 checks, zero failures, including all three-family offensive capacity combinations with ricochet.
- Player hit contract: 41 checks, zero failures.
- Energy chains: 188 checks, zero failures.
- Impact explosions: 203 checks, zero failures.
- Upgrade selection: 76 checks pass. Its shutdown retains the previously documented resource/ObjectDB warning.
- Asset audit: zero pixel differences in all preexisting atlas columns; all three editable Aseprite exports match their PNGs exactly.
- Native travel/impact frames for both teams were captured to `.godot/ricochet_native_0.png` through `_7.png`; inspected at native scale. These fixture captures verify rendering, not human gameplay acceptance.

The local runtime cannot write its normal user/editor settings and shader cache directories under the current filesystem permissions. Explicit workspace log paths were used for the final fixtures. No script or physics-flush errors occurred in the focused fixtures.

Human playtest, broad balancing, dedicated audio and final combined-build acceptance remain pending. Stop before step 14.

## Maintainer playtest revision — 2026-10-29

The maintainer reported an empty selection illustration and weak propagation resembling lightning, then requested more rebounds and more shards at higher ranks. This supersedes the initial one-shard / 1/2/3-target contract: ranks emit 1/2/3 shards, each with a 3/4/5 accepted-target budget. All shards of one root still share visited groups and boss exclusions. Initial targets are distinct eligible groups; insufficient targets or free capacity produce a partial volley. The four-active/reserved owner cap, 0.40-second cooldown, 88px acquisition, 300px/s speed, 1.2-second lifetime, 55% initial pre-critical damage and 80% retention are unchanged.

The missing red icon was real: creating a second cel on the same Aseprite layer/frame replaced the first team's cel. A separate player-one layer restores it in both atlases. Raw and imported texture audits now count 560 nontransparent card pixels and 35 miniature pixels per team. A regression rejects invisible imported card/miniature cells for either owner. Travel/impact cells grow from 8px to native 16px with a brighter metal core, colored tail and broader impact fragments, keeping the swept point collision footprint unchanged. Selection cards show shard count and rebound budget.

Revised fixture: 123 headless / 125 native checks pass, including rank volleys, distinct launch targets, shared group exclusions and both imported icon rows. Upgrade offers: 4,923 checks; energy chains: 188 checks. Asset parity audit: zero mismatches. Human acceptance remains pending. No commit or push requested.

## Selection illustration style revision — 2026-10-29

At the maintainer's request, the 64px card illustration now uses the same native Nomad hull as the neighboring electric-chain card, beneath three shaded metallic hulls and angular ricochet paths with bright shard cores. Red/blue ownership is preserved in a dedicated Ricochet composition layer. This replaces the sparse geometric symbol; gameplay and the 16px miniature are unchanged. The actual selection icon renderer was captured for both teams in `.godot/ricochet_cards_native.png` and inspected. Source/export parity and all twenty preceding atlas columns remain pixel-identical under the art audit (zero mismatches).

## Returning ricochets — 2026-10-29

The maintainer approved repeat contacts to distinguish physical ricochets from unique-target lightning. This supersedes the ordinary-hull shared-exclusion rule above. Each shard now owns its last contacted group and local visited set: it prefers an unvisited eligible hull, then falls back to a previously visited surviving hull if no fresh target can be acquired. It never selects or damages its last contacted group consecutively. The direct origin counts as the starting group, so two ordinary enemies support B → A → B returns; one isolated enemy never emits a self-loop.

A secondary ricochet channel permits ordinary repeat damage through the existing accepted-hit API. Root-wide boss exclusions remain stricter: a boss already hit by the direct source or any child stays excluded, including every overlapping cannon/core surface, even after a shard returns to another ordinary hull. Electric chains, blasts, direct shots and their histories keep their existing rules. Each accepted return consumes one of the unchanged 3/4/5 impacts and multiplies subsequent damage by 0.8 once. Lifetime, speed, range, cooldown, 1/2/3-shard volleys and the four-shard owner capacity are unchanged. Pool release clears both new fields. The upgrade description now explains return contacts.

Focused verification: 200 headless checks pass, including actual alternating impacts and accumulated HP loss for both owners at every rank, exact per-impact decay, fresh-target preference, isolated target behavior, boss entry/overlap/return exclusion, pause, owner death, restart and pool reuse. Native verification and return captures use the same fixture. Affected regressions pass: 188 chain, 203 explosion and 41 player-hit contract checks. The host still reports its root-certificate store warning at startup; focused tests report no script or physics-flush errors.

Human playtest remains pending; no commit, push or step 14 work requested.

Final native return fixture: 202 checks, zero failures. The eight `.godot/ricochet_return_0.png` through `_7.png` captures show a physical shard alternating between two surviving hulls; the return sequence was visually inspected. No visual assets changed in this revision.
