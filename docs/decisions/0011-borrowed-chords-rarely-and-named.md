# 0011. Borrowed chords: rarely, from the same key note, and always named

Taken 2026-10-01. Stands. Widens [0006](0006-chords-stay-in-the-key.md). Since 1.6 there is Common too
([0018](0018-flavours-voicings-and-inversions.md)): about two ideas in three,
and a second chord in a longer idea.

## Context

"If there's a way to implement borrowed chords without breaking the script
that would be good too, but if you did this the borrowed chords should only
appear rarely in generations and the UI should flag when a borrowed chord
appears and which scale it's from."

[0006](0006-chords-stay-in-the-key.md) kept every chord in the key because
chromatic chords chosen by dice clash more than they colour. Borrowing done
carefully avoids that.

## Decision

**Modal mixture only**: a chord on the same degree, taken from another
seven-note scale on the same key note.

- In a major key, mostly from the parallel minor - the iv (Fm in C), the
  bVI (Ab), the bVII (Bb), the bIII (Eb) - and from Mixolydian, Dorian and
  the rest less often. In a minor key, mostly from the parallel major and
  from Dorian (the major IV) and harmonic minor.
- **Rare**: about one idea in four is allowed one, and it needs room - never
  the first chord or the last two (the opening tonic and the cadence stay
  the key's own) - so in practice short ideas borrow less often still.
  Never a diminished or augmented chord, and only a chord that really has a
  note from outside the key.
- **The degree is unchanged**, so the walk that chose the chords, and the
  form, are untouched; only the chord's notes change.
- **The scale bends under it.** Each chord in the timeline carries its scale
  (`sl.key`), and everything that turns a scale position into a pitch reads
  the scale sounding at that moment (`I.keyAt`): under Ab in C major the
  tune plays Ab, Eb and Bb, not A, E and B. Seven-note scales borrow only
  from seven-note scales, so the positions line up note for note.
- **Always named.** The window prints "Borrowed chord: Ab (bVI) in bar 3,
  from C Minor" in the body text, and the chord line marks it `Ab*`.
- A **Borrowed: Off / Rare** setting, Rare by default, in the Key step. It is
  hidden for a scale that cannot borrow (pentatonic, blues, whole tone,
  diminished).

## Consequences

- The sweep checks every note against the scale sounding under it rather
  than the key; named tests check rarity (10-35% of ideas, never two), the
  positions it may take, that the chord is really from outside the key, the
  flag, and that the tune bends (no A, E or B against a chord from C minor).
- Midi Catalogue's chord-scale bending is the same idea, arrived at for the
  same reason: a borrowed chord needs its own scale under it.

## Alternatives

**Secondary dominants and other chromatic chords.** Not yet: they want
resolving to their target chord, which the walk does not plan for.

**Borrowing at any rate the dice give.** Rejected by the request: rare, and
flagged.
