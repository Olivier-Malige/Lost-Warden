# Console diagnostics — 2026-10-21

Godot 4.7.2, isolated addon-free project using the current workspace sources.

## Reproduction and correction

- The local game logs contained no runtime errors. The editor MCP session was disconnected, so diagnostics were collected through a private local Godot language server.
- The initial scan found 11 warnings in the 83 game scripts: shadowed names, an orb reference read before explicit initialization, a discarded integer remainder, and ambiguous nested local declarations.
- Workspace analysis also reported three test parse errors comparing resource array properties with packed arrays. Normalize the tested values to the expected packed type before comparing, preserving exact assertions.
- Opening those three tests exposed seven additional warnings. Replace incompatible ternaries with typed branches, initialize the side-shot reference, remove an unused binding, and disambiguate nested locals.
- No warning suppression or gameplay balancing changes were added.

## Verification

- Fresh language-server analysis: 86 diagnostic documents (83 game scripts and three corrected tests), zero errors or warnings.
- Native OpenGL tests: micro-missiles 458, piercing beam 118, energy chains 144, XP orbs 30, upgrade selection 48, elimination HUD / critical feedback 25 checks; all passed with clean exits (823 checks total).
- `git diff --check` passed.

This verifies the reproduced script diagnostics and selected runtime paths. It does not certify messages from an unavailable editor session, local addons, or every possible gameplay scenario.
