# 0004. Ideas are built from units: a basic idea, its repeats, answers, sequences, fragments and cadences

Taken 2026-10-01. Stands.

## Context

"Motif will generate a short melody pattern of between 1-4 bars, Phrase will
generate either a short melody pattern, a chord pattern, or a melody and
chord pattern combined into one clip of 1-4 bars. Measure will generate a
full 8-16 bars of music." A walk that wanders for sixteen bars has no shape;
what makes music hang together is repetition with change.

## Decision

An idea is planned as a list of **units**, written `letter:bars[:cadence]`
(`gi_idea`, `I.PLANS` and `I.FORMS`):

- a letter's first appearance is **new** material;
- `a` again **repeats** it; `a'` **answers** it (the same first half, a new
  ending); `a~` **sequences** it (moved a step up or down, or to the
  dominant, chords and all);
- `f` **fragments** the basic idea - its first half, again and again, a step
  lower each time, with the chords changing twice as fast;
- `c` is a new **cadential** unit;
- the cadence is PAC (home), IAC (home, on the third or fifth), HC (a pause on
  the dominant) or open (anything but home, leading back to the start).

The plans are Open Music Theory's sentence and period, and a song's A A B A,
at the size of the idea:

- **Motif**: 1-4 bars of half-bar or one-bar cells - `a a~`, `a a'`, `a b a b'`,
  the mini-sentence `a a~ f c`. Mostly open at the end, to loop.
- **Phrase**: 1-4 bars, more line than cell - `a`, `a a'`, `a c`, the
  sentence. Mostly closing.
- **Measure**: 8, 12 or 16 bars in one of four forms - **Period** (asks, then
  answers), **Sentence** (presentation, continuation, cadence), **Song** (A A
  B A, or A A B at 12 bars), **Loop** (one progression round and round, the
  tune varied over it).

An answer keeps its source's chords **by time** up to the half-way cut, then
walks to its own ending, so its first half fits exactly as before. A repeat,
or an answer to the same ending, plays the same chords - which is what makes
a Loop's chords go round.

## Consequences

- An idea has a recognisable shape: the tests check that a Period's two
  halves start alike and end differently, that a Song's last A starts as the
  first did, that a Loop repeats its chords, that a Sentence's continuation
  changes chord faster.
- A Measure is 8, 12 or 16 bars, not every length between: phrases come in
  fours, and 9 or 13 bars would need an irregular form to make sense.
- Copying a statement onto new chords can create a repeated note or a leap,
  so a last pass (`I.untangle`) is needed and tested.

## Alternatives

**One long walk for the whole idea.** Rejected: no repetition, so nothing to
remember, and a sixteen-bar walk drifts.

**Separate generators per kind.** Rejected: the three kinds are the same
craft at three sizes; one planner with three sets of templates keeps them
consistent and tested together.
