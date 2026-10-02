# 0020. Applied chords, the deceptive cadence, and six more forms

Taken 2026-10-02. Stands. Widens [0006](0006-chords-stay-in-the-key.md)
(a second kind of chord from outside the key, after
[0011](0011-borrowed-chords-rarely-and-named.md)'s borrowed chords) and
[0004](0004-ideas-are-built-from-units.md) (a new cadence and new forms).

## Context

The second half of "update Good Idea so that it's in line with the books":
add what they suggest adding (`docs/READING.md`, first section). This
release takes the harmony and form items. The books agree on these, so
nothing needed asking.

- **Applied (secondary) chords**: "the most common chromatic chord in every
  style" - V/x, V7/x and viio(7)/x before any major or minor chord of the
  key (Open Music Theory, "Applied chords"; Hutchinson, chs. 17-18).
- **The deceptive cadence**, V to vi (Hutchinson, ch. 7), and the phrase it
  stretches: a weak or deceptive cadence where a full close was due, then
  the continuation "one more time" (Open Music Theory, "Internal
  Expansions").
- **Caplin's hybrid themes** and the **small ternary** (Open Music Theory,
  "Hybrid themes", "The Small Ternary").

## Decision

**Applied: Off / Rare / Common** (Key step, beside Borrowed; seven-note
scales; Rare by default; its own dice, `applied`). The chord before a major
or minor chord (not the tonic) becomes that chord's V - V7 with Sevenths or
Mixed - or, one time in four (`I.APPLIED_LEADING`), its leading-tone chord,
viio or viio7. `I.appliedKey` makes it from the home scale with the notes it
needs bent a semitone (V/V in C is the C scale with F#; V/vi with G#), so
the tune keeps its positions and bends with the chord while it sounds, as
under a borrowed chord. About 15% of the chords that can take one on Rare,
40% on Common (`I.APPLIED_CHANCE`). Never the first or last chord or a
cadence's, never a borrowed one, never two running, never one whose notes
are all in the key (V/IV as a plain triad is just I); only where the chord
after is the same every time the passage comes round, and a copy does what
its original did - so a Loop and a Period's answer play it again. Not
flavoured (nor is the chord it leads to, which must stay the chord it is
the dominant of), not chosen for inversion - though it may take the note a third
inversion before it falls to (Am7/G D7/F# G: the bass G F# G). Named in the
window ("Applied chord: D7 (V7/V) in bar 6, leading to G7") and marked `>`
in the chord line.

**DC**, a deceptive close: a cadence chord, then vi (VI in minor), in a
seven-note scale (an imperfect close in any other). The tune lands on a note
of vi, preferring do - "where the tonic was due". It is a unit's cadence like
the others (two chords; the cadence slots stay as they are).

**Form** gains six values (outside Any, which still rolls 1.0's four, so
every idea number keeps its form):

- **Hybrid 1** - antecedent + continuation: `a:2 b:2:HC f:1 f:1 c:2:PAC`
- **Hybrid 2** - antecedent + cadential: `a:2 b:2:HC c:4:PAC`
- **Hybrid 3** - compound basic idea + continuation: `a:2 b:2 f:1 f:1 c:2:PAC`
- **Hybrid 4** - compound basic idea + consequent: `a:2 b:2 a:2 b':2:PAC`
- **Ternary** - A B A: `a:4:PAC b:4:HC a:4:PAC` (12 bars; 8 and 16 bars put
  a period in the A)
- **Extended** - a sentence stretched by a deceptive cadence:
  `a:2 a~:2 c:2:DC c:2:PAC` (and at 12 and 16 bars, the continuation again
  before the second cadence)

(8 bars shown; 12 and 16 scale the same shapes.)

## Consequences

- Version 1.8. With Applied off (and the other 1.1-1.7 settings plain), every
  1.0 idea number is still the 1.0 idea; the 1.8 forms are only chosen.
- With the defaults, a 1.7 idea number may now have an applied chord.
  Measured over 400 C major ideas: on Rare, a third of Measures (4% of their
  chords), a sixteenth of Phrases; on Common, three in five Measures (11% of
  chords). V/V and V7/V are the commonest, then viio/V, V/vi, V/ii and V7/IV,
  as in the repertoire.
- At a deceptive cadence the tune holds do over vi 59 times in 60.
- The sweep checks every applied chord (a major V a fifth above the chord it
  leads to, or a diminished chord a semitone under it; never two running)
  and every deceptive close, and plays every fourth Measure in a 1.8 form.

## Alternatives

**An applied chord as a key change.** Rejected: positions counted from
another tonic would move the whole tune. Bending the home scale keeps every
position, and the spelling (F#, not Gb) comes from the home scale's letters.

**The evaded cadence** (the cadence never arrives). Not done separately:
Extended's deceptive cadence is the books' commonest way to stretch a phrase,
and an evaded one sounds like a plain answer without a melody that leaps
away, which Good Idea's walk does not do on purpose.
