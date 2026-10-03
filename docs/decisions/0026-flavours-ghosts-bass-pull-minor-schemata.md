# 0026. Flavours with every colour, Drop 4, ghost notes, the bass lying back, the galant schemata in minor, and a truck driver that changes gear

Taken 2026-10-03. Stands. Widens [0018](0018-flavours-voicings-and-inversions.md)
(flavours with Triads and Sevenths; a ninth voicing),
[0013](0013-drums-are-a-kind-of-idea.md) (ghost notes),
[0014](0014-pull-the-chords-lie-back.md) (the bass may lie back too),
[0021](0021-named-progressions.md) and [0025](0025-the-engine-decides-more.md)
(the galant schemata in minor) and [0024](0024-sixnine-power-and-key-change.md)
(the truck driver into the tonic).

## Context

After 1.13 the user said yes to six of the things CLAUDE.md had left open:
a separate Drop 4 voicing, flavours for Triads or Sevenths, ghost notes in
drum ideas, pull for the bass, minor-key versions of the galant schemata,
and a truck-driver key change that did not fall back to a plain step up in
about a third of Measures. (And a seventh, out-of-key colour chords: 0027.)

## Decision

**Flavours with every colour.** The Flavours row shows with Triads and
Sevenths as well as Mixed. Each flavour is offered only where it is the
real thing (as 0018 had it), and only where it fits the colour: a triad
takes a sus4, sus2, add2, add9 or 6 (a 6/9 half the time) - not the
diminished seventh a third up, which is a seventh chord; a seventh chord
keeps its seventh (sus4 becomes 7sus4, 9) or trades it for a 6 (C6 for
Cmaj7, as jazz players do), or becomes the diminished chord on its third -
never a sus2 or an added note, which would drop the seventh. Same rates as
Mixed, same dice.

**Drop 4.** A voicing: four notes in close position with the lowest dropped
an octave - three close notes over a gap. Chosen, not rolled by Any (which
still rolls the seven 1.5 had).

**Ghost notes** (Drums step: Off / Rare, the default / Common; dice of their
own, `ghost`): the snare tapped very quietly (velocity 38, at any Velocity
setting) on the weakest places in the bar - the sixteenths between the
eighths, or in a shuffle the middle note of the triplet - most often just
before or after the backbeat (a place away from it is a third as likely).
Never where the kick or the snare plays, never in a fill. Chosen once for
the idea, so every bar has the same. Common keeps Rare's and adds.

**The bass lying back** (hidden: the engine decides, half and half, on the
pick dice): where the chords are pulled, the bass either stays on the beat
with the tune (as since 1.2) or lies back with them - the new note an eighth
late, where the chord comes, the note before held to meet it, anything it
played inside that eighth gone. The tune is the same either way.

**The galant schemata in minor.** Open Music Theory: "though these schemata
are presented in major mode, most of these can be converted directly to
minor mode" ("Galant schemata - summary"). So: the Meyer and Prinner as i
V4/3 V6/5 i, iv i6 vii°6 i (the V and vii°6 from the harmonic minor, the iv
from the natural); the Romanesca as i v6 VI i6, the bass do te le me - the
natural minor's v6, as a falling line in minor takes it (the harmonic
minor's raised ti falling to le would be an augmented second); the Monte as
V7/iv iv V7/V V. The Fonte is the one that cannot be converted directly: in
major it falls from ii (tonicised) to I, and the minor key's ii is
diminished - no key of its own. So in minor it falls from iv to III a step
below (V7/iv iv V7/III III: Fm then Eb in C minor) - minor then major, a
step down, as in major. A named progression's chords in minor are taken
from the scale they name (`from`), so a Dorian or Phrygian key plays them
as in natural minor.

**The truck driver changes gear.** It needs the new key's tonic to arrive at
the change (0024). Where no section in the second half starts on the tonic,
the latest that can is made to: its first chord becomes the tonic - unless
that would take a chord its close needs (two for a full close, one for a
half), as in a last section that is only V-I. The truck driver's V is never
flavoured: the gear change is a dominant seventh.

**Found on the way.** A Loop of a named progression whose statements carry
the progression on (Pachelbel's eight chords over two four-bar statements)
drew its flavours afresh the second time round; now a statement that comes
to the same point of the progression as an earlier one plays that one's
chords, flavours and all. And a chord whose copy is a cadence's (a Period's
answer copies its question's opening up to where its own close begins) is
not flavoured, since the copy cannot follow it there - the answer opens as
the question did.

## Consequences

- Version 1.14. Every idea with flavours on may differ from 1.13 (most
  ideas: Rare is the default); drum ideas have ghost notes by default.
- Measured over 300 C major Measures: flavours in 162 with Triads, 161 with
  Sevenths, 160 with Mixed (1.13: 0, 0, 163); about one chord in ten. Ghost
  notes: 1.5 a bar on Rare (in 258 of 300 drum ideas), 3.4 on Common. Of 162
  Measures with pulled chords, the bass lay back in 79. The truck driver:
  553 of 600 Measures in seven-note scales changed gear (1.13: 360); the 47
  that step up plainly end on a section that is only its close.
- The sweep plays every ninth idea in Drop 4, ghost notes in turn, the bass
  pull as the engine rolls it, and checks ghost notes (a quiet snare, on a
  weak place, alone) and the bass's root where the chords change, pulled or
  not.

## Alternatives

**Ghost notes on the hats** or the kick. Not done: the snare's is the ghost
note every drum method means.

**Bass pull as a row of buttons.** Not done: the window is full (0025); the
engine decides, half and half.

**The Fonte left out in minor.** Rejected: the user asked for the minor
versions; the iv-to-III Fonte keeps what makes it a Fonte (a pair, the
second a step lower, minor then major) and the reply says so.
