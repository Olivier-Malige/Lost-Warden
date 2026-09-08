# Dark Space Art Review

Date: 2026-09-07. Status: benchmark accepted; production harmonization passes 01 and 02 implemented. Runtime integration and combat playtesting remain pending.

## Scope and evidence

Reviewed local itch.io banner v2, page background v3, cover, selected exported gameplay sheets, palette, production inventory, universe bible, and scene references. The published itch.io page was not checked. No gameplay session was captured; motion, combined transparency, and combat readability still require runtime validation. The initial review changed no art or runtime files. The authorized implementation passes are recorded below.

Pixel measurements below use the first frame only, counting RGB values of pixels with alpha greater than zero, without alpha weighting. They exclude later hit/explosion frames and are composition indicators, not perceived brightness measurements. Samples: Razor Fighter, its elite, Siege Turret, Grave Carrier, Dread Ark, red Nomad, and small asteroid.

## Conclusion

Keep Lost Warden 24 for the first harmonization pass. All visible RGB colors in the seven sampled frames belong to it. The larger mismatch is the distribution and placement of colors, followed by detail density, elite treatment, and inconsistent color-role documentation.

The store art suggests blackened industrial space: broad dark masses, recessed mechanisms, sparse warm edge highlights, red internal heat, and large empty areas. Gameplay sprites currently reveal more of their machinery through repeated steel stripes and outlines. Preserve their silhouettes while consolidating shadow masses and reducing repetitive highlights.

Do not transfer the banner's extremely low ship contrast directly to moving enemies. Gameplay needs a stronger readable silhouette than promotional scenery.

## Asset findings

| Asset | Evidence and interpretation | Proposed treatment |
|---|---|---|
| Nomad | Neutral frame uses five colors; Pale Steel covers 11.7% of visible pixels. Its restrained hull already relates well to the cover's player ship. | Use as the small-sprite material reference. Preserve readable fins and nose; settle player color roles before changing weapons. |
| Razor Fighter | Ten colors including engine tones; Gunmetal covers 48.3%, Steel 13.0%. No Pale Steel or white in the sampled frame. | It is not excessively white: its broad midtone coverage is the issue. Move selected interior plates into Hull Shadow; retain short directional Steel edges. |
| Fighter elite | Shield Violet occupies 154 of 610 visible pixels (25.2%); the regular frame has 292 visible pixels. The outline and aura greatly increase apparent footprint. | Replace the continuous violet border with a few distinctive plate inlays and broken accents. Keep elite recognition through a consistent marking pattern plus restrained pulse. Check aura alpha before comparing perceived brightness. |
| Siege Turret | Thirteen colors; Deep Space and Hull Shadow already dominate. Pale Steel/white occupy 5.3%. | Preserve the dark structure and directional aperture. Reduce isolated decorative pixels before darkening the whole unit. |
| Grave Carrier | Pale Steel occupies 11.8%, arranged as repeated ribs. | Retain a few structural ribs; sink secondary ribs and machinery into darker tones. Avoid evenly illuminating both sides of every compartment. |
| Dread Ark | Steel occupies 22.3%, Pale Steel/white 1.9%. Wide repeated panel strips reveal most of the surface. | Highest-value large-sprite revision: dark wing masses, selective rim highlights, fewer bright panel stripes, and a dominant red trench. Preserve attack-stage information and weapon anchors. |
| Small asteroid | Dark Bronze occupies 44.9%; white edge pixels and fragmented markings suggest metallic platework. | Favor irregular rock clusters and shorter dim edges. Evaluate existing Dark Slate source variants before producing replacements. Keep some bronze for material diversity. |
| Background planets | Large violet/orange rings and simple stepped spheres can suggest colorful arcade space. Export alpha reaches 185/255. | Dim or break ring highlights and keep lit surfaces sparse. Avoid confusing scenery accents with elite or hazard signals. |
| Nebula layers | Blue alpha peaks at 37/255, mauve at 28/255; isolated RGB previews misrepresent their intended faint appearance. | Judge only when composited over Void. Retain subtle cool depth; reserve red clouds for controlled regions, away from red projectile traffic. |

## Palette direction

The existing dark neutral ramp is suitable:

- Void `#06070C`: empty space and deepest cuts.
- Deep Space `#101522`: recessed structures.
- Hull Shadow `#222735`: dominant enemy armor.
- Gunmetal `#464A52`: lit planes.
- Steel `#74777D`: short edges and selected mechanical landmarks.
- Pale Steel `#B8B6AE`: rare material highlights, more available to the player.

