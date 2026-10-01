# Good Idea

Ideas for starting a track, for REAPER. Press **New Idea** and get a short
motif, a phrase, or eight to sixteen bars of music - melody, chords, bass and
drums - in your key, ready to drop into the project as MIDI and work on.

The hardest thing in music is the blank page. Good Idea fills it with
something worth reacting to: not a finished piece, but a start you can keep,
change, or throw away and roll again.

## Three kinds of idea

- **Motif** - a short melodic hook, 1 to 4 bars. Built the way hooks are: one
  small cell, repeated, moved up or down, answered. Most motifs leave the door
  open at the end so they loop.
- **Phrase** - 1 to 4 bars of a **melody**, a **chord pattern**, or **both**
  together in one clip. A phrase has a proper ending: it comes home, or pauses
  on the dominant, or leaves itself open to go round again.
- **Measure** - **8, 12 or 16 bars** of music: a melody, chords, a bass line
  and a drum part, laid out in a form - a **Period** (a question and its
  answer), a **Sentence** (an idea, the idea again, broken up and driven to a
  close), a **Song** (A A B A) or a **Loop** (one progression round and round
  with the tune varied over it).

## Why maths, and not a library or dice

Nothing here is a stored clip. Every idea is **calculated**, from the rules
that make music sound like music:

- **Rhythm.** A straight rhythm puts notes on the strongest beats first - the
  downbeat, then beat 3, then the other beats, then the half beats. A
  syncopated one spreads its notes over the bar as evenly as they will go and
  turns them off the beat - the same sum that gives you the tresillo (3 notes
  in 8) and the cinquillo (5 in 8). Musicologists call these Euclidean
  rhythms; a great many of the world's rhythms are made this way.
- **Chords.** Harmony moves from home (the tonic) to away (the subdominant) to
  tension (the dominant) and back home. Good Idea walks that cycle chord by
  chord - after V mostly home, after ii mostly V, after vi on to ii or IV - and
  every phrase ends on a real cadence: V-I to close, a pause on V to ask a
  question.
- **Melody.** A tune moves mostly by step, lands on a note of the chord on the
  beat, fills in after a leap by stepping back, and follows a shape - an arch
  that peaks two thirds of the way through (the golden section), a rise, a
  fall, a wave.
- **Form.** Ideas are built from parts the way composers build them: a basic
  idea, its repeat, a sequence of it (the same shape on another chord), an
  answer (the same start, a different ending), fragments of it, and a cadence.
- **Rhythmic colour.** Now and then a pair of notes becomes long-short
  (dotted) or a beat becomes three (a triplet); chords can be **pushed** an
  eighth early, onto the "and" before the beat, with the tune and the kick
  drum coming along; and the whole idea can **swing**.
- **Borrowed chords.** Rarely - about one idea in four, at most one chord -
  a chord is borrowed from another scale on the same key note: the minor iv
  or the bVI in a major key, the major IV in a minor one. The tune bends to
  it, and the window always tells you which chord it is, where, and which
  scale it came from.

So there is chance in it - **New Idea** picks which rhythm, which chords,
which notes - but only among choices that make musical sense.

### Every idea has a number

Each idea has an **idea number**. The same number with the same settings is
**always the same idea**. So you can:

- **write a number down** and come back to it any time;
- **change a setting and keep the idea** - put idea 4821 into D minor, make it
  busier, give it seventh chords, and it is still recognisably idea 4821. Change
  the key and you get the same tune, moved.

A number written down from version 1.0 still gives the same idea with
Figures on Plain, Push on None, Borrowed on Off and no swing.

## The settings

Every setting is a row of buttons. Most have an **Any** button: leave a
setting on Any and it is rolled afresh for every new idea (hover over Any to
see what this idea rolled). Choose a value and it stays put.

1. **Idea** - Motif, Phrase or Measure, and how many **bars**. For a Phrase,
   the **content**: Melody, Chords or Both.
