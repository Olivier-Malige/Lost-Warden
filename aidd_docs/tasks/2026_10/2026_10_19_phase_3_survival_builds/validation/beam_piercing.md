# Signature beam piercing — 2026-10-21

Following the maintainer's cannon-piercing playtest, piercing is now a personal utility for Nomad's manual plasma beam. The live catalog replaces `piercing` with `beam_piercing`; critical hits remain offensive. A nearest-target electric cannon arc will use the planned `energy_chains` family in a subsequent checkpoint. No chain or missile is implemented here.

The maintainer also requested a modest damage/width increase for this evolution. The prototype applies both bonuses with the utility; the unmodified beam retains its previous values.

| Rank | Extra targets | Initial damage per 0.1 s tick | Normal / overdrive width | Initial damage bonus |
| --- | ---: | ---: | ---: | ---: |
| None | 0 | 3 | 8 / 16 px | 0% |
| 1 | 1 | 3.6 | 10 / 20 px | 20% |
| 2 | 2 | 3.9 | 11 / 22 px | 30% |
| 3 | 3 | 4.2 | 12 / 24 px | 40% |

Widths receive authored +25/+37.5/+50% bonuses. Damage is `(3 + existing DAMAGE flat plasma bonus) * piercing damage multiplier`; overdrive applies its existing x1.5 once. Every crossed target multiplies subsequent damage and width by 0.8. Rank-three normal widths are 12 / 9.6 / 7.68 / 6.144 px; overdrive widths are 24 / 19.2 / 15.36 / 12.288 px. Values are prototype tuning for playtest, not final balance acceptance.

The family occupies one utility slot across all ranks, grants no charge and resets with the run. Zero starting plasma, base capacity 100, activation at 10, drain 20/second and one-second full-reserve overdrive remain unchanged. Armor stops traversal; one tick damages at most one surface in a logical boss group. A separate enemy beyond that boss can receive the next attenuated contact.

## Runtime and art

ContinuousBeam allocates four visible/collision segments once. Each segment uses the existing team-colored plasma art and shader, with independent material flow length. Query/collision width follow the same attenuation and existing x1.2 collision tolerance. One PLASMA hit root owns each tick, retaining player credit and excluding gun criticals/procs. Pause freezes flow/damage; deactivation clears contacts and disables all segment colliders deferred.

The Aseprite MCP redraws only column 10 in the card and miniature masters. `upgrade_icons_64.png` remains 768x128, with 64px cells at x640 and owner rows y0/y64; `upgrade_miniatures.png` remains 192x32, with 16px cells at x160 and rows y0/y16. A continuous stepped beam, pierced plates, real Nomad and plasma cartridge replace the cannon-bolt composition. All other columns are pixel-identical to the pre-revision exports. Fresh source composites match runtime exports exactly, use binary alpha and exact Lost Warden 64 colors. Original beam art/shader remain unchanged.

## Focused verification

Godot 4.7.2, addon-free project `.godot/phase_2_runtime_validation`, separate APPDATA per fixture. Latest runs after the damage/width increase:

| Fixture | Actual result |
| --- | --- |
| `tests/player/test_beam_piercing.gd`, native compatibility renderer | **118 checks PASS**, clean shutdown |
| `tests/test_upgrade_offers.gd`, headless | **2,125 checks PASS** |
| `tests/test_beam_upgrades.gd`, headless | **36 checks PASS** |
| `tests/player/test_player_hit_contract.gd`, headless | **41 checks PASS** |
| `tests/player/test_beam_impact.gd`, headless | **18 checks PASS** |
| `tests/player/test_beam_effect.gd`, headless | **PASS** |
| `tests/test_progression_activation.gd`, headless | **67 checks PASS**, existing shutdown warning (two ObjectDB instances / one resource) |
| `git diff --check` | **PASS** |

The beam fixture covers every rank, normal/overdrive, actual ShapeCast contacts and HP loss, attenuated collision width, continuous joins, off-axis exclusion, restored full strength after removing the front obstacle, armor, multipart boss deduplication, owner credit, personal slots/ranks, no free plasma, existing DAMAGE composition, unchanged partner/base beam, reset, pause and five activation cycles without node/root growth. It rejects incomplete/negative width data and verifies the card discloses damage/width bonuses.

Native 640x400 captures inspected after the increase: `beam_taper_normal_1.webp`, `beam_taper_overdrive_1.webp`, and `beam_taper_choices.webp` in the isolated runtime; the fixture also captures samples 0 and 2 in both beam modes. Both owners show progressive narrowing and distinct normal/overdrive widths. Controlled review offers demonstrate card layout, not natural offer generation. Numeric lines fit co-op cards; utility miniatures and the elimination/level HUD remain readable. Focused ICON-PIXEL-LOCK and COMP-SAFE-EDGE checks score 2/2 for the inspected presentation; collision agreement is also asserted numerically.

No full economy rerun, general performance certification or human co-op balance acceptance is claimed. Step 5's remaining solo observations and qualitative feedback are outstanding. No save-schema, encounter-pressure or dedicated audio change, commit or publication is included.
