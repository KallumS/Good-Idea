# 0006. Chords stay in the key; scales other than seven notes are built by ear

Taken 2026-10-01. Stands, widened by [0011](0011-borrowed-chords-rarely-and-named.md): rare
borrowed chords from scales on the same key note. Since [0018](0018-flavours-voicings-and-inversions.md) a
Mixed chord may take a flavour (sus, 6, 9, add2, the diminished seventh a
third up) - every one built from the scale, so still in key.

## Context

Midi Catalogue lets the user chain any of 87 chords, borrowed ones included,
and bends the scale under each. Good Idea chooses the chords itself, at
random, and a borrowed chord chosen by dice is far more likely to sound wrong
than inspired. Meanwhile the sixteen scales include five-, six- and
eight-note ones, where "every other note" stacks into nonsense (every other
note of C major pentatonic is C E A).

## Decision

- **Every chord is built from the scale**, so it is always in key, and
  everything over it - tune, bass, chords - is in the key too.
- In a **seven-note scale**, every other note: the textbook triads and
  sevenths. **Mixed** colours them as a player would: a seventh where it
  pulls (ii, V, vii, VII), a whole-tone added ninth on the other major and
  minor chords, never the flat ninth on iii.
- In **any other scale**, by ear: a third if the scale has one, else a sus
  chord, then a fifth if it has one (a sharp fifth only over a major third).
  C major pentatonic gives C, Dsus4, Em(no5), Gsus4, Am.
- **Which chord follows which** is read off each chord root's distance from
  the tonic, not its numeral, so one table serves major, minor and every
  mode: in natural minor the cadence comes from VII or v, in Phrygian from
  bII, in Mixolydian from bVII. Other scales move by root motion.
- A **half cadence** rests on a dominant (V, v, VII, bII), never on IV.

## Consequences

- The tests check every chord of every scale in every colour is in the key,
  rooted and named, and that every note of every chords part is on its
  chord.
- No secondary dominants, no borrowed chords, no chromatic bass lines. Those
  are the next things a musician adds to an idea, and Midi Suggester and Midi
  Catalogue are built for exactly that.

## Alternatives

**Borrowed and chromatic chords at random.** Rejected for now: drawn by dice
they clash more often than they colour. A later "Colour: Borrowed" setting
could add them deliberately, with Midi Catalogue's chord-scale bending.

**Only offer seven-note scales.** Rejected: ScaleView's sixteen are the
house's scales, and pentatonic and blues ideas are some of the most useful
starting points.
