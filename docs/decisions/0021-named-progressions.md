# 0021. Named progressions

Taken 2026-10-02. Stands. Widens [0006](0006-chords-stay-in-the-key.md)
(a named progression may take a chord from the parallel scale, as the
lament's VII and the double plagal's bVII do) and
[0004](0004-ideas-are-built-from-units.md) (a unit's chords may come from a
list rather than the walk).

## Context

The third part of "add everything they suggest adding" (`docs/READING.md`,
first section). Good Idea's chords have always been a walk: each drawn from
the one before by how strongly it leads there. The books also teach chords
as stock patterns a listener knows by ear:

- Open Music Theory's pop/rock pages: the **doo-wop** progression (I vi IV
  V), the **singer-songwriter** (vi IV I V), **Puff** (I iii IV I), the
  **lament** or Andalusian cadence (i VII VI V), the **circle of fifths**,
  the **double plagal** (I bVII IV I), and the **12-bar blues** with its
  8- and 16-bar cousins.
- **Pachelbel's canon** (I V6 vi iii6 IV I6 IV V), named on the same pages
  and in Hutchinson's chapter on sequences.
- Gjerdingen's **galant schemata**, summarised on Open Music Theory's
  "Galant schemas" page: the **Meyer** (I V4/3 V6/5 I, the bass do re ti
  do) and the **Prinner** (IV I6 vii6 I, the bass fa mi re do).

The books agree on what each progression is, so nothing needed asking.

## Decision

**Progression** (Chords step; last in `I.SETTINGS`, so older ideas keep
their dice): Walk (the default, as before), Any named, or
one of nine by name. No Any button: Walk is how Good Idea has always
worked, and Any named is the way to leave the choice to the idea number.

- A named progression **fills the chords a unit walks to, in order, going
  round**: a unit with four chords at the start of an idea plays I vi IV V;
  the next new unit carries on from where the list got to. Where a unit
  closes, its cadence's chords still end it (two for a full close, one for
  a half close), so the progression gives way to V-I at the end, as songs
  do. A **repeat carries the progression on** (its tune copied and
  fitted to the chords now under it, as songs repeat a line over the next
  chords) until the progression has come round to where the repeat's
  source began; then it copies, as before. So a sixteen-bar Loop of
  four-bar statements at a chord a bar plays all eight of Pachelbel's
  chords, then all eight again, and a Loop at a chord every two bars still
  reaches doo-wop's F and G. An answer's first half and a sequence copy as
  before.
- Each chord is a **degree** of the key, with the **scale it comes from**
  when it is not the key's own (the lament's VII and VI from natural minor,
  its V from harmonic minor; the double plagal's bVII from Mixolydian) and
  the **scale degree in its bass** when it is inverted (Pachelbel's V6, the
  Meyer's V4/3 and V6/5, the Prinner's I6 and vii6). The bass is played as
  written, and the chord line writes it G/B.
- A named chord is the progression's: it is **not inverted, borrowed or
  made applied** by those settings. It may take a **flavour** (with Mixed),
  but only one that keeps its bass note - G(add9)/B, never Gsus4/B.
- The Meyer's V4/3 and V6/5 are the same chord with the bass moving, so
  they are **not merged into one held chord**, as the same chord twice
  running otherwise is.
- **The blues** is a chord a bar by where the bar is in the idea - I I I I
  IV IV I I V IV I I over twelve bars, I V IV IV I V I I over eight, and over
  sixteen eight bars of I, then the last eight of the twelve. Measures only.
  The blues plays its own changes: where the form asks for a close, the
  tune lands on a note of the chord the blues has there (a deceptive close
  has no vi to go to).
- A progression is offered only where it means what it says: in a
  seven-note scale, in its mode (doo-wop, Puff, Pachelbel, double plagal
  and galant in major keys; the lament in minor ones; the singer-songwriter
  and the circle in both). Chosen where it does not suit, the chords walk
  as usual and the summary line says why ("walked (Lament needs a minor
  key)"). **Any named** picks, by the idea number, among the ones that
  suit the key, from a dice stream of its own (`schema`).

## Consequences

- Version 1.9. Walk draws nothing new, so every 1.8 idea number is the same
  idea with Walk, and every 1.0 idea number is still the 1.0 idea with the
  other settings plain.
- In a Sentence the second statement is a sequence, moved to another
  chord: the named progression is heard in its first statement and its
  continuation. The hint says a Loop or a Song shows it best.
- How much of an idea the progression fills (200 C major Measures, the
  doo-wop): every chord of a Loop, which always opens I vi IV; about two
  thirds of a Period's or a Sentence's chords; half a Song's, whose
  cadences and sequences are its own. Any named, over 400 ideas half in
  major and half in minor, chose each of the nine, only where it suits.
- The sweep plays every third idea with a named progression (or Any named)
  and checks every chord, note and bass as it does the walk's; it also
  checks that every chord's bass note is one of its notes.

## Alternatives

**Every galant schema** (the Romanesca, the Fonte, the Monte, the Do-Re-Mi,
the Quiescenza ...). Not done: the Meyer and the Prinner are the pair Open
Music Theory teaches first and the two most common openings and answers of
the style; the others can be added the same way, as a list of degrees and
basses.

**A named progression as a separate kind of idea.** Rejected: the tune, the
rhythm, the form and the bass all work as they do over the walk, so it is a
choice of chords, in the Chords step.
