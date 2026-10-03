# 0027. Chromatic chords: the Neapolitan, the augmented sixths, the passing diminished seventh

Taken 2026-10-03. Stands. Widens [0006](0006-chords-stay-in-the-key.md)
(a third kind of chord from outside the key, after
[0011](0011-borrowed-chords-rarely-and-named.md)'s borrowed chords and
[0020](0020-applied-chords-cadences-and-forms.md)'s applied ones).

## Context

The last of the things the user said yes to after 1.13 (0026 has the rest):
"out-of-key colour chords (the Neapolitan, augmented sixths, a passing
diminished seventh)". CLAUDE.md had left them open since 1.5.

What the sources say (read in their own text):

- "The most common chromatically altered subdominant chords (aside from the
  applied dominant of V) are the Neapolitan chord and the various
  augmented-sixth chords" (Open Music Theory, "Chromatically altered
  subdominant chords").
- The Neapolitan "contains lowered scale-degree 2, along with scale-degree
  4, and lowered scale-degree 6: ra, fa, and le. It is a major triad, and
  it usually appears with fa in the bass (first-inversion), which is also
  doubled" (Open Music Theory); "being a chromatically altered ii chord, the
  Neapolitan has pre-dominant harmonic function"; "double the bass (the
  third)"; "resolve 2 down to the nearest note in the next chord", to V, the
  cadential I6/4 or viio7/V (Hutchinson, 20.1 and 29.3).
- Augmented sixths are "a special class of pre-dominant chords with notes
  that approach the dominant (5) from a half-step below (#4) and from a
  half-step above (b6) simultaneously" (Hutchinson, 21.1). Italian le do fi;
  French adds re; German adds me; le "typically the bass note"; "the German
  sixth is almost always used in minor and followed by a cadential 6/4"
  (Open Music Theory). On a lead sheet, "major-minor seventh chords built on
  6": Ab7 (no 5th), Ab7(b5), Ab7 in C (Hutchinson, 21.4). They go to V, V7
  or the cadential six-four (Hutchinson, 29.4).
- A passing chord "will fill in the third with stepwise motion" (Open Music
  Theory, "Harmonic syntax - prolongation"); Hutchinson's examples pass
  through viio7/V (I6 ii6 viio7/V I6/4; N6 viio7/V V).

The books agree, so nothing needed asking. (Open Music Theory also names a
"Swiss" sixth, the German's sound spelled with ri, in major keys; the notes
are the same, and Good Idea names the chord as a lead sheet does.)

## Decision

**No new rows.** The window is full (0025). The Neapolitan and the
augmented sixths come under **Borrowed** (chords from outside the key that
stand in for one of the key's), the passing diminished seventh under
**Applied** (it is the next chord's own leading-tone seventh). Each has dice
of its own (`chroma`, `passing`) and draws nothing when its row is Off.

**At a close**, the chord before its V (a ii or a IV - or, where the tonic
comes straight before the V, the tonic's second half: i N6 V) may become
(`I.chromatic`, about one close in three that can on Rare, four in five on
Common):

- the **Neapolitan**, N6: the major chord on the flat 2nd from the Phrygian
  on the same key note, over fa (Db/F in C); by the book it doubles its
  bass, as both books say;
- an **augmented sixth**: le do fi (Italian), le do re fi (French), le do me
  fi (German), le in the bass, the tune using the home scale with fa raised
  and la lowered (mi too, for the German); by the book fi rises to sol in
  the next chord; the German takes the first half of the V for the
  cadential six-four, or is not chosen.

Only before a major V (one with a leading note), never on a named
progression's chord, a borrowed or applied one, a chord an applied chord
leads to, or after a key change. With Triads, only the three-note ones
(the Neapolitan and the Italian sixth). A copy of a chord does what its
original did, and a copy whose original was not before a V does nothing:
a Period's answer opens as its question did. The chord line marks them `*`
("from outside the key"), and the window says which, where, and what it is:
"Db/F (N6, the Neapolitan) in bar 7, before the V".

**Passing diminished seventh** (`I.passing`): where the bass climbs a tone
from one chord to the next (IV to V, I to ii, V to vi, VII to i in minor),
and the first chord is two beats or more and not a close's, its second half
may become the diminished seventh on the note between (F F#dim7 G): the
bass climbs by semitones. With Triads, the diminished triad. A quarter of
the places that can on Rare, three in five on Common; only where the next
chord is the same every time round. Neither chord either side is then
inverted. Marked `>` and listed with the applied chords: "F#dim7 (viio7/V)
in bar 7, passing to G".

**Found on the way.** A second voice in sixths under fi in an Italian sixth
found only the augmented sixth or a tritone among the chord's notes: it
takes a consonant note of the scale instead. An Open voicing of a chord with
no fifth (the Italian sixth) spreads root - seventh - third.

## Consequences

- Version 1.15. With Borrowed and Applied on Rare (the defaults), about one
  Measure in eight has a chromatic chord (48 of 400, any key) and one in ten
  a passing diminished chord (40 of 400). In 300 C major and minor Measures:
  70 chromatic chords on Rare, 133 on Common; the Neapolitan doubled its
  bass 74 times in 74; fi rose to sol 56 times in 59.
- The sweep checks each kind's notes and bass, that it goes to V (the
  German through the six-four), and that a passing chord's bass climbs by
  semitones.

## Alternatives

**A row of its own** ("Chromatic: Off / Rare / Common"). Not done: the user
asked for fewer rows in 1.13; Borrowed and Applied already mean "chords from
outside the key".

**The common-tone diminished seventh** (I - #ii°7 - I over a held tonic) and
the Swiss sixth. Not done: the user named the passing kind; the common-tone
one is an embellishing chord, rarer in the books' examples.
