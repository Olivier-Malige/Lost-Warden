# Distinct projectile reflection and contact retaliation

The maintainer clarified on 2026-10-26 that Reflection should protect only against projectiles, and requested clearer descriptions, icons and effects because the two defensive upgrades were too similar. This supersedes the former sphere body/beam protection and shield-first contact behavior.

- Reflection reverses hostile projectiles, spending one charge per distinct shot. Keep 3/5/7 charges, 8/6/4-second recharge, a 20px projectile interception radius, co-op ownership and safe projectile pooling.
- Actual enemy or asteroid hull contact shatters all remaining reflector charges and starts recharge. Reflection does not absorb that collision. Bodies passing through the visual sphere without touching the player's hull leave charges intact.
- Continuous beams bypass Reflection and do not consume its projectile charges.
- A ready Retaliation Pulse independently cancels a direct enemy or asteroid hull collision, including the collision that breaks Reflection, then grants its existing 0.6-second protection and counterattack. The maintainer explicitly added small and large asteroids after the visual revision. Projectiles and beams cannot trigger it.
- Preserve retaliation damage 4/6/8, recharge 12/10/8 seconds and the 0.20/0.35/0.60-second wave boundaries. The maintainer found rank one's explosion too large, so its radius is reduced from 64px to 48px; rank two/three retain 80/96px. Criticals and recursive effects remain excluded.
- Reflection uses its original owner-colored sphere: red for the red player, blue for the blue player, including reflection arrows and rupture fragments. The maintainer explicitly requested this color restoration after the universal cyan revision. Retaliation retains its amber ready diamond, brief protection sparks and golden pixel-art explosion matching its active damage radius. To address magnification feedback, its dedicated Aseprite animation is authored at native 48/80/96px radii, with fine 1–2px contours. Expansion only shrinks native frames; no frame is magnified.
- Keep the existing 64px and 16px atlases and editable Aseprite sources. Restore the original red/blue Reflection icons in column 6, as requested by the maintainer; retain the native golden Retaliation icons in column 18. Other columns stay pixel-identical. Generated standalone mirror/starburst assets are superseded and removed.
- Selection summaries explicitly identify PROJECTILES ONLY and BODY CONTACT. Resource descriptions explicitly include enemy and asteroid contact, body rupture, beam bypass and independent combo behavior.

Validate small/large asteroid and enemy contacts at every reflector rank, real callbacks and sustained polling, combo activation, projectile reflection/pool ownership, beam bypass, unrelated upgrade offers/selection, native solo/co-op/wide appearance and exact atlas/source preservation. Retain the existing fast-contact fix. No new slots, unrelated balance, commit or publication.

Implemented locally. See [validation](validation.md), including the scoped audio-shutdown observation from the selection suite. Await maintainer playtest.
