# Player banking master source

`ship_banking_master.aseprite` is the single editable source for the red and blue player variants.

| Layer | Role | Default visibility |
| --- | --- | --- |
| `Base hull` | Shared rigid-roll hull and highlights | Visible |
| `Player Red` | Red cockpit and wing accents | Visible |
| `Player Blue` | Blue cockpit and wing accents | Hidden |

Only one team-color layer should be visible during export. `Player Red` is selected by default. To export the blue variant, hide `Player Red` and show `Player Blue`; all frames, tags, timing and pivot remain shared.

The master has 13 synchronized frames, 39 cels, five animation tags and the fixed `(16, 16)` `ship` pivot. Team layers differ in 14 pixels in the neutral pose: red uses `#9C2020`/`#3A0D14`; blue uses `#78B7CF`/`#102A4A`. Both are Lost Warden 24 colors.

The neutral pose is bilaterally symmetrical. Each right-bank frame is the exact horizontal mirror of its matching left-bank frame, and return poses reuse their corresponding outbound frames. Red and blue exports were regenerated from this corrected master.


The dark-space pass selectively reduces rear-wing highlights and lower outer-hull midtones across all 13 frames. Forward highlights and both team-color layers are unchanged. The two PNG sheets and GIF previews are synchronized with this source; frame layout, duration, pivot, and left/right symmetry remain unchanged.
