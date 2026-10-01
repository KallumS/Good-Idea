# 0015. Figures reach every chord style and the walking bass; 1.5 chords a bar, chosen not rolled

Taken 2026-10-01. Stands. Widens [0010](0010-figures-push-and-swing.md).

## Context

"The figures section with Any/ Plain/ Dotted/ Triplets/ Mixed options only
seems to affect timing of the melody and not chords." In 1.1 figures fell on
Pulse chords (only where a beat had exactly the right notes in it) and
Broken chords (triplets only); Block chords, the commonest, were untouched.

And: "Could we add 1.5 a bar to the chord pace?"

## Decision

**Figures, for every chord style:**

- **Block**: a held chord now and then takes stabs - struck again a dotted
  quarter in (the Charleston: 1 and the "and" of 2) with Dotted, or three
  times across two beats (a quarter-note triplet) with Triplets.
- **Pulse**: as in 1.1, the figures laid over each bar's pulse.
- **Broken**: with Triplets the arpeggio rolls in eighth-note triplets; with
  Dotted (or Mixed) the figures fall on the arpeggio itself, long-short.
- **A Moving bass** takes them too: dotted quarter and eighth, or a triplet.
- The Phrase's root in the bass and the held and pulsing basses stay plain,
  to anchor the rhythm.

**1.5 a bar**: three chords to two bars, which on the beat grid of 4/4
falls as 3+3+2 (or 3+2+3) beats - the rhythm of so much pop harmony. It is
in the Chord pace row between One and Two. **Any does not roll it**: Any
rolls Slow, One and Two with 1.0's weights, so a 1.0 idea number still rolls
the same chord pace. Like the colour scales, it is there to be chosen.

## Consequences

- With Figures on Plain nothing changes: no dice are drawn for them.
- The tests check each style takes the figures it should and none when
  Plain, that 1.5 a bar lays 3+3+2, and that Any never rolls it.

## Alternatives

**Let Any roll 1.5 a bar.** Rejected: every 1.0 idea with the chord pace on
Any would have rolled a different pace.

**Figures on every bass style.** Rejected: something has to hold the beat
still for the figures to be heard against.
