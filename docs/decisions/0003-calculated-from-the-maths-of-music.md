# 0003. Calculated from the maths of music, not drawn from a library

Taken 2026-10-01. Stands.

## Context

"This won't be based on a library of midi, but rather generated
mathematically as music IS math." And: "The hardest thing in music is
starting a track" - so what comes out has to be worth starting from, not
noise.

Random pitches and durations are maths too, and they are exactly what makes
generators sound random. The question was which maths.

## Decision

Each part of an idea is made by a piece of maths that music theory already
uses to describe what works, with the dice choosing only among what it
allows:

- **Rhythm: the metric grid and Euclidean rhythms.** A straight rhythm takes
  the k strongest steps of the bar (downbeat, half bar, beats, half beats).
  A syncopated one spreads k notes over n steps as evenly as possible
  (Bresenham's line, the same patterns as Bjorklund's algorithm) and turns
  it off the beat - the tresillo is 3 in 8, the cinquillo 5 in 8 (Toussaint,
  "The Euclidean algorithm generates traditional musical rhythms").
- **Harmony: a weighted walk (a Markov chain) over tonic, subdominant and
  dominant.** The weights are Open Music Theory's "idealised phrase" written
  chord by chord: V mostly home or to vi, ii mostly to V, vi on to ii or IV.
  Endings are fixed cadences, and when the dice cannot reach one, the
  likeliest path is found exactly (Viterbi's algorithm).
- **Melody: a weighted walk over scale steps, pulled toward a contour.**
  Steps likeliest; a bell curve around where the contour is; chord tones on
  the beat; a leap filled by a step back; an arch peaking at the golden
  section (0.618 of the way).
- **Form: units** - see [0004](0004-ideas-are-built-from-units.md).

All of it works in scale positions, so "a third above" is +2 in any scale,
and pitches appear only at the end.

## Consequences

- Every idea is in the key, on the chords, ends properly, and is playable;
  the tests check each of those on every note of hundreds of ideas.
- The weights are judgement, set by reading `tools/demo.lua` output. Changing
  one means reading the demo again and running the deep sweep.
- What comes out is a starting point in a common-practice and pop idiom.
  Atonal or microtonal ideas would need different maths.

## Alternatives

**A library of MIDI, transposed.** Rejected by the request itself.

**Uniform random notes in the scale.** Rejected: in the scale is not the same
as musical, and filtering random notes afterwards wastes most of what is
rolled.

**A trained model.** Rejected: it would be a library by another name, could
not run inside a ReaScript, and could not be reasoned about or tested rule by
rule.
