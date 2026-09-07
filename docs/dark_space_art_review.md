# Dark Space Art Review

Date: 2026-09-07. Status: proposal, not an approved replacement for the existing roadmap or palette.

## Scope and evidence

Reviewed local itch.io banner v2, page background v3, cover, selected exported gameplay sheets, palette, production inventory, universe bible, and scene references. The published itch.io page was not checked. No gameplay session was captured; motion, combined transparency, and combat readability still require runtime validation. No art or runtime files were changed.

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
