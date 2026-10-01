# 0005. Every setting can be left to chance, and each takes its own draw

Taken 2026-10-01. Stands.

## Context

"Feature every setting within the GUI", and "a New Idea button that
generates a new clip of the selected type at random". Some people starting a
track know their key and tempo and want everything else to surprise them;
some want a surprise key too; some have found a feel they like and want only
the notes to change.

## Decision

- **Every musical setting is a row of buttons in the window**, from one list
  (`I.SETTINGS`), and most begin with **Any**. Any is rolled for every idea;
  a chosen value stays. Hovering Any says what this idea rolled.
- **Each setting takes one draw of the dice whether it is on Any or not**
  (`I.resolve`). So fixing one setting - to anything - never changes what
  the others roll.
- **Keep** turns every Any on screen into what this idea rolled, and because
  of the above, the idea does not change: from then on New Idea changes only
  the music.
- **A setting that does not show does not count.** Chords settings under a
  Motif, melody settings under a chords-only Phrase are hidden, not greyed
  (the house rule: no dead controls), and the idea does not depend on them.
- Any rolls the common choices where the full list is for choosing: the
  twelve usual key spellings (not C# and Db both), and the scales a tune is
  usually in (not blues, whole tone or diminished, which are there to pick).
- The idea number, Keep, back and forward, and Play new ideas are in the
  window too; the tempo and time signature are the project's and are shown,
  not set.

## Consequences

- The tests hold every part of this: every value of every setting has a
  button and can be chosen, Any rolls every value it offers, fixing one
  setting leaves the other rolls alone, Keep gives the same idea back, hidden
  settings change nothing.
- Defaults lean towards surprise: everything on Any except the key (C major),
  the register (Middle), drums (on), layout (tracks) and velocity (flat).

## Alternatives

**A single "randomise" switch.** Rejected: all or nothing, when the useful
thing is to keep what you like and roll the rest.

**Drop-down menus.** Rejected as in every sister repo: buttons keep every
choice visible and one click away.
