# Universe Bible

Status: revised draft for maintainer approval  
Working codename: **Project Lost Warden**

This document defines a light original identity for the arcade gameplay rework. It intentionally avoids a developed narrative. The universe exists to support recognizable player ships, enemies, bosses, locations, audio, and interface art.

## Original pitch

The original pitch remains the foundation:

> A retro shoot 'em up about destroying and surviving incessant enemy waves.

The rework does not turn the game into a narrative campaign. The player is still a lone, lost space fighter facing an overwhelming force for as long as possible. A second surviving pilot joins in co-op. There are no quests, dialogue scenes, lore codex, named protagonists, or story ending in the current roadmap.

## Title direction

The working codename is **Project Lost Warden** because it preserves the legacy idea of a lost lone warrior while replacing the franchise-specific role.

Provisional final-title shortlist:

1. **Lost Warden**
2. **Starborne Exile**
3. **Beyond the Last Star**

The title remains open during preparation phase A. Availability and trademark checks are required after one direction is selected.

## High concept

A **Warden** pilot is stranded beyond the frontier after a battle against the **Obsidian Dominion**. With no route home and no support fleet, the pilot keeps moving through hostile sectors and destroys everything sent to stop them. The Dominion escalates from fighter patrols to elite squadrons, heavy warships, and command carriers.

The run ends when every player is dead. Survival time, danger, score, upgrades, elites, and bosses are the complete story told through play.

The fiction should remain understandable from the title screen and the sprites alone:

- the player is isolated;
- the enemy owns the battlefield;
- each new wave is more dangerous;
- surviving longer means reaching deeper hostile territory.

## Tone

The target tone is **heroic space opera under overwhelming military pressure**. It combines fast and readable starfighter combat, strongly differentiated science-fiction armies, and monumental dark machinery.

The game should feel adventurous and spectacular rather than hopeless or horrific. Dark industrial and gothic details give the enemy scale, while bright player colors preserve arcade energy.

## Themes

- **Isolation:** one or two small fighters are surrounded by a much larger force.
- **Escalation:** the enemy answers survival with stronger formations, elites, and bosses.
- **Defiance:** the player is never expected to win, only to keep fighting better.
- **Arcade survival:** score and survival time matter more than fictional consequences.

## Inspiration boundaries

The universe may evoke familiar space-opera and military-science-fiction feelings without reproducing protected characters, factions, silhouettes, terminology, symbols, music, or locations.

### Star Wars inspiration

Use:

- immediate starfighter fantasy and readable dogfights;
- a lone pilot facing a much larger military power;
- worn spacecraft, bright energy shots, shields, and huge capital ships;
- simple archetypes that are understood without exposition.

Do not use:

- Jedi, Sith, the Force, lightsabers, stormtroopers, or equivalent renamed copies;
- X-wing, TIE, Star Destroyer, or Death Star silhouettes;
- franchise insignia, typography, sound-alike music, or recognizable sound effects;
- the exact conflict, character roles, or visual composition of an existing film or game.

### StarCraft inspiration

Use:

- extremely clear faction and unit-role silhouettes;
- the contrast between military machinery, alien biology, and ancient technology;
- enemies whose shape immediately communicates speed, range, armor, or aggression;
- bosses and heavy units that feel much larger than common fighters.

Do not use:

- Terran, Zerg, Protoss, their unit designs, terminology, color schemes, or symbols;
- direct equivalents of identifiable units or buildings;
- interface frames or portraits that imitate the original games.

### Warhammer 40,000 inspiration

Use:

- monumental scale, armored mass, industrial ornament, and severe architecture;
- the sense that every enemy ship belongs to an ancient war machine;
- cathedral-like vertical rhythm used sparingly on capital ships and locations;
- dramatic names and silhouettes that remain readable in eight-bit pixel art.

Do not use:

- Imperium, Chaos, Space Marines, specific factions, heraldry, weapons, or terminology;
- aquilas, purity seals, faction icons, characteristic armor, or skull-covered copies;
- dense ornament that harms gameplay readability;
- grimdark lore exposition or religious language as a substitute for original design.

## Creative pillars

### 1. Arcade first

Every fiction and art decision must improve immediate gameplay readability. If a name, effect, or decorative detail needs a paragraph of explanation, it does not belong in the game.

### 2. One fighter against an armada

The player ship is small, agile, bright, and visibly outnumbered. Enemy formations and capital ships communicate scale without cutscenes.

### 3. Distinct silhouettes, original construction

