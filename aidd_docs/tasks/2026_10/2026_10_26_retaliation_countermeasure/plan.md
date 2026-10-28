# Retaliation Pulse emergency countermeasure

Historical implementation checkpoint. The later [defense role split](../2026_10_26_defense_role_split/plan.md) supersedes the shield/contact interaction and presentation below; retaliation damage, recharge and protection timings remain applicable.

Approved behavior: the maintainer accepted protection plus a stronger retaliation on 2026-10-26, then restricted activation to direct enemy body contact. The reflector sphere takes priority and the pulse is reserved for the next enemy collision threatening the hull.

- A ready pulse cancels a direct enemy collision hit, including a lethal hit, before energy, hit slowdown or injury effects change. Enemy projectiles, continuous beams and asteroid bodies never trigger or consume the charge.
- It grants 0.6 seconds of protection against projectiles, bodies and continuous beams. This interval is independent of ordinary injury grace and reactive armor.
- Shield charges remain first in the incoming-hit path. Sphere rupture leaves the pulse ready; an additional enemy body collision against the hull triggers it.
- The counterattack clears unreflected hostile shots at 360 degrees and damages each visible enemy/boss group once. Common DAMAGE applies once; criticals and recursive effects remain excluded. Explicit armor continues to block the wave.
- Initial playtest values by rank: damage 4/6/8, radius 64/80/96 pixels, cooldown 12/10/8 seconds. Expansion lasts 0.20 seconds, damage/clearing remains active through 0.35 seconds, and inactive fragments end at 0.60 seconds. These are provisional values, not final balance acceptance.
- Ranking during cooldown preserves completed recharge percentage. Ranking never grants an immediate extra charge or extends active protection.
- The existing ready indicator remains, with a distinct brief protection state. Wave pixels and timing must track the larger gameplay footprint.
- All state is personal to each co-op player and freezes on pause. Death and world teardown cancel protection, pending waves, live waves and hit roots safely.
- Retain the three utility slots, existing family ID and rank count. No new power-ups, unrelated balance, commit or publication.

Implementation: update resource validation and values, central hull protection, pulse presentation and the affected defensive tests. Verify real projectile/body/beam callbacks, simultaneous and lethal hits, shield priority, armor grace, rank changes, co-op isolation, pause, death, restart, damage attribution, pooling, occlusion and visual saturation. Inspect native solo/co-op and upgrade-card captures; run affected progression, projectile and guard regressions.

Implemented locally. See [validation evidence](validation.md). Await maintainer playtest; final balance remains open.
