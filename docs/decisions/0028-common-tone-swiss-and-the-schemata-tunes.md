# 0028. The common-tone diminished seventh, the Swiss sixth, the Aprile, Pastorella and Ponte - and the schemata's tunes

Taken 2026-10-03. Stands. Widens [0027](0027-chromatic-chords.md) (two more
chromatic chords) and [0021](0021-named-progressions.md) /
[0025](0025-the-engine-decides-more.md) (three more schemata, and a named
progression may now set the tune's note on each of its stages).

## Context

After 1.15 the user asked for the rest of what 0025 and 0027 had left out:
"the common-tone diminished seventh and the Swiss sixth; the Ponte, Aprile
and Pastorella schemata".

What the sources say:

- The common-tone diminished seventh "is a fully diminished seventh chord
  which progresses to a major triad or dominant seventh chords whose root is
  the same as one of the notes of the o7 chord. Examples are #ii°7 (or
  enharmonic #iv°7) progressing to I and #vi°7 progressing to V(7)"; "the
  remaining three notes of the diminished seventh chord resolve to the
  nearest chord tone, but the diminished 7th of the chords remain
  unresolved as common tones"; embellishing diminished sevenths are
  "non-functional attachments to the I, IV, and V(7) chords" (Kent State's
  voice-leading encyclopedia and *Harmony and Musicianship with Solfège*,
  "Embellishing diminished seventh chords", as quoted by a web search - the
  pages themselves are blocked from the container, so these are the
  search's excerpts). Not in Hutchinson or the Open Music Theory pages in
  the zip.
- The Swiss sixth "has four members: le, do, ri, and fi ... it sounds German
  but is spelled like the French ... the Swiss chord tends to appear in
  major keys, with ri proceeding to mi and do carrying over into the
  cadential 6/4"; and "the German sixth is almost always used in minor"
  (Open Music Theory, "Chromatically altered subdominant chords").
  Hutchinson shows the German in major keys too.
- The Aprile: melody do ti re do over the bass do re ti do (I V4/3 V6/5 I);
  the Pastorella: melody mi re fa mi over do sol sol do (I V7 V7 I); the
  Meyer: do ti fa mi over do re ti do (Open Music Theory, "Galant schemata -
  summary"). The Aprile, the Pastorella and the Meyer "all prolong tonic by
  moving away for the two middle stages before a tonic return ... the bass
  and harmonic structure are less fixed than is the melody" ("Galant
  Schemata - opens and closes"). The Ponte "holds onto that T1/V, heightens
  tension melodically, and often adds a seventh to the chord ... A passage
  built on a Ponte does not have a cadence" ("continuation patterns").

The one difference between the books (the German sixth in major) is of
spelling, not of sound; both are kept (below), so nothing was asked.

## Decision

**The schemata's tunes.** A named progression's chord may name the degree
the tune sings on that stage (`sing`; two for a chord holding two stages).
The first note of the tune in the stage takes that degree - the nearest
note of it within a fifth of the note before, a note of the chord - in the
walk, and in a copied tune when it is fitted to the chords under it; not a
close's last two notes, which go where the close goes. Given to the Meyer
(do ti fa mi) and the Prinner (la sol fa mi) of the Galant, the Do-Re-Mi (do
re mi), and the new Aprile and Pastorella - so the Aprile, which has the
Meyer's chords, is told from it by its tune, as the books tell them apart.
The others (Romanesca, Fonte, Monte, Ponte) are left to the walk.

**Three more schemata** among the named progressions (rolled by Any named,
with the rest), major and minor:

- the **Aprile**: I V4/3 V6/5 I, the tune do ti re do;
- the **Pastorella**: I V7 I, the V holding two stages, the tune mi re fa mi;
- the **Ponte**: the tonic, then V held - standing on the dominant (V7 with
  Sevenths or Mixed, V with Triads, as the Colour says); entered from the
  tonic so that an idea built on it opens at home.

**The Swiss sixth** (with Borrowed): le do ri fi - Ab C D# F# in C - in
major keys only, through the cadential six-four like the German, ri rising
to mi. In a major key it shares the German's place half and half (both
books kept: Hutchinson's German in major, Open Music Theory's Swiss); in
minor the German alone.

**The common-tone diminished seventh** (with Applied; its own dice,
`commontone`): a held major I or V, three beats or more and not a close's,
becomes I - #ii°7 - I (V - #vi°7 - V): the diminished seventh for a beat
(two in a longer chord) before its last beat or two, its common tone - the
chord's root - held in the bass (written D#dim7/C), the tune and the inner
voices moving to it by step. Not with Triads (it is a seventh chord); a copy
does what its original did; the chord either side keeps its root. Marked
`>` and named in the window with the applied chords: "D#dim7/C (#iio7, the
common-tone diminished seventh) in bar 7, colouring Cmaj7".

## Consequences

- Version 1.16. Ideas with a named schema now have its tune at most of its
  stages (80% of 4,545 stages in 480 test ideas - the rest where the tune
  rests or a rule overrides); an idea may now roll the Aprile, the
  Pastorella or the Ponte. With the defaults, a common-tone diminished
  seventh in about one Measure in 18 (22 of 400); on Common with Sevenths
  at a chord a bar, 193 in 300 Measures.
- The sweep checks each common-tone chord (fully diminished, between two of
  the same major chord, its root in the bass) and the Swiss sixth's notes
  and its six-four.

## Alternatives

**A seventh forced on the Ponte's V** even with Triads. Rejected: Triads
means three-note chords; the seventh is the Colour's.

**The common-tone diminished seventh on IV**, or as an incomplete neighbour
(before the chord, not between). Not done: the sources' examples are #ii°7
to I and #vi°7 to V, between statements of the chord.