Familiar roles are welcome; familiar silhouettes are not. Ships are designed from their gameplay function using this project's own shape grammar.

### 4. Dark military spectacle in eight bits

Heavy armor, spires, engine glow, large weapons, and violent explosions create grandeur while preserving the existing low-resolution, Pico-8-inspired clarity.

## Player identity

The player is simply a **lost Warden pilot**. Wardens are independent frontier protectors, but the game does not explain their order, government, training, or history. The name provides the same immediate lone-warrior fantasy as the legacy title without carrying over its specific franchise identity.

The launch craft is the **Nomad fighter**:

- silhouette: narrow spearhead body with two uneven swept fins and a square engine gap;
- construction: repaired navy armor, exposed dark frame, and bright engine conduits;
- palette: navy, cyan, warm white, and coral damage accents;
- propulsion: two cyan exhaust blades of unequal length;
- primary weapon: twin pulse cannons;
- charged weapon: plasma beam;
- side-shot upgrade: detachable side cannons;
- shield: incomplete rotating energy arc;
- player two: the same hull with mirrored markings and violet secondary light.

The silhouette must not resemble an X-wing or another recognizable franchise craft. Mechanical parity between players remains more important than fictional variation.

## Main enemy force: the Obsidian Dominion

The Obsidian Dominion is a vast militarized power that controls the hostile sectors. Nothing more needs to be established during this roadmap. It sends increasingly valuable forces because the Warden continues to survive.

Visual language:

- shape grammar: forward blades, armored wedges, vertical spines, and enclosed engine blocks;
- common fighters: compact and sharp;
- heavy ships: broad armored hulls with restrained gothic verticals;
- palette: charcoal, dark violet, bone highlights, red targeting lights, and amber engines;
- materials: worn black metal, pale armor plates, recessed machinery, and hot vents;
- emblem: three downward blades around an empty center;
- propulsion: rectangular amber flames with a hard on/off rhythm;
- projectiles: red bolts, amber shells, and magenta telegraph lines.

The Dominion combines space-opera readability with a dark industrial presence. Its ships must look like parts of the same army without copying any existing science-fiction faction.

## Enemy families

The names below are short display terms, not deep lore. Stable data identifiers appear in parentheses.

### Razor Wing (`razor_wing`)

The fast fighter family replaces the legacy TIE role and contains common fighters, interceptors, and the future dive hunter.

- base **Razor Fighter**: small split spearhead, single red cannon, direct movement;
- **Talon Interceptor**: longer side blades, triple shot, diagonal attacks;
- **Dive Hunter**: folded outer blades that open during its charge telegraph;
- motion language: fast turns, coordinated formations, and short amber engine blocks.

No unit uses a ball cockpit, vertical solar panels, X-shaped wings, or another recognizable franchise construction.

### Siege Choir (`siege_choir`)

The specialist family replaces the turret role and later supports bombers and snipers. “Choir” describes weapons firing in deliberate sequences; it does not imply a developed religion.

- base **Siege Turret**: armored wedge with a rotating central aperture;
- **Furnace Bomber**: wide hull with two visible payload bays and slow falling shells;
- **Lance Sniper**: narrow vertical spine, clear magenta sight line, and controlled retreat;
- motion language: slower patrols and strong attack telegraphs.

### Grave Fleet (`grave_fleet`)

The heavy family replaces the mother-ship role. These are old warships kept operational through layers of repair and armor.

- base **Grave Carrier**: broad asymmetric hull that deploys Razor Fighters;
- heavy sections use bone armor ribs over charcoal machinery;
- engines burn in several uneven amber blocks;
- weapons fire in large readable patterns rather than dense visual noise.

### Asteroids

Asteroids remain asteroids. They receive seeded drift, rotation, and updated original sprites, but they need no fictional renaming or faction connection.

## Additional visual families

Future variety may introduce two secondary enemy looks without requiring story development:

- **the Brood:** armored alien organisms with curved shells, exposed luminous tissue, and aggressive dive or bomber roles;
- **the Precursors:** ancient geometric machines with floating fragments, white cores, and controlled sniper or beam roles.

These directions borrow only the useful idea of strongly contrasted science-fiction armies. They are optional visual families for Phase 4 or later, not new narrative factions that require dialogue or exposition.

## Elites

An elite is simply an **Elite** or **Dominion Ace**, depending on the base unit. It is a stronger battlefield variant, not a named character.

