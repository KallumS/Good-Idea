# 0030. The window's text follows Apple's writing guidelines

Taken 2026-10-15. Stands. Follows Noterator's
[0053](https://github.com/KallumS/Noterator/blob/claude/adoring-feynman-bihxp2/docs/decisions/0053-writing-the-way-the-mac-does.md),
which set the same rules for Noterator and Miderator, where Good Idea's
settings are shown too.

## Context

The user asked for every window in their projects to follow Apple's Human
Interface Guidelines on writing
(developer.apple.com/design/human-interface-guidelines/writing), as had just
been done for Noterator and Miderator. Good Idea had grown its own habits:
buttons in sentence case ("Insert at cursor", "Open folder"), "Choose
folder..." with three full stops, " - " for a dash, straight quotes in the
hints, a row labelled "Make a" (which only read as English with the button
after it), and messages like "No track selected" that said what was wrong
but not what to do.

## Decision

- **Buttons, toggles and dialog titles** are in title-style capitals, a verb
  first where they act: Insert at Cursor, Insert on New Tracks, Export MIDI
  File, Open Folder, Play New Ideas, Choose a Folder for MIDI Files.
- **A setting's values are labelled in title style** where they have more
  than one word: 2 Bars, 1.5 a Bar, One Item, Half-Time, Four on the Floor,
  At the End, Every 4 Bars, Step Up, Half Step Up, Truck Driver (and, for the
  hidden settings, By the Book, Any Named, On the Beat, With the Chords). In
  Noterator and Miderator these are the items of a pop-up menu.
- **The stored values do not change.** "One item", "Every 4 bars", "Truck
  driver" and the rest are what is saved and what the dice roll; only the
  label (`name(v)`, through `I.valueName`) is new. `barsName` stays as it was
  for the item's name and the .mid file's name, which keep plain ASCII.
- **A setting's row label is a label, in sentence case**, the way Noterator
  writes its own ("Chord pace", "Bass line"): Chord pace, Second voice, Key
  change, Ghost notes. **"Make a" is now "Kind"**: a noun like the labels
  beside it (Bars, Content), and the word the code, the docs and the README
  already use for Motif, Phrase, Measure and Drums. "Idea" was the other
  candidate, but it is the step's own name, so the row would have read
  "Idea / Idea".
- **"…"** (one character) after Choose Folder…, which asks for a folder
  before it acts.
- **Hints, tooltips and the status line** are in sentence case; complete
  sentences end with a full stop. An em dash (—) between phrases, curly
  quotes and apostrophes (“and”, guitarist’s).
- **Messages say what happened, then what to do**: "No track is selected.
  Select a track, then insert."; "Couldn’t write to … Choose another folder
  below."; "Saved “Good Idea 12 - Motif ….mid”. Open Folder shows it."
- Chord symbols, note and scale names (ScaleView's, copied unchanged), the
  chord line's marks (^ _ * > C/E), the step names and the "+" and "-" on a
  folded step are left as they were.

## Consequences

- `gi_idea.lua` is vendored unchanged into Noterator and Miderator
  (`Engines/GoodIdea/`), so the new labels and hints reach them when they
  copy it across. Their adapters read `s.label`, `I.valueName` and `s.hints`;
  Noterator hides the Key and Scale rows by their labels, which did not
  change. Its text reaches JUCE as `std::string`, which `juce::String` reads
  as UTF-8, so the dashes and quotes come through.
- The tests click the new labels; the values they set are the old ones.
- New text follows the same rules.
