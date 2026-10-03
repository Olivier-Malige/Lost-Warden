# Sound Design — Suno Production and Godot Integration

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

### Acceptance

Verify desktop and Web: complete/skipped loader, solo/co-op launch, scores and return, defeat during a solo, return to title, pause/resume/restart, mute/unmute, blocked autoplay, rapid debug wave changes, and endless cycles. Check simultaneous and capped pickups, voice clarity during combat, beam cleanup, and repeated loops. Use focused automated checks for mappings and transition/queue behavior, plus listening validation by the maintainer.

Deliver the prompt catalog, selected masters and game exports, integrated Godot audio, and a short validation report. Keep unrelated gameplay phases and existing user edits outside this work.
