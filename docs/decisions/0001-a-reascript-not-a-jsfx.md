# 0001. A ReaScript, not a JSFX

Taken 2026-10-01. Stands.

## Context

"I want to create a ReaScript that generates good ideas for when starting a
new track." The request named a ReaScript, and every sister repo (Starting
Blocks, Midi Suggester, Midi Variator, Midi Catalogue, ScaleView) has
already argued the alternative.

## Decision

A Lua ReaScript with a ReaImGui window, built like Midi Catalogue.

- **The idea has to land in the project.** Inserting items, making a track
  per part for a Measure, writing a .mid - a script has the API for all of
  it. A JSFX cannot write a file, reach the REAPER API or create tracks.
- **There are many settings.** Every one of them had to be in the window;
  ReaImGui gives rows of buttons with tooltips, a JSFX gives sliders and a
  hand-drawn `@gfx` section.
- **The music has to be testable.** The engine is plain Lua, run and checked
  outside REAPER - over half a million checks in `tools/test.sh`, millions in
  the deep sweep. EEL2 only runs inside REAPER.

## Consequences

Ideas are made when asked for, not live as the music plays. A generator that
reacts to incoming MIDI would be a different tool; nothing asked for needs
it.

## Alternatives

**JSFX.** Rejected for the reasons above; all five sister repos reached the
same answer.
