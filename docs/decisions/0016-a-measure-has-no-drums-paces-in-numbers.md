# 0016. A Measure has no drums; chord paces in numbers, 0.5 to 4 a bar

Taken 2026-10-01. Stands. Reverses half of
[0013](0013-drums-are-a-kind-of-idea.md) (a Measure always had drums) and
widens [0015](0015-chord-rhythm-figures-and-one-and-a-half.md) (the chord
pace).

## Context

"Could we remove drums entirely from Measure. Could we also add 0.5 a bar
and 4 a bar to the chord paces please."

Since 1.2 drums are a kind of idea of their own, with their own beat, fills
and cymbal. A Measure's drums were the 1.0 part - none of those choices -
and with a drum idea one click away they doubled up: two ways to make drums,
one of them with no controls.

"Slow" in the chord pace was already half a chord a bar: a chord every two
bars.

## Decision

**A Measure is melody, chords and bass.** No drum part, nothing on MIDI
channel 10. On Tracks it makes three tracks; in one item, channels 1, 2
and 3. Drums are the Drums kind's alone.

- **The bass is unchanged.** A Pulse bass plays the rhythm a kick drum
  would play (`I.kickPattern`). That pattern is still drawn from the
  `drums` dice stream, as in 1.0 to 1.2, so every Measure's tune, chords
  and bass are exactly what they were - only the drums are gone.
- **The `drums` setting stays retired** and its one value is now Off. A
  saved `drums=On` comes back Off. It keeps its place in `I.SETTINGS`, so
  every setting after it rolls as before.
- **1.0's Measures are compared without their drums.** The regression
  check's Measure fingerprints were made again by the 1.0 code, leaving out
  the notes on channel 10: everything else is still note for note 1.0's.

**The chord pace reads in numbers**: 0.5, 1, 1.5, 2 and 4 a bar. "0.5 a
bar" is the old Slow, renamed, not a new value - adding a second one would
have made two buttons that do the same thing. The stored names (`Slow`,
`One a bar`, `Two a bar`) are unchanged, so saved settings and idea numbers
still mean what they did; only the labels (`name(v)`) are new.

**4 a bar is a chord on every beat**: four a bar in 4/4, three in 3/4,
two in 6/8 - the number of chords is capped at the number of beats. A
continuation (`f`) is never slower than the pace chosen. Like 1.5 a bar, it
is chosen, never rolled by Any: Any rolls 0.5, 1 and 2 with 1.0's weights.

## Consequences

- Version 1.3. A Measure from 1.2 loses its drums and nothing else.
- The push test checks that the bass comes with a pushed chord (it used to
  check the kick). The kick pattern test checks the bass against the
  pattern drawn from the stream.
- The tests check that no Measure has drums, that the retired switch is
  Off, that 4 a bar changes chord on every beat in 4/4 and 3/4, that Any
  never rolls it, and that the row reads 0.5, 1, 1.5, 2, 4.

## Alternatives

**Keep a drums switch on the Measure, off by default.** Rejected: the ask
was to remove them entirely, and the Drums kind does it better.

**Add 0.5 a bar beside Slow.** Rejected: two buttons, one meaning.

**Rename the stored values too.** Rejected: saved settings would come back
as the default, for nothing a musician sees.
