# Selection audio handoff and integration brief

Step 1, 2026-10-20. The maintainer supplies **all music and sound effects** and approves the result by listening. The agent owns technical preparation and Godot integration. No generation prompts, Suno work or unrelated soundtrack replacement is required.

## Files to provide

Names and durations are suggestions, not input-format restrictions. Preserve each supplied master unchanged; record its real filename, format, destination and any edits when it arrives. Source projects/stems and intended loop points are useful when available, not prerequisites for a visual build.

| Asset | Suggested content | Proposed runtime destination | Bus |
| --- | --- | --- | --- |
| Level-up sting | Energetic 0.5-0.8 s accent; leaves room for the selection loop | `assets/audio/music/selection/level_up_sting.ogg` | Music |
| Selection loop (optional for prototype) | Restrained space/synthwave, approximately 20-30 s before boundary editing; supports a long choice | `assets/audio/music/selection/selection_loop.ogg` | Music |
| Navigation cue | Short, clear cursor movement; suitable for repeated independent co-op input | `assets/audio/sfx/ui/upgrade_navigate.wav` | Sounds |
| Confirmation cue | Distinct final choice acknowledgement | `assets/audio/sfx/ui/upgrade_confirm.wav` | Sounds |
| Return accent | Short accent into resumed combat | `assets/audio/music/selection/selection_return.ogg` | Music |

Proposed retained-master location: `assets/sources/audio/selection/` with original filenames and formats. Do not create empty placeholder media or treat these proposed paths as received assets.

## Current files and missing inputs

Dedicated sting, loop, navigation, confirmation and return files: **not supplied**. The approved interactive preview is silent. Existing `assets/audio/sfx/ui/menu.wav`, `menu_select.wav` and `menu_start.wav` may support later routing checks, but cannot be marked dedicated selection audio. Retain current gameplay music `assets/audio/music/Retro-Futurist Drive.mp3`; do not repurpose title/game-over music.

Step 4 delivery update: the playable native selection now uses menu.wav for navigation and menu_select.wav for confirmation. Local pause/resume, one session, independent mutes, null streams and non-mutating Ogg loop copies are tested. No dedicated sting/loop/return is assigned. XP collection's optional stream remains null and is owned by the pool's separate audio player; a test-only existing cue verifies survival across orb recycling. Masters/destinations remain unfilled until actual files arrive.

The world owns `music` in `scenes/world/world.tscn`, routed to Music. `core/global.gd` independently mutes Music/Sounds through the saved options. Preserve that behavior. `main._fade_to` changes Master volume and temporarily changes audio processing for screen navigation: do not reuse it for level-up audio.

## Agent preparation and local runtime contract

1. Inventory the received masters and retain originals. Inspect format, sample rate, channels, peak/clipping and useful boundaries. Prepare Ogg Vorbis music and WAV effects as needed; avoid unnecessary lossy re-encoding.
2. Prepare loop boundaries and retained effect/reverb tails, compare levels with gameplay/UI audio, and record export settings and edits. Do not infer musical acceptance from waveform inspection.
3. Use the planned local `scenes/ui/upgrade_selection_audio.gd` component. At selection opening, preserve the same gameplay player's playback position and pause its stream; resume that player at its saved position after selection. Do not stop/restart from zero or introduce a global MusicDirector.
4. Start one sting/loop session for the entire contiguous queue of levels, shared by both players. The second confirmation or next queued level must not restart it. Run the selection streams while gameplay is paused; suppress combat audio without unmuting Music/Sounds or changing Master.
5. Navigation/confirmation use Sounds, musical assets including return use Music. Muting either bus must not alter the other. Missing, null, muted or browser-blocked streams must never delay card interaction, confirmation, level changes or resumption.
6. Menu/debug overlays preserve the pending audio/choice batch. Restart, death-driven cancellation and world removal cancel local tweens/callbacks; actual screen transitions retain their own ownership. Audio callbacks cannot reopen or resume a removed run.

## Acceptance

Step 3 may exercise the local component silently with null streams and use existing menu cues for technical checks. Step 14 still requires received files plus maintainer listening acceptance, or an explicit deferral of the missing item. Verify independent mutes, no unwanted clicks/gaps at loop boundaries, acceptable repeated cues, one session across queued levels and seamless gameplay-position restoration. Record actual listening feedback separately from automated results. Audio availability never blocks visual review or working choices.
