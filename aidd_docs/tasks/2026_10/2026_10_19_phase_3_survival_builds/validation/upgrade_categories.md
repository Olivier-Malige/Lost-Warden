# Upgrade categories and balanced choices

Delivered locally on 2026-10-25 after the maintainer requested a category on every power-up card and an offensive/utility choice at every level. Scope stops before ricochet. No commit or push requested.

## Behavior

Cards show their snapshot category as **OFFENSIVE**, **UTILITY**, or **RECOVERY** for consumable energy. Category labels use the existing palette, font and snapshot data, fit horizontal solo and compact co-op cards, and do not intercept input. The recovery category replaces the duplicate recovery rank caption. No artwork, effects or authored family categories change.

`UpgradeTable.generate_offers` reserves one eligible offensive and one eligible utility at every selection, rather than only the first. Owned-rank/new-family reservations then coexist within three distinct choices. Remaining positions retain authored weighted selection. A full category's slots still permit its owned ranks; unowned families stay blocked. If all eligible families in a category are exhausted, the hand uses only the remaining candidates. Recovery does not count as a utility. One/two candidates and automatic score fallback remain unchanged.

Offers remain personal in co-op: P1/P2 order is fixed, snapshots are copied before either draw, and each queued level recomputes eligibility. The optional legacy first-selection argument is retained for callers but no longer narrows the category guarantee.

## Verification

Godot 4.7.2, native OpenGL Compatibility rendering:

| Fixture | Checks | Result |
| --- | ---: | --- |
| Upgrade offers | 4,531 | PASS |
| Selection input/layout | 71 | PASS |
| Progression activation | 80 | PASS |
| Fresh GDScript diagnostics | 106 documents | Zero issues |
| `git diff --check` | — | PASS |

All final native runs exit cleanly. Coverage includes both categories after the first level across fifty seeds and several personal builds, full family capacity with owned ranks, exhausted categories, distinct/eligible offers, retained acquired/new choices, two-candidate catalogs and asymmetric co-op availability. Existing deterministic traces, authored weighting, fallback, stale/duplicate choices, nested pause, queued levels and restart regressions pass.

Native solo, co-op and wide captures show the new labels; assertions verify category text, bounds and minimum text width for every visible card. The freshly inspected captures are `phase3_selection_coop.webp` and `phase3_selection_solo.webp` in the ignored native validation project. Final logs are `.godot/guard_blades_qa/category_offers_final.log`, `category_selection_fit.log` and `category_activation.log`. Fresh diagnostics are `.godot/console_qa/guard_diagnostics.json`. Stop for maintainer playtest before ricochet.