Keep Oxblood `#3A0D14`, Warden Red `#9C2020`, and Amber `#9E6B2D` as the main hostile identity accents. The page art appears more saturated red than the coral Neon Red `#FF5A4D`; reproduce its dark-to-red contrast first, rather than immediately adding another red.

Treat the 24 colors as a shared library, not a requirement to show every hue at once. Cyan, violet, green, and pink should convey specific gameplay information. Solar yellow should remain an interface/energy accent, not a general hull highlight.

Proposed trial targets, not existing requirements:

- Ordinary enemy idle frame: roughly 65–80% dark structural tones, 15–30% lit metal, 2–8% luminous accents; choose a combination totaling 100%.
- Use about six colors for a small hull; count engine and animation effects separately when evaluating material complexity.
- Use one consistent lighting direction, broad connected shadow clusters, and interrupted highlights. Avoid complete bright outlines and alternating light/dark stripes across every panel.
- Keep attack cores, pickups, focus indicators, and hit feedback readable. Darkening the entire rendered scene would undermine the objective.

Only consider a palette revision after a representative scene passes with these changes. A new dark violet or deeper red is optional, not currently justified by missing colors alone.

## Resolve conflicting color rules

The bible describes navy/cyan players and a violet player-two cue, while the current master exports red and blue variants. The inventory mixes those descriptions with red/blue reactors, shots, and shields. The palette assigns red to enemies and violet to shields; the bible also assigns violet to elites.

Recommended proposal: keep the red Nomad cockpit as a branding detail, but use a cool dominant envelope for allied fire and red/amber for enemy fire. Distinguish cooperative players with localized markings, shape cues, and HUD labels. Reserve elite violet for small stable marks; shields can remain distinguished by their barrier silhouette and animation. This revisits an established red/blue production choice and needs a deliberate art-direction decision before asset edits.

An all-red visual theme is unsuitable as the sole gameplay identification system. Test friendly and hostile shots crossing, with shields and elite units active, including a grayscale inspection.

## Integration limits

The inspected player scene still references `x_wing.png`; the carrier scene references `mother_ship.png`; the background scene references `background.png` and `background_2.png`. Searches of scenes, core, and data found no references to the new Nomad sheet, new parallax directory, new carrier sheet, or fighter projectile sheet. Existing enemy PNG paths already contain replacement exports, so the current project combines production generations.

Do not judge the completed production set from the current runtime alone. Conversely, exported-sheet approval does not establish final in-game readability. Keep integration in its authorized roadmap phase.

## Recommended sequence

1. Establish a small benchmark set: Nomad, Razor Fighter, its elite, Dread Ark, one asteroid, allied/hostile shots, and one composed background.
2. Retouch the Dread Ark and elite first; they show the largest mismatch with the store hierarchy. Revise normal enemy midtones and asteroid highlights selectively.
3. Compare the benchmark at native resolution and intended gameplay scale on a dark starfield and on the brightest intended nebula region.
4. Validate dense combat, cooperative fire, elite recognition, boss telegraphs, hit flashes, and explosions. Check motion and small-window readability; accept bright transient effects without letting idle sprites compete with them.
5. Once the benchmark is accepted, align the bible, palette usage guide, and production inventory, then propagate the treatment through editable sources and matching exports.

Acceptance: ships retain recognizable silhouettes; hostile shots stand out immediately from hulls and scenery; allied fire remains distinguishable; elite identity survives without a complete luminous border; the boss reads as a dark mass with a focal trench; background lights never resemble urgent combat signals.

## Implemented benchmark — pass 01

The maintainer authorized the start of the graphical rework after the baseline commits `f2d74fc`, `13b4802`, and `cdf14ed`.

- Razor Fighter: darker wing planes and shorter Steel highlights on frames 1–4 and 6. The hit frame and seven explosion frames remain pixel-identical to the saved export.
- Fighter elite: matching hull treatment, interrupted violet markings, and a hidden aura layer to avoid detached red fragments resembling hostile shots. The editable aura remains available. Explosion frames remain pixel-identical.
- Dread Ark: darker wing ribs and recessed bay grooves across all twelve phase frames; darker engine housings retain amber outlets. Trench, phase accents, and weapon-state layers remain intact.
- First-frame Steel coverage: fighter 13.0% to 4.5%; boss 22.3% to 2.0%. Elite violet coverage: 25.2% to 5.8% of visible pixels.

