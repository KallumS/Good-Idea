# 0008. Velocity is 100; accents rise above it

Taken 2026-10-01. Stands.

## Context

The request said nothing about velocity. Midi Catalogue's user asked for
"all velocity at 100" for simplicity, and also for velocity patterns; its
[0005](https://github.com/KallumS/Midi-Catalogue/blob/main/docs/decisions/0005-velocity-100-accents-above-it.md)
reconciled the two.

## Decision

The house rule, kept. Everything leaves at 100. One **Velocity: Flat /
Accents** setting, Flat by default, raises the accented notes - bar
downbeats, the first note of each unit of the idea (and each fragment), the
kick on 1, the snare's backbeat, the crash - to 115 and leaves every other
note at 100.

## Consequences

- The tests check that nothing leaves at anything but 100 unless Accents is
  chosen, and then only 100 and 115.
- No ghost notes on the snare and no velocity shaping of the hats: dynamics
  are the piano roll's job, once the idea is in.

## Alternatives

**Humanised velocities.** Rejected: a starting point should be clean to edit,
and the sister repos agree.