2. **Key** - the key note and the scale: major, minor, the modes, pentatonic,
   blues, whole tone, diminished (ScaleView's sixteen). Its notes are spelled
   out underneath. **Borrowed** - Off, or Rare (the default): whether an
   idea may borrow a chord (seven-note scales only).
3. **Feel** - the **pace** (Calm, Flowing, Busy) and the **groove** (Straight,
   Syncopated); the **figures** (Plain, Dotted, Triplets, or Mixed: dotted
   and triplet rhythms now and then - with Triplets the drums shuffle and
   broken chords roll in triplets); the **push** (None, Some, Lots: chords
   arriving an eighth early); and **Swing**, a slider from 0 (straight) to
   100% (full triplet swing, the off-beat eighth two thirds of the way
   through the beat). Swing is not rolled by Any - it is your groove, and it
   is kept between sessions. In 6/8 and 12/8 there is no slider (they are in
   threes already), nor in 7/8. These shape every part.
4. **Melody** - the **contour** (Arch, Rise, Fall, Wave, Valley) and the
   **register** (Low, Middle, High).
5. **Chords** - the **colour** (Triads; Sevenths; Mixed - sevenths where they
   pull, added ninths elsewhere), the **chord pace** (a chord every two bars,
   one a bar, two a bar) and the **style** (Block, Pulse, Broken).
6. **Arrangement** (Measure only) - the **form**, the **bass** (Held; Pulse,
   locked to the kick drum; Moving, stepping into each new chord), **drums**
   on or off, and the **layout** (a track per part, or one item).

Steps that mean nothing for what you have chosen are not shown: a Motif has
no chords to set, a chords-only Phrase has no melody.

## Using it

Press **New Idea**. The idea appears in the roll - the tune in yellow, chords
and bass in grey, drums as ticks along the bottom - with its chords written
out underneath, bar by bar. A chord marked **^** is pushed an eighth early; a
chord marked **\*** is borrowed, and a line underneath says which chord, in
which bar, from which scale: "Borrowed chord: Ab (bVI) in bar 3, from C
Minor".

- **<** and **>** step back and forward through the ideas you have made.
- **Idea number** - type a number to go straight to that idea.
- **Keep** turns every Any into what this idea rolled, so the next New Idea
  keeps the key, length and feel and changes only the music.
- **Play new ideas** auditions each idea as soon as it is made.
- **Velocity** - everything leaves at 100. Choose **Accents** and the downbeats
  and the start of each part of the idea rise to 115.

And get it out:

- **Insert at cursor** puts it on the selected track at the edit cursor, as
  one item. A Phrase with melody and chords keeps them on MIDI channels 1 and
  2, so you can split them apart later with REAPER's explode-by-channel
  action (search the action list for "explode").
- **Insert on new tracks** (a Measure laid out on Tracks) makes a track for
  each part - Melody, Chords, Bass, Drums - under the selected track.
- **Export .mid** writes a MIDI file into a `Good Idea` folder in REAPER's
  resource path. Point the Media Explorer at it and every idea you export is
  one drag away.
- **Audition** plays it through the virtual keyboard, so a record-armed track
  with monitoring on will sound it. It is a preview, not a performance - for
  exact timing, insert it and press play.

The drums are on **MIDI channel 10** with General MIDI notes (kick 36, snare
38, closed hat 42, open hat 46, crash 49, toms 45, 47, 50), which any General
MIDI drum kit understands.

The tempo and time signature are read from your project: an idea in 3/4 or
6/8 has bars of that length and is felt that way. Your choices and the idea
you were on are remembered between sessions.

## Installing

**1. Install ReaImGui.** The script will not start without it.

In REAPER: Extensions -> ReaPack -> Browse packages, search for `ReaImGui`,
right-click it and Install. Then Extensions -> ReaPack -> Apply changes, and
restart REAPER.

**2. Install Good Idea.** Either:

- **With ReaPack** (easiest, and it keeps it up to date): Extensions ->
  ReaPack -> Import repositories, paste
  `https://raw.githubusercontent.com/KallumS/Good-Idea/main/index.xml`,
  then Browse packages, find Good Idea and Install. That link only works once
  this has been merged into the main branch.
- **By hand**: Options -> Show REAPER resource path in explorer/finder, go into
  `Scripts/`, make a folder called `Good Idea`, and put these five files from
  the `reascripts` folder in it together:

  ```
  Scripts/Good Idea/
    Good Idea.lua
    gi_theory.lua
    gi_idea.lua
    gi_midi.lua
    gi_place.lua
  ```

  They have to be in the same folder: the first one loads the others from
  beside itself.

**3. Load it as an action** (by-hand install only - ReaPack does this for
you). Actions -> Show action list -> New action -> Load ReaScript, and pick
`Good Idea.lua`. It is then in the action list, where you can run it, give it
a shortcut or put it on a toolbar. Running it again closes the window; Escape
closes it too.

### If something goes wrong

**It says it needs ReaImGui.** The extension is not installed, or REAPER has
not been restarted since it was.

**It errors on the line that loads ReaImGui.** Your ReaImGui is older than the
version the script asks for; update it through ReaPack.

**It cannot find `gi_theory.lua`.** The five files are not in the same folder.

**Audition makes no sound.** It plays through REAPER's virtual MIDI keyboard,
so it needs a track that is record-armed with input monitoring on, with an
instrument on it. Insert and Export do not need that.

**The drums play as piano notes.** The instrument on the track is not a drum
kit. Put the Drums track (or the whole item, in one-item layout) through a
General MIDI drum instrument.

## Checking it

For anyone changing the code: `tools/test.sh` runs every test. The tests run
the real engine and the real window against stand-ins for REAPER and ReaImGui
and check over half a million things about what comes out - that every note
is in the key, that the tune is on the chord on every beat, that phrases end
on real cadences, that a Loop's chords really do go round, that the drums are
on channel 10, that every button in the window can be clicked. See
[CLAUDE.md](CLAUDE.md) for how it fits together, and
[docs/decisions](docs/decisions/) for why it is the way it is.

The keys, scales and note spelling are
[ScaleView for REAPER](https://github.com/KallumS/ScaleView-for-Reaper)'s,
unchanged, so the apps agree. The chord names are
[Starting Blocks](https://github.com/KallumS/Starting-Blocks)'. The window,
the colours, the MIDI writer and the way ideas are put into the project are
[Midi Catalogue](https://github.com/KallumS/Midi-Catalogue)'s, and the dice
are [Midi Variator](https://github.com/KallumS/Midi-Variator)'s. When an idea
is in, [Midi Suggester](https://github.com/KallumS/Midi-Suggester) and Midi
Variator are the natural next step.
