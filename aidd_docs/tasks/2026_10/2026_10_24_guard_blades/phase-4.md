---
status: done
---

# Playtest revision: rank reach and anticipation

Authorized by the maintainer on 2026-10-24 after accepting the larger base size: increase area with upgrades, shorten their proc times and show a small timer before activation.

- Keep rank-one outer radius 60 and the central gap 16. Set rank-two/three outer radii to 72/84 (+20/+40% reach); start intervals become 3/2/1.5 seconds. Preserve damage 2/3/4 and existing sweep geometry/durations.
- Show a tiny personal, team-colored filling bar above the ship for the final 0.6 seconds before each salvo, without numbers or text as requested in the maintainer's follow-up. Anticipate the initial salvo too. The warning never deals damage, clears shots or lengthens recurring intervals. Pause freezes it; death/teardown remove it with the controller.
- Preserve cooldown percentage on rank changes and initial warning time before the first salvo. The ongoing salvo retains its original damage, collision radius and native rank art.
- Author rank variants through MCP Aseprite, keeping the inner gap fixed and pixel scale native. Existing icons remain intact. Cards report reach growth in percent alongside damage and interval.
- Validate real rank-boundary damage/clearing, old/new rank snapshots, timer boundaries, pause, co-op, teardown, offer/menu regressions, diagnostics and palette/source/export/runtime parity. Inspect native captures and stop for playtest before ricochet.
- Maintainer feedback on 2026-10-25 further requests a clearly visible equal meeting: converge in 160ms, hold the identical bright images together for the remaining 120ms of damage, then cool. The authored motion duration must leave a positive active hold. MCP Aseprite supplies merged terminal frames and narrow inactive fragments; right-hand mirroring ends at convergence so the two held images match exactly.

Completed locally: 280 guard / 3,781 offer / 51 selection native checks pass; 106 diagnostic documents are clean, three art/export/import pairs match, and nineteen older icon columns are preserved. Bar-only warning, both team sizes and updated menu captures are inspected. See [evidence](validation.md).