- one-pixel bone or pale-violet outline;
- slow red pulse behind the sprite;
- one altered armor panel or brighter engine block;
- compact health bar;
- short warning tone when it enters;
- unchanged collision shape.

The single supported presentation keeps the outline, altered panel, health bar, entry tone, and pulsing aura.

## Boss: Dread Ark

The first command-carrier boss is the **Dread Ark** (`dread_ark`). It is a massive Dominion warship built from the Grave Fleet visual language.

Silhouette:

- wide armored wedge split by a central engine trench;
- three tall dorsal spines that create a monumental profile;
- two side launch bays that visibly open for reinforcements;
- bone armor ribs over dark machinery;
- no triangular Star Destroyer outline and no cathedral copied from another setting.

Phases:

- **100–66%:** aimed red volleys and Razor Fighter reinforcements;
- **66–33%:** side bays open, alternating broadside patterns, faster formations;
- **below 33%:** central trench glows white, attacks accelerate, and safe lanes narrow;
- each transition includes a brief ceasefire, visible armor movement, and a two-tone alarm.

The boss bar displays **DREAD ARK**. No biography or dialogue is required.

## Locations

Locations are visual backdrops and encounter names, not levels with written history.

- **Frontier Graveyard:** wreckage, small asteroids, distant battle flashes;
- **Crimson Veil:** red-violet nebula, reduced distant contrast, bright projectiles;
- **Dominion Foundry:** orbital machinery, furnace vents, moving industrial shadows;
- **Dead Fleet:** enormous inactive warships that provide scale behind the playfield;
- **Black Citadel:** fortified space structure used for late danger and boss encounters.

Names may appear briefly when the visual sector changes. The endless run does not stop between them.

## Gameplay terminology

Keep names direct and arcade-readable.

| Mechanical concept | Display term |
|---|---|
| Player | Warden |
| Primary shot | Pulse cannon |
| Charged beam | Plasma beam |
| Side shots | Side cannons |
| Shield | Energy shield |
| Speed upgrade | Engine boost |
| Damage upgrade | Weapon power |
| Fire-rate upgrade | Rapid fire |
| Beam-charge upgrade | Beam charge |
| Orb-attraction upgrade | Energy magnet |
| Experience orb | Energy shard |
| Repair | Repair |
| Salvage score | Bonus score |
| Danger | Danger |
| Survival time | Survival time |

Internal identifiers remain mechanical and independent from display text.

## Audio direction

- energetic four-channel or similarly constrained chiptune music;
- heroic lead melody during normal play, heavier noise percussion and bass during bosses;
- short mechanical enemy sounds and bright player weapon sounds;
- large enemies use layered low impacts without obscuring gameplay cues;
- no melodic quotation, orchestration imitation, voice sample, or recognizable sound effect from an existing franchise;
- reuse existing sounds only after provenance and similarity review.

## Interface direction

The interface is a direct arcade display, not an in-universe computer simulation.

- title, menus, gameplay, pause, and game over fill the logical viewport;
- dark metal panels may use restrained blade or spine shapes from the Dominion language;
- cyan identifies players, red or amber identifies danger, and pale violet identifies elites;
- use direct labels such as `SCORE`, `SURVIVAL TIME`, `DANGER`, and `GAME OVER`;
- avoid dense cockpit frames, lore paragraphs, faction portraits, and ornamental gothic borders;
- keyboard and gamepad focus remain obvious at Web-embed sizes.

## Narrative limits

The complete in-game premise should fit in one or two lines:

> Lost beyond the frontier, a lone Warden faces the endless armada.  
> Destroy. Upgrade. Survive.

Allowed narrative content:

- a short title-screen premise;
- enemy, boss, and location names;
- one-line boss warnings;
- survival results and high scores;
- slightly expanded store-page copy.

Not planned:

- named protagonists or villains;
- dialogue, cutscenes, missions, quests, or campaign chapters;
- faction histories, politics, timelines, or a lore codex;
- a canonical ending;
- story-dependent mechanics.

## Approval gate

Before replacement art is produced, the maintainer must approve or revise:

- the unchanged arcade survival pitch;
- **Project Lost Warden** as a working codename, without selecting the final release title yet;
- the four creative pillars;
- the Nomad fighter silhouette and palette;
- the Obsidian Dominion visual language;
- the Razor Wing, Siege Choir, Grave Fleet, Elite, and Dread Ark directions;
- the optional Brood and Precursor visual families;
- the five location directions and strict narrative limits.

Approval freezes these practical art constraints for the next phase. It does not require expanding the lore.
