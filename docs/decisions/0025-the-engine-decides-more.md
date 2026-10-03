# 0025. The engine decides more; the books' last items

Taken 2026-10-03. Stands. **Changes [0010](0010-figures-push-and-swing.md)'s
promise** that every 1.0 idea number gives the 1.0 idea: given up, at the
user's word. Widens [0019](0019-part-writing-by-the-book.md) (a six-four
doubles its bass), [0020](0020-applied-chords-cadences-and-forms.md) (the
evaded cadence), [0021](0021-named-progressions.md) (four more schemata) and
[0013](0013-drums-are-a-kind-of-idea.md) (a fifth beat).

## Context

The user, after 1.12: the window is filling up with options. Hide the
Progression (walk or a named progression, half and half, under the hood),
Part-writing (by the book, always) and the Form (rolled for every idea, each
about one time in ten). Old idea numbers need not be kept: no one is using
the script yet. And yes to the five smaller things the books suggest that
were left over: two leaps the same way only where they outline a chord,
minor keys closing on a major V, an evaded cadence, the other galant
schemata, and a reggaeton beat.

## Decision

**Hidden settings.** A setting may be `hidden`: never drawn (`I.shows` is
false), left alone by Keep, but rolled like any other - the engine decides
it. Progression: Any, rolling Walk or Any named, half and half (Any named
picks a progression that suits the key, or walks and says why). Part-writing:
By the book (Free is kept for the tests, which compare the two). Form: Any,
over all ten forms, evenly. The summary line still says which progression
and which shape an idea has.

**1.0's ideas are no longer kept.** The thirty fingerprints that held them
are retired. The rest of the discipline stands - one draw per setting, a
stream per part, settings appended - because it is what makes the same
number with the same settings the same idea, and changing one setting leave
the others' choices alone.

**Two leaps the same way** outline a consonant triad (major or minor, any
position, inside an octave) or do not happen: "no consecutive leaps in the
same direction (Fux's F-major cantus is an exception, where the back-to-back
descending leaps outline a consonant triad)" (Open Music Theory, "Composing a
cantus firmus"). In the walk (`choose`), guaranteed in the last tidy pass
(`untangle`, after its octave fix, which could make one), and respected by
the parallels pass and an appoggiatura's leap. Not across a statement's
start.

**The minor key's V.** In a key on the Minor scale every V is the harmonic
minor's - major, its third the raised seventh - and the tune bends with it:
Hutchinson's table of the chords in minor (ch. 7, Figure 7.3.1) marks the
minor v "rare" and takes V "from the harmonic minor scale". Its cadences weight it as a real V. The modes (Aeolian, Dorian,
Phrygian) keep their own v; a named progression's chords are as written.

**The evaded cadence.** Extended's stretch is a deceptive close or, half the
time, an evaded one (EC): the cadence chord, then the tonic standing on its
third (I6), the tune leaping up to a note that is not do instead of
resolving - "the PAC never materializes: the leading tone ... is not
resolved, the pianist's right hand leaps up" - then the passage "one more
time" to a full close (Open Music Theory, "Internal Expansions", Mozart K.
309). Kept inside Extended so the ten forms stay one in ten each.

**More galant schemata** (Open Music Theory, "Galant schemata"): the
Do-Re-Mi (I V6/5 I; minor too), the Romanesca (I V6 vi I6), the Fonte (V7/ii
ii V7 I) and the Monte (V7/IV IV V7/V V). A named chord may be `appliedTo`
a degree - its dominant, from the home scale bent, marked `>` - and falls
back to the plain chord of its degree if a close cuts in before the chord it
leads to. The Aprile and the Pastorella have the Meyer's and the Do-Re-Mi's
chords, so they are not separate. A named bass is now taken from the
chord's own scale (the Do-Re-Mi's ti in C minor is B, harmonic minor's).

**Reggaeton** (the Drums kind's Beat, rolled by Any): the dembow - a kick on
every beat, the snare on 3, 6, 11 and 14 of the bar - "the reggaeton beat
is built from a 3+3+2 rhythm", 3+3+2 in sixteenths, set beside the habanera
(Hutchinson, 14.6.1.1). In 4/4; a backbeat elsewhere. Its answering bar's
pickup kick goes on the "a" of 4, where the snare has the "and".

**Found on the way.** The six-four: "when a triad is in second inversion,
double the fifth (the bass note)" (Hutchinson, 26.9; and 26.12's summary:
root position and second inversion double the bass, first inversion does
not, but for vii°6 and ii°6). Since 1.7 a six-four had its doubled bass
taken out; now it keeps it. And a drum idea's answering bar could not open a
hat on the ride or under quarter-note hats; it takes the pickup kick there.

## Consequences

- Version 1.13. Every idea number may give a different idea from before.
- Measured: half the ideas look for a named progression (201 of 400); each
  form 6-14% of 1000; Extended's stretch evaded 99 times and deceptive 101 in
  200; the evaded tonic on its third every time, the tune leaping up a fourth
  or more 68 times in 99; in C minor no V without B natural; 58 of 58
  six-fours keep their doubled bass.
- The sweep checks two leaps the same way, the minor V, the evaded close;
  plays the hidden settings as the engine rolls them.