Validation: all exported visible RGB values remain in Lost Warden 24; PNG dimensions are unchanged; normal fighter and boss alpha masks are identical across their full sheets. Source dimensions, frame counts, durations, tags, layer names, and slice bounds are preserved. No runtime code or scene changes were made. Runtime combat readability has not yet been validated.

Comparison: `assets/art/sprite_references/dark_space_pass_01.png`, before on the left and after on the right. Its editable composition is `assets/sources/art/dark_space_pass_01.ase`. These are first-frame comparisons over Void, not gameplay screenshots.


## Production Propagation — Pass 02

The maintainer accepted pass 01 and requested the same treatment for the remaining produced set. Sixteen production sources now supply 26 updated PNG exports and two synchronized player GIFs. The original first-pass assets remain intact.

| Family | Treatment |
|---|---|
| Talon, drone, turret | Darker lower planes and selective edge highlights; targeting and engine cues remain luminous. |
| Grave Carrier | Most repeated pale ribs recede into the hull; selected top ribs and turret edges remain visible. Amber outlets retain their color inside darker engine housings. |
| Four remaining elites | Interrupted violet marks and selective plate accents; aura layers hidden, with editable data retained. |
| Small/large asteroids | Original-shape Dark Slate selected; bright seams and mineral hotspots subdued on ordinary frames. Earth and platework alternatives remain available. |
| Nomad and energy icons | Restrained lower/rear metal highlights; player markings and energy cores retained. Both player exports updated. |
| Siege projectile | Outer armor dimmed independently of its bright inner charge, core, and impact/explosion sequence. |
| Boss beam/destruction | Deep Ion beam fringe and darker hull debris; luminous core, magenta body, blasts, and shockwave retained. |
| Parallax | Subdued rings and ruins, less prominent debris, restrained warm stars, and faint blue/red haze. Existing layer/export names remain stable. |

Other produced player weapons, shields, reactors, fighter/interceptor shots, and boss projectiles already satisfy the emissive hierarchy and remain unchanged. The legacy pickup remains excluded by the production inventory. Store art, historical files, and future reference boards remain reference material rather than runtime replacement targets.

First-frame measurements use visible pixels without alpha weighting, as in the initial audit:

| Asset | Steel or brighter, before → after | Elite violet, before → after |
|---|---|---|
| Talon | 12.3% → 2.1% | — |
| Drone | 11.9% → 5.0% | — |
| Turret | 16.7% → 8.0% | — |
| Carrier | 11.8% → 4.5% | — |
| Elite Talon | — | 24.9% → 6.1% |
| Elite drone | — | 28.5% → 3.2% |
| Elite turret | — | 17.1% → 1.9% |
| Elite carrier | — | 12.8% → 1.3% |

Here, “Steel or brighter” counts Steel, Pale Steel, Star White, and Flash White; it is a palette-group measurement, not luminance or a ranking of all hues.

### Validation

- All 26 changed PNG exports retain their dimensions and use only Lost Warden 24 RGB colors on visible pixels.
- Non-elite foreground alpha masks remain unchanged. Background occupied-pixel masks remain unchanged; haze, planet, and debris alpha values were intentionally reduced. Elite aura/outline coverage was intentionally reduced.
- All 16 updated sources preserve canvas dimensions, color modes, palette entries, frame counts/durations, animation tags, layer names, cel positions, and named slice bounds/pivots.
- Eight enemy explosion sequences and four normal-enemy hit flashes remain visually pixel-identical after normalizing invisible RGB values. Protected source core, explosion, impact-flash, and reference layers remain intact.
- Both Nomad GIFs match their PNG frames, retain their durations, and preserve left/right banking symmetry.
- Static before/after and composed-background inspection completed. No gameplay scenes, scripts, or resource definitions were changed. The composition is illustrative and does not verify runtime collisions, animation playback, solo/co-op readability, or shader behavior.

### Review Artifacts

All comparison PNGs have layered `.ase` counterparts under `assets/sources/art/`:

- `assets/art/sprite_references/dark_space_pass_02.png`: before left / after right; ordinary enemies, elites, asteroids/player/icons, then projectile samples.
- `assets/art/sprite_references/dark_space_background_comparison.png`: before left / after right, with both backgrounds composited over Void.
- `assets/art/sprite_references/dark_space_composition.png`: illustrative 1066×800 composition with sprites displayed at 4×, using the accepted boss and revised production set. This is not a gameplay capture.

The current live elite effect described in the historical Phase 1 follow-up may still differ from these exported sources. The future elite integration requirement in the roadmap now refers to the accepted localized markings; runtime integration remains separate.
