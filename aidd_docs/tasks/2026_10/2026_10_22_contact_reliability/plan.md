---
status: implemented
---

# Reliable hull contacts and three offensive families

Source: maintainer-approved plan, 2026-10-22. Preserve existing local work and stop for playtest before ricochet. No commit or publication requested.

## Delivery

1. Reproduce missed contacts with native enemies. Fix confirmed collision geometry/transform defects and separate shield body cooldown from hull injury eligibility. Preserve the player's central hitbox, last-impact absorption, ordinary injury grace and zero automatic ram damage.
2. Set three offensive and three utility families per owner. Draw selection slots from build capacities. Preserve family ranks, categories, manual cannon/signature beam, debug enforcement and personal co-op builds.
3. Measure actual energy loss for front/side/diagonal contacts, sustained overlaps, shield rupture/return, asteroids and boss. Verify offers, direct application, debug, solo/co-op menus and affected regressions, inspect native captures and fresh GDScript diagnostics.

## Acceptance

No unexplained central hull traversal; wing grazing remains forgiving. No post-rupture immunity from the shield's half-second body cooldown. Owned families remain upgradeable at full capacity; a fourth offensive family cannot be acquired. Keep damage, movement speed, power values, sprites and unrelated legacy geometry unchanged. Record baseline failures and final evidence separately.

## Outcome

Implemented locally. All three phases are done; [validation](validation.md) records 5,401 passing native checks, 104 clean diagnostic documents and the historical geometry failures remaining outside this scope. Start a fresh run and playtest before ricochet. No commit or push.
