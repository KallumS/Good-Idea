# 0017. The tune takes figures too: its quarters and halves, not only its eighths

Taken 2026-10-01. Stands. Widens [0010](0010-figures-push-and-swing.md);
balances [0015](0015-chord-rhythm-figures-and-one-and-a-half.md).

## Context

"The figures section with Any/ Plain/ Dotted/ Triplets/ Mixed options now
only seems to affect timing of the chords and not melody (opposite to how it
was working before) - is it possible for it to affect the timing of both at
the same time without breaking the script?"

The tune never stopped taking figures, but it took them rarely. A figure
falls only on a beat of the right shape - two eighths in a beat, or two
quarters across two beats - and a tune at a Calm or Flowing pace is mostly
lone quarter notes and half notes, which neither shape touches. Measured
over 300 ideas each, with Triplets, about one beat in seven of the tune was
a triplet against nearly two in five of the chords (which play on almost
every beat, so almost every beat has a shape to figure), and about a third
of Motifs and Phrases had no figure in the tune at all. Since 0015 gave the
chords figures, they drowned out the tune's.

## Decision

**In the tune, a quarter note and a half note take figures too.** In
`I.figure`, with `tune` set (only `I.cell`, the tune's rhythm, sets it):

- a quarter note on the beat, with a note on the next beat, becomes a dotted
  eighth and a sixteenth (Dotted) or an eighth-note triplet (Triplets);
- a half note on the beat, with a note two beats on, becomes a dotted
  quarter and an eighth (Dotted) or a quarter-note triplet (Triplets);
- Mixed does either, at about half the odds of each.

The odds (`qdot`, `qtri`) were set by measuring: with Triplets about a
quarter of the tune's beats are now triplets (from about a seventh), and
about two Phrases in three have triplets in the tune and the chords at
once (from about two in five). Notes held over the bar, the long notes of a Calm tune and a
syncopated tune's own long-short lilt (3+3+2) are left alone: they are
figures of their own.

## Consequences

- Version 1.4. With Figures on Plain nothing is drawn, so 1.0's ideas and
  every Plain idea are unchanged. With figures on, the tune's rhythm is new
  (more dice from its rhythm stream). The chords, bass and drums draw from
  their own streams, and their rhythm is exactly as in 1.3 (checked over
  900 figured ideas). The bass and drums are note for note 1.3's; the
  chords are voiced to sit under the tune's lowest note, so where a figure
  gives the tune a new lowest note, about one idea in nine, they move to
  stay under it.
- The extra notes are made before the tune is walked, so they are pitched
  by the same rules as every other note: passing notes off the beat, chord
  tones on it, whole triplets only.
- The tests check each new shape exactly, that Plain and the chords are
  untouched by it, that with Triplets most phrases have triplets in the tune
  and the chords at once, and that a fifth or more of the tune's beats are
  triplets. The 1.3 engine fails four of these six checks: all but the two
  that say what must not change.

## Alternatives

**Fewer figures in the chords.** Rejected: the ask was for both at once, and
the chords' figures were liked.

**Guarantee a figure in every tune.** Rejected: a short Calm tune with one
long note has nowhere for a figure to go without stopping being calm; the
dice decide, among the places a figure fits.

**Figures on the syncopated beats too.** Rejected: an off-beat syncopation
is already a rhythm figure, and a triplet over it blurs both.
