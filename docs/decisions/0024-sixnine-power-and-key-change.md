# 0024. The 6/9, power chords, and a key change for the last section

Taken 2026-10-03. Stands. Widens [0018](0018-flavours-voicings-and-inversions.md)
(a flavour and a voicing) and [0006](0006-chords-stay-in-the-key.md) (the
last section may be in another key).

## Context

The last part of "add everything they suggest adding" (`docs/READING.md`,
first section):

- **Chord types**: the List of chords names the **6/9** ("major sixth ninth
  chord", "6 add 9"; and the minor 6/9) and the **power chord** (a perfect
  fifth, "C5"), neither of which Good Idea made.
- **A key change near the end**: "In the pop literature, direct
  modulations by whole- or half-step are common near the end of the song
  ... also called step-up or pump-up modulations"; and the **truck-driver
  modulation**, "a direct modulation that moves from the old key (usually
  the tonic chord) to the dominant chord of the new key to prepare that
  tonic arrival" (Open Music Theory, "Modulation"). A direct modulation
  "often happens at phrase boundaries".

The sources agree on these, so nothing needed asking.

## Decision

**The 6/9** - a flavour (with Mixed and Flavours on): a 6 becomes a 6/9 -
root, third, fifth, major sixth, and the whole-tone ninth on top - half the
time where the ninth is a whole tone (`I.SIXNINE_CHANCE`, on dice of its
own, `sixnine`, drawn only when a 6 has been chosen). It is not in
`T.FLAVOURS`, so the flavours drawn before 1.12 are drawn as they were; a
copied chord does what its original did. Cm6/9 in C minor's Dorian-sixth
places; never where the chord had a seventh.

**Power** - a voicing (outside Any, which still rolls the seven): the root,
the fifth over it and the root an octave up. A chord with no perfect fifth
(diminished, augmented) plays its root in octaves. The chord line still
names the chord (the tune and the bass still hear its third).

**Key change: None / Step up / Half step up / Truck driver** (Arrangement
step, Measures only, None by default; draws nothing). From the start of the
last unit that begins at or after half way, on a bar line, with two bars or
more to go (`I.changeAt`), every chord is the same degree of the key a tone
(or a semitone) higher (`T.transpose`: spelled with the fewest sharps and
flats, lifted an octave where the key note passes B), so the tune, which is
positions in the scale, goes up with it, and so does the bass. The truck
driver puts the new key's V (major; from harmonic minor in a minor key; V7
with Sevenths or Mixed) in the second half of the chord before the change,
or in its place if that is short. Chords after the change are not borrowed
or made applied (those read the home key). The window says where and to
what ("Key change: Up a whole tone to D Major at bar 9").

## Consequences

- Version 1.12. With Key change None, Voicing not Power and no 6 chords,
  every 1.11 idea number is the same idea; with flavours, half of the 6
  chords are now 6/9 (the chord's name says so).
- The sweep plays every seventh Measure with a key change (all three) and
  every eighth idea with power chords, and checks every note against the
  scale sounding under it - in the new key after the change.

## Alternatives

**A key change by a pivot chord**, or to the dominant or the relative key
(the classical modulations). Not done: they want a section written for the
new key (a new tonic, cadences in it); the pop step-up is the one the books
name for a last section.

**Power chords as a colour** (C5 in the chord line). Rejected: the harmony
is still the triad - the tune and the bass are written over it - and the
power chord is how the chords part plays it, like Shell or Rootless.
