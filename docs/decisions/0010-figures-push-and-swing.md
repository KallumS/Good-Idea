# 0010. Rhythm: dotted and triplet figures, pushed chords, and swing - laid over, not built in

Taken 2026-10-01. Stands, widened by [0014](0014-pull-the-chords-lie-back.md) (pull)
and [0015](0015-chord-rhythm-figures-and-one-and-a-half.md) (figures on every chord style).

## Context

After 1.0: "it would be good if there was a way to make the generations
more rhythmically interesting - such as chords and notes that don't start on
beat, or have a chance to be a triplet or dotted. Perhaps there could be a
global swing slider too."

1.0 works on a sixteenth-note grid. Triplets do not fit on it (a third of a
beat is 4/3 of a sixteenth), and every chord changed on a beat.

## Decision

Three things, each a layer over what 1.0 already made, so the rules that
make an idea musical (chord tones on the beat, cadences, voice leading) are
untouched:

- **Figures** (Plain, Dotted, Triplets, Mixed, or Any). After a rhythm is
  made, now and then a beat's two eighths become a dotted eighth and a
  sixteenth, or two quarters a dotted quarter and an eighth; or a beat
  becomes an eighth-note triplet, or two beats a quarter-note triplet.
  Triplet notes sit at fractional steps (4/3, 8/3) - the step grid stays,
  and the few places that ask "is this on the beat?" already answer no for
  them, so they are passing notes. It applies to the tune, to Pulse chords,
  to Broken chords (an arpeggio rolls in triplets), and with Triplets the
  hats shuffle. A last pass (`I.wholeTriplets`) keeps every triplet whole:
  copying half a statement or holding a closing note could otherwise cut
  one in two.
- **Push** (None, Some, Lots, or Any). A chord change on a beat moves back
  an eighth onto the "and" before it; the chord before gives up that eighth.
  The tune's note on that beat comes early with it, the kick drum moves onto
  the push, the bass plays the new root there, and a held chord is struck on
  the push and not again on the beat.
- **Swing** (a slider, 0-100%). The very last thing done to an idea: each
  quarter note's grid is stretched so the off-beat eighth lands later - at
  100% two thirds of the way through the beat, where a triplet would - with
  the sixteenths either side moving in proportion. Beats never move;
  triplets are left alone. It is a slider, not a row of buttons, because it
  is a matter of degree, and it is not rolled by Any: a groove's swing is a
  choice for the whole session.

Only in metres whose beat is a quarter (or half) note. 6/8 and 12/8 are in
threes already; 7/8 has no quarter-note beats to divide. The window says so
where the swing slider would be.

**1.0's ideas are kept.** The settings list is also the order the dice are
drawn in, so the new settings were added at its end, and each draws nothing
when plain. With Figures Plain, Push None, Borrowed Off and no swing, every
1.0 idea number gives exactly the 1.0 idea: `test_idea` holds thirty of them,
hashed before 1.1 was written.

## Consequences

- Notes no longer always start on sixteenths, and chords no longer always
  change on beats. The sweep's rules were widened to say exactly how: a
  chord changes on a beat or an eighth before one when pushed; a note
  between the sixteenths belongs to a whole triplet.
- Swing changes what is inserted and exported, not only what is heard.
- The roll and the demo show the off-grid notes; the chord line marks a
  pushed chord `^`.

## Alternatives

**A finer grid** (48 or 96 to the bar) so triplets are whole numbers.
Rejected: every musical rule in the engine counts in sixteenths, and every
one would have needed rewriting and re-proving for a feature that needs only
a few notes at a time between them.

**Swing as a setting rolled by Any.** Rejected: swing is a feel chosen for a
track, not a property of one idea; rolling it would make ideas hard to
compare.

**Random timing offsets ("humanise").** Rejected: off-beat starts here are
musical figures - pushes, dotted rhythms, triplets - placed for a reason,
not jitter.
