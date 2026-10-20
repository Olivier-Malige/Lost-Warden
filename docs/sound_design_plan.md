# Sound Design — Suno Production and Godot Integration

## Phase 3 selection moment — brief verified 2026-10-20

The maintainer requests a rewarding level-up opening and special transition/selection music, and will provide all music and sound effects. The [Phase 3 contract](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/contract.md#selection-audio) suggests an energetic 0.5-0.8-second sting and a compatible restrained space/synthwave loop targeting 20-30 seconds before musical-boundary editing. The requested file checklist is a level-up sting, selection loop, navigation cue, confirmation cue and return accent, with source/master files and intended loop points where available. No dedicated selection or XP-collection audio files have been supplied. Steps 1-4 now provide a playable foundation: the native screen temporarily uses existing menu cues, with tested local music pause/resume, loop-copy handling and null streams. The earlier interactive preview remains silent. Dedicated audio integration/listening remains pending.

The maintainer approved the preview and requested implementation on 2026-10-20. The [local selection audio brief](../aidd_docs/tasks/2026_10/2026_10_19_phase_3_survival_builds/selection_audio_brief.md) records the file checklist, proposed master/runtime destinations, existing menu cues and exact integration/listening gates. No new audio file has been produced or imported; XP collection's optional stream is null by default and owned outside recycled orbs.

No generation prompts or Suno production are required for these selection assets. The agent preserves supplied masters and handles technical import, loop-boundary preparation, matched levels, Music/Sounds routing, runtime Ogg/WAV exports and Godot integration. Prototype music is optional; visual review and choices must work without audio. Later integration tests may use existing UI cues and a null loop. Final audio acceptance requires the supplied assets and maintainer listening approval, or an explicit deferral. The historical audio workstream below retains its own workflow.

Use one local musical session per contiguous batch of queued levels, shared across co-op players. Pause and resume the same gameplay player at its previous position. Musical assets use Music, UI cues use Sounds; muted, missing or browser-blocked audio never delays choices. Keep the global MusicDirector and unrelated screen/encounter music outside this Phase 3 addition. Future audio design must use current encounter/time progression rather than silently reviving the historical wave mapping below.

## Continuous title and hiscore music — 2026-10-12

The main screen controller owns one `TitleMusic` player on the `Music` bus. Opening hiscores or returning to the title keeps its current playback position and audio volume. The return retains its visual fade without an audio fade; other screen transitions retain their audio fades, and starting gameplay stops title music during the existing screen fade. The title scene no longer owns an autoplay player. `tests/test_screen_fades.gd` verifies uninterrupted hiscore playback, stable volume throughout the return, visual fade completion and gameplay handoff; both that suite and `tests/test_start_screen.gd` pass in Godot 4.7.2 headless.

## Pickup announcement shortening — 2026-10-12

Maintainer-requested edit of the six current pickup WAVs: remove the final "up" by cutting at the preceding low-energy word boundary, apply an 8 ms fade and append 25 ms of silence. Preserve existing resource paths, stereo 44.1 kHz float32 encoding, import settings and queue behavior. Current durations: laser 0.675 s, shield 0.640 s, side shots 0.985 s, speed 0.600 s, health 0.545 s and plasma energy 1.210 s.

Godot imports and the pickup-audio routing/queue regression pass. Cuts were located from waveform activity; subjective listening confirmation of each word ending remains pending because audio input is unavailable in this agent session. Original files are retained locally under the ignored `.godot/pickup_audio_originals/` directory for adjustment.

## Direction and workflow

Plan revised: 2026-09-29. Phase 1 prompt catalog prepared; Suno generation and Godot implementation have not started. This is the dedicated Sound Design phase of the [gameplay roadmap](gameplay_rework_plan.md); complete and verify each requested subphase before starting the next.

The maintainer uploads an audio reference to Suno and selects the generated results. The agent prepares English prompts and handles technical preparation and Godot integration. No preliminary listening report, tempo analysis, or key analysis is required before writing prompts. Check timing and loop boundaries after generation, using the selected exports.

The maintainer has an active Suno Pro subscription. Prompt preparation and music generation can proceed.

## Phase 1 — Prepare the prompts

The generation prompt catalog was retired during the audio cleanup on 2026-10-11. The retained runtime music is `Retro-Futurist Drive.mp3` for gameplay, `loader.ogg` for loading, `title.mp3` for the title screen, and `gameover.mp3` for game over. Temporary generation tools and unused source tracks were also removed.

| Asset | Direction |
| --- | --- |
| Gameplay | Retro synthwave / 8-bit, several synth and electric guitar solos, developments and breathing sections |
| Loader and title | A separate shared atmospheric theme, less rhythmically dense, with pads, spacious arpeggios, and discreet percussion |
| High scores | A brighter, relaxed variation of the atmospheric theme |
| Game over | Immediate defeat punctuation followed by a melancholic variation of the gameplay theme |
| Musical bridges | Loader → title, title → gameplay, title ↔ scores, gameplay → game over, and game over → title |
| Sound effects | UI navigation/confirmation/back/launch; player and enemy shots, hits and explosions; asteroids; shield reflection; beam start/loop/stop; pickup cues |
| Robotic announcements | “Speed up!”, “Damage up!”, “Fire rate up!”, “Side shot!”, “Shield up!”, “Energy up!” |

Use a hybrid arcade sound-effect palette. Announcements share one clear, lightly vocoded robotic voice, spoken rather than sung, approximately one second long, without background music. Each prompt states its purpose, desired character, approximate duration, and whether it should loop. Request distinct musical sections and short transitions without requiring measured BPM or key at this stage.

Done: prompts were prepared for the music, transitions, existing effects, and six announcements.

## Phase 2 — Generate and select in Suno

- The maintainer supplies an audio reference, requests the planned modifications, and iterates on the results using the approved musical direction.
- Start with the extended gameplay remix, the atmospheric theme, and one robotic announcement. Once their direction works, produce the remaining variations, bridges, effects, and voices.
- Keep the gameplay melody recognizable, with synth and guitar solos and alternating intensity. Keep menu music atmospheric while retaining a compatible sound palette.
- Export the chosen results as WAV, keeping stems when available and useful for editing. The maintainer validates the musical choices by listening.

Done when: the selected music and sound library cover the requested assets. Exact loops and final joins are prepared next, rather than assumed to be perfect from generation alone.

## Phase 3 — Prepare the game audio

- Check the selected exports' actual tempo and musical boundaries; align or edit them as needed for reliable joins. Determine key compatibility when preparing bridges between themes.
- Split gameplay into loopable sections: main theme, development, synth solo, breathing section, guitar solo, and intense reprise. Keep the complete 6–8 minute arrangement separately.
- Prepare short screen bridges, clean loop points, matched levels, and preserved reverb tails. Solos lead into accompaniment loops instead of repeating constantly.
- Use Ogg Vorbis for game music and WAV for short effects; retain source masters. Store assets under `assets/audio/` with snake_case filenames.

Done when: timing checks pass and the maintainer confirms that loops and transitions have no unwanted gaps, clicks, or obvious musical clashes.

## Phase 4 — Integrate and verify in Godot

### Continuous music

Use one persistent `MusicDirector` under the main scene, with `AudioStreamInteractive` for premixed sections and beat/bar-based transitions. Store the music configuration under `data/audio/`, and the component under `scenes/audio/`. Remove the separate screen music players when the replacement is ready. Runtime stem mixing is not required for this version.

Main remains responsible for screen changes. The music component accepts screen-state and wave requests and reports actual section entry. Reuse existing `Events` notifications, including `wave_changed`.

- Confirm menu input immediately, then synchronize the visual screen change with the musical join. Keep screen transitions short; do not wait for a complete solo.
- Loader completion and skip share one transition path. Adapt the loader presentation to the chosen introduction.
- On defeat, stop gameplay immediately, play the impact, and transition into the melancholic theme on the next suitable beat.
- Pause reduces music volume; resume restores it. Restart clears pending transitions and voices. Prevent duplicate navigation requests.
- If music is muted, missing, or blocked by browser autoplay, screen navigation must still complete.

### Wave progression

Use an editable mapping, without changing wave durations:

| Waves | Music |
| --- | --- |
| 1–3 | Main theme |
| 4–6 | Development |
| 7–9 | Synth solo |
| 10–12 | Breathing section |
| 13–15 | Guitar solo |
| 16–18 | Intense reprise with synth/guitar dialogue |

Switch at prepared phrase boundaries, retain only the latest pending wave request, and do not restart an already active section. Endless cycles reuse the mapping. Defeat and screen exits take priority over wave changes.

### Effects and announcements

Preserve the `Music` and `Sounds` controls and route a `Voice` sub-bus through `Sounds`. Play pickup effects immediately, serialize announcements without overlapping voices, and discard stale or duplicate queued announcements. Keep voices independent of pickup node lifetime. Capped upgrades must not announce an increase that did not occur. Limit repeated effects and ensure beam audio stops correctly.

### Requested XP pickup cue — 2026-10-20

The maintainer requested audible XP collection during the playable review. `assets/sources/audio/xp_orb_collect.py` reproducibly exports the agent-authored `assets/audio/sfx/pickups/xp_orb_collect.wav`: 75 ms, 44.1 kHz mono PCM16, short rising electronic ping with a tapered envelope, zero endpoints and peak -16.6 dBFS. The XP pool defaults to this cue at -2 dB on Sounds; orbs worth four or more XP use x1.12 pitch. A 60 ms interval coalesces dense bursts and max polyphony two bounds overlap without suppressing XP credit. The pool-owned player can finish during level-up pause and stops on run cancellation. This is the requested playable prototype; the maintainer may replace it with a supplied master and final listening approval remains pending. Selection sting/loop delivery and the broader MusicDirector workstream are unchanged.

### Acceptance

Verify desktop and Web: complete/skipped loader, solo/co-op launch, scores and return, defeat during a solo, return to title, pause/resume/restart, mute/unmute, blocked autoplay, rapid debug wave changes, and endless cycles. Check simultaneous and capped pickups, voice clarity during combat, beam cleanup, and repeated loops. Use focused automated checks for mappings and transition/queue behavior, plus listening validation by the maintainer.

Deliver the prompt catalog, selected masters and game exports, integrated Godot audio, and a short validation report. Keep unrelated gameplay phases and existing user edits outside this work.
