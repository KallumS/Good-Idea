# 0002. An idea is a number: chance, but reproducible

Taken 2026-10-01. Stands.

## Context

"There should be a New Idea button on the UI that generates a new clip of
the selected type at random." But the house has argued against randomness
before: Midi Catalogue's [0002](https://github.com/KallumS/Midi-Catalogue/blob/main/docs/decisions/0002-calculated-from-choices-not-stored-or-random.md)
rejected random generation as "not reproducible", and its user had
complained that other tools are "too random and not musical". Here a button
that gives something new every press is the point, so the catalogue's answer
(enumerate every combination) does not fit: a Measure has far too many
combinations to list, and nobody browses a list when starting a track.

## Decision

Chance, made reproducible. **Every idea has a number** (1 to 99,999), and an
idea is a pure function of the settings, the project's metre and that number:
`I.make(st, meter, seed)`. New Idea draws a new number from the clock; the
dice are Midi Variator's fixed Park-Miller generator, seeded from it, so the
same number gives the same numbers on any machine and any Lua.

The window shows the number, lets you type one, and keeps the ones made this
session so **<** and **>** step back and forward.

Two refinements make the number worth having:

- **Each part of the idea draws its own dice** (`I.stream(seed, name)`: the
  plan, the harmony, the rhythm, the melody, the chords, the bass, the
  drums). So changing how the chords are played does not change the tune, and
  turning the drums off does not change the bass.
- **The tune's range is counted from the tonic** (`I.melodyRange`), so the
  same idea in another key is the same tune, moved, note for note.

Together they mean a setting can be changed without losing the idea: idea
4821 in D minor, busier, with sevenths, is still idea 4821.

## Consequences

- An idea can be written down and found again; a bug report can name one.
- The tests can check any idea exactly, and do: the same number is the same
  idea, a hundred numbers are a hundred ideas, a key change moves the tune.
- 99,999 ideas for each combination of settings. The range is kept to five
  digits so the number is easy to read out and type.
- Changing a setting that the melody depends on (the chords under it, the
  pace) does change the melody - the number keeps everything else.

## Alternatives

**Unseeded randomness** (`math.random`). Rejected: an idea you liked and lost
could never be found again, and the tests could only check properties, never
a particular idea.

**Enumerate every combination, as Midi Catalogue does.** Rejected: the
request is for a button, not a list, and a Measure's combinations are beyond
listing.
