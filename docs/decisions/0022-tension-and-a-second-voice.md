# 0022. Tension, and a second voice

Taken 2026-10-03. Stands. Loosens 0003's walk (a note on the beat is a
note of the chord - but for the tension notes named here) and widens
[0007](0007-a-measure-on-tracks-a-motif-in-one-item.md) (a fourth part).

## Context

The fourth part of "add everything they suggest adding" (`docs/READING.md`,
first section): the tune.

- **Accented non-chord tones.** Good Idea's tune put a note of the chord on
  every beat and left every other note by step: passing and neighbour
  notes only. The books also teach the accented kinds - the
  **suspension** (prepared, held over the change, falling a step: 4-3,
  9-8, 7-6) and the **appoggiatura** (accented, leapt to - usually up -
  falling a step) - and the **anticipation** (the next chord's note early,
  struck again on the change), often at cadences (Hutchinson, ch. 10;
  Open Music Theory, "Embellishing tones"). Open
  Music Theory: "With the exception of 9-8, the pitch class of the
  resolution tone should never sound in another voice simultaneous with
  the suspended tone."
- **A second voice in thirds or sixths.** "Melodies in octaves, double
  octaves, in thirds and sixths" (Rimsky-Korsakov); "parallel doubling in
  thirds, fifths or sixths adjusted to the harmony" (Belkin); a melody on
  the first violins "harmonised in thirds and sixths" (Wikipedia,
  *Orchestration*); a Thirds tune style suggested by *The Idiomatic
  Orchestra*.

The books agree on these, so nothing needed asking.

## Decision

**Tension: Off / Rare / Common** (Melody step; Rare by default; its own
dice, `tension`). After the tune is made (and kept clear of parallels),
`I.tension` goes through it:

- **Suspension** - where the tune steps down a note into a chord change,
  the note before (a note of its chord) is held over the change, a
  dissonance there, and the chord's note comes in late. Taken about one
  time in three on Rare where it can be, seven in ten on Common
  (`I.SUSPEND_CHANCE`): the spot is rarer than the others'.
- **Appoggiatura** - on a beat, the note a step above the chord's note,
  leapt up to (a third or more), falling to it. One time in ten where it
  can be on Rare, a quarter on Common (`I.TENSION_CHANCE`).
- **Anticipation** - a close's last note an eighth early, off the beat,
  over the chord before; struck again on the beat. A quarter of closes on
  Rare, half on Common (`I.ANTICIPATE_CHANCE`).

The dissonance lasts an eighth (a quarter, on a note a half note long or
more), then the chord's note takes the rest; so the note must be at least a
quarter long, and its chord must stay put until then. Never a minor ninth over the bass; never falling onto the bass's own
note but for the root (9-8); never on a close's goal (but the anticipation,
which is it early), a pushed note or a triplet; never a tritone or more than
an octave from the note before. An exact repeat leans where its source did
and draws nothing - so a Loop sounds the same each time round. By the book,
a chord struck while a suspension or appoggiatura sounds leaves out the note
it falls to - but for the 9-8, where that note is the chord's root - keeping
two notes, and a Phrase's own bass; free, it may sound it. (Open Music Theory
says it of the suspension; the appoggiatura, the same dissonance leapt to,
is treated alike.)

**Second voice: Off / Thirds / Sixths** (Melody step; Off by default; draws
nothing). Each note of the tune gets one under it, in the scale sounding
then: Thirds a third under, Sixths a sixth; on the beat it must be a note of
the chord, so where the interval is not, a fourth, then the other interval,
then the nearest note of the chord a third to a sixth under (a fifth at the
last). Off the beat, and under a tension note, it moves with the tune. A
part of its own, last, so the others keep their channels: in one item on the
next channel (4 in a Measure, 2 in a Motif), on tracks a track of its own.
The chords go under the tune and the second voice both.

## Consequences

- Version 1.10. With Tension Off (and the other settings plain) every 1.0
  idea number is still the 1.0 idea; Second voice Off adds nothing.
- With the defaults a 1.9 idea number may lean somewhere: measured over 200
  C major Measures, 35-40% on Rare (39 suspensions, 72 appoggiaturas and
  22 anticipations), about 60% on Common; 1.6 in 100 notes on the beat on
  Rare, 3.9 on Common. A tune that leans moves the
  chords a little where they sit under it.
- By the book, a chord doubled what a suspension falls to 4 times in 120
  Measures on Common (the two-note and bass exceptions); free, 144.
- Thirds is a third 84% of the time, Sixths a sixth 84%; the rest are the
  fourths and other intervals the chord asks for on the beat.
- The sweep checks every tension note by what it is (prepared, held over,
  falling a step to the chord, never a minor ninth on the bass, an
  anticipation off the beat), the chords leaving out a resolution, and the
  second voice under every note of the tune, on the chord on the beat.

## Alternatives

**The other non-chord tones** (escape tone, retardation, the 7-6 against a
moving bass, the bass suspension 2-3). Not done: the walk's passing and
neighbour notes cover the unaccented ones; these are rarer in the books'
own tallies and the 2-3 needs the bass to lean, which it never does.

**A second voice above the tune.** Rejected: the tune should stay on top -
"melody planned in the upper parts stands out from the very fact of
position alone" (Rimsky-Korsakov).
