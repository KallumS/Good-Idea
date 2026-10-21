# Review against Apple's Human Interface Guidelines: Foundations

Good Idea checked against all 19 Foundations pages (the user's copy,
October 2026), the same review Transient Shuffler had. Writing was done
first, on its own ([0030](decisions/0030-the-windows-text-follows-apples-writing-guidelines.md));
this covers the rest ([0031](decisions/0031-apples-hig-foundations.md)).

The window is drawn by ReaImGui inside REAPER, so some guidance cannot apply:
a script cannot reach VoiceOver, Dynamic Type or Increase Contrast, or read the
system's appearance. Where a guideline is not met for that reason, this says
so rather than counting it as met.

## What changed (1.18)

| Guideline | Before | Now |
| --- | --- | --- |
| **Accessibility: the keyboard alone** | Mouse only. | Keyboard navigation is on: Tab and the arrow keys move between controls, Space or Return presses one, and a near-white ring shows where you are. |
| **Accessibility, Typography: larger text** | One fixed size. | **View → Text Size**: 100%, 125%, 150% or 200%, also Cmd+= and Cmd+- (Ctrl on Windows), Cmd+0 for 100%. Remembered between runs. Buttons grow with the text and rows wrap at the window's edge. |
| **Typography: default size** | ReaImGui's own font. | The system's sans-serif at 13 points, the Mac's default text size. |
| **Accessibility: control size and spacing** | Buttons 19 points tall, 8 apart. | 28 points tall (Apple's Mac default) with 12 between them. |
| **Accessibility, Dark Mode: contrast** | Secondary text 4.7:1, warnings 3.4:1. | Every line of text is at least 7:1, the target for small text in a dark window: secondary text `#B0B6C0` (7.4:1), warnings `#FF9E96` (7.6:1). The house red is no longer used for words. |
| **Accessibility, Color: more than colour alone** | A chosen button was shown only by being yellow. | It also has a dark bar under its label. |
| **Layout: nothing important at the bottom of a window** | The message line came last, under the output buttons. | It sits at the top, above step 1. |
| **Accessibility: avoid time-boxed elements** | (Messages stayed, but could not be cleared.) | A message stays until **Dismiss**, or a newer one replaces it. |

## Already met

- **Design principles.** An idea is a number: the same number and settings always give the same idea, so nothing is lost by trying another, and back and forward walk the history like a browser's. Every step but Idea folds away. Insert is one REAPER undo step; nothing in the project changes until you insert.
- **Feedback.** Controls change on hover and press; a folded step says what it holds; the roll shows the idea and a playhead while it plays; Audition turns into Stop.
- **Playback you control.** *Play New Ideas* and *Play with REAPER* are switches you can turn off, and Stop or REAPER's own stop ends playback.
- **Colour.** Only the tune takes the accent in the roll; chords and bass take the controls' grey (decision 0009).
- **Motion.** Nothing animates except the playhead, which follows playback.
- **Dark Mode.** Always dark. Apple allows this for apps built around media,
  and advises against an app-only appearance setting; it is also the house
  scheme.
- **Writing.** Decision 0030.
- **Privacy.** Nothing is collected or sent. Preferences and the export folder are saved in REAPER's own settings; a .mid goes where you choose.
- **Inclusion.** Plain musical words; the tooltips explain each choice.

## Not met, because a ReaImGui script can't

- **VoiceOver, Voice Control and Switch Control** cannot read a ReaImGui
  window.
- **Dynamic Type and Increase Contrast** cannot be read from a script. Text
  Size and the 7:1 colours stand in for them.
- **Right to left.** The window is English only; time runs left to right, as in
  every DAW.

## Not relevant

Materials (Liquid Glass), app icons, icons and SF Symbols, images, spatial
layout and immersive experiences: the window has none of these.

## Unverified in REAPER

- Whether REAPER hands Cmd+=, Cmd+- and Cmd+0 to the window (the View menu
  does the same either way).
- Which face "sans-serif" gives on each system (Helvetica or San Francisco on
  a Mac, Segoe UI or Arial on Windows).

## Checked by

`tests/test_ui.lua` with `tests/hig_mock.lua` (the family's shared checks): keyboard navigation on and its ring not the accent; 13-point text, 28-point controls, 12 points apart; every line of text 7:1 on the ground and every button's ink 7:1 on its fill; a bar on every chosen button; the warning above everything else, still there twenty frames later, gone on Dismiss; the View menu's sizes, the keys, every button wide enough for its label at 200%, the size saved under its own key, clamped and restored. Each was broken on purpose and the suite failed - a button narrower than its label only when both `flow()`'s and `pick()`'s measures are broken, since either alone keeps it wide enough.

## Final sweep (16 October 2026) - 1.19

Every guideline of the 19 Foundations pages that a custom-drawn window can
act on, checked again against the page itself, measured rather than
guessed, with the choices the family's windows share (Midi Suggester 1.3,
Midi Variator 1.5, both Starting Blocks, Midi Catalogue 1.3). What changed,
in a musician's words:

- **Menus and tooltips are lighter than the window**, not darker, as Apple's
  dark surfaces are; ImGui's blue menu highlight and grey menu bar are gone,
  and the keys written beside a menu item (Cmd+=) are 7:1 on the menu.
- **Things you can see and grab are 3:1 or more**: the scrollbar thumb, the
  resize corner, and the tick boxes, the idea number's field and the swing
  slider, which now have an edge (they were 1.1:1 on the background).
- **Esc lets go first**: of the control the keyboard ring is on, of an open
  menu, of the idea number being typed - which used to close the window.
- **Stop is always in sight**: whenever anything plays - Audition, Play New
  Ideas, Play with REAPER - it is in the menu bar. Both switches that make
  it play by itself were already remembered.
- **Keep can be undone**: an Undo beside its message turns the Anys back.
- **Nothing runs off the edge**: the New Idea row, the output row, settings
  side by side, folded steps' summaries and messages wrap at 200%; tooltips
  are broken into lines of about 64 characters (Play with REAPER's ran to
  about 400); the window has a smallest size (400×300, grown with the text).
- **The roll from the keyboard**: Space on it plays from the top (it used
  wherever the pointer happened to be). Its tooltip also says the tune is
  yellow and the chords and bass grey.
- **The title names the idea showing**, which is what a screen reader can
  read of the window.

Only REAPER can confirm: that Esc reaches the window and ImGui lets go of
focus on it; that the menu bar's Stop sits well beside the View menu; how
the lighter menus look on a real screen.

| Item | Guideline (paraphrased) | Verdict | Here |
| --- | --- | --- | --- |
| ACC-01 | Interactions should be familiar and behave the same everywhere | met | Same buttons, keys and words as the sister windows |
| ACC-02 | Never carry information by one sense or channel only | met | Chosen buttons carry an ink bar; playing shows Stop and a playhead; the roll's tooltip names its colours |
| ACC-03 | Adapt to people: honour their system settings or let them personalise | met | Text Size in the window; system settings cannot reach it |
| ACC-06 | Let text be enlarged to at least 200% | met | Text Size 100–200% |
| ACC-07 | Let icons and glyphs grow too, not only words | met | <, >, ticks and the ink bar are text or go through px() |
| ACC-08 | macOS type: 13 pt by default, never below 10 pt | met | One size, 13 pt; nothing smaller |
| ACC-09 | Thin weights need bigger sizes | met | Regular weight only |
| ACC-10 | Minimum contrast: 4.5:1 for text up to 17 pt; 3:1 at 18 pt and above or in bold | met | Every word 7:1 |
| ACC-11 | Contrast also applies to icons, not only text | fixed now | Scrollbar thumb 3.6:1 (was 2.6), resize corner 3.3:1 (was ImGui's blue); the tick boxes, idea-number field and swing slider got a 4.7:1 edge (were 1.1:1); notes and playhead already far above 3:1 |
| ACC-13 | Check contrast in every appearance you ship | met | One palette |
| ACC-15 | Use shape, icon or text as well as colour | met | Chosen = colour + bar; warnings are worded |
| ACC-16 | Watch the colour-blind pairings (red–green, blue–orange) | met | No two states differ by hue alone |
| ACC-17 | Consider letting people recolour charts and characters | user's decision | The three colours are settled by the user |
| ACC-18b | (derived) VoiceOver can at least read a window's title | fixed now | The title names the idea showing ("Good Idea — Good Idea 4182 - Motif …") |
| ACC-18c | Native dialogs reach VoiceOver | met | Choosing a folder uses js_ReaScriptAPI's dialog or REAPER's GetUserInputs |
| ACC-21 | Pair audio cues with visual cues | met | Every playback shows a playhead and Stop |
| ACC-22 | macOS control size: 28×28 pt by default, 20×20 pt at the least | met | Every button 28 pt tall and at least 28 wide |
| ACC-23 | About 12 pt of space around controls with a bezel | met | 12 pt apart |
| ACC-24 | About 24 pt of space around clickable things with no bezel | met | The roll is the one frameless target: 130 pt tall, the window wide |
| ACC-25 | Use the simplest gesture for frequent actions | met | Single clicks only |
| ACC-26 | Every gesture has an on-screen alternative | fixed now | Clicking the roll plays from a beat; Space on it from the keyboard now plays from the top (it used wherever the pointer was) |
| ACC-28 | Siri and Shortcuts for voice and automation | user's decision | Exposing commands as REAPER actions is a new feature; not asked |
| ACC-29 | Work with Full Keyboard Access, Switch Control and Pointer Control | met | Keyboard navigation |
| ACC-30 | Everything works from the keyboard alone | met | Every control reachable by Tab |
| ACC-31 | Don't override system shortcuts | met | Only Cmd+=, Cmd+-, Cmd+0; nothing of the Mac's own |
| ACC-32 | Keep actions simple; prefer familiar system behaviour over custom | fixed now | Esc lets go of focus, a menu or the idea number being typed before it closes the window (it closed the window mid-typing) |
| ACC-33 | Avoid UI that times out; dismiss explicitly | met | Messages stay until Dismiss; nothing times out |
| ACC-34 | Offer difficulty accommodations in games | not applicable | Not a game |
| ACC-35 | Never autoplay sound without visible start and stop controls; offer an opt-out | fixed now | Play New Ideas and Play with REAPER are switches, remembered; now Stop is in the menu bar whenever anything plays, so it can't scroll away |
| ACC-37 | Be careful with fast or blinking animation; under Reduce Motion, cut automatic or repeating zoom, scale and peripheral motion | met | Only the playhead moves |
| ACC-38 | Reduce Motion: stiffen springs, no bounce | met | No springs |
| ACC-39 | Reduce Motion: motion follows the pointer directly | met | No drags |
| ACC-40 | Reduce Motion: no animated depth changes | met | No zooms |
| ACC-41 | Reduce Motion: fade instead of sliding | met | Changes are immediate |
| ACC-42 | Reduce Motion: don't animate into or out of blur | met | No blur |
| ACC-43 | Confirm before hard-to-undo actions | fixed now | Keep leaves an Undo beside its message; back and forward walk the ideas |
| APP-14 | No replicas of Apple hardware in any artwork | not applicable | No artwork |
| BRA-01 | One voice and tone in every piece of copy | met | House words (Audition, Use Selected Items) |
| BRA-02 | Use the accent colour sparingly: the primary action, status and the selected item, not every control | met | Yellow only for on |
| BRA-03 | Brand colour can live in the content rather than on controls | met | Notes in the accent |
| BRA-04 | A custom font must be legible at every size and scale with the text setting; use the system font for body text and captions | met | System sans |
| BRA-05 | Express the brand through familiar components; keep standard size, placement and behaviour | met | ImGui buttons |
| BRA-06 | Branding gives way to content: no space spent only on a logo | met | No logo |
| BRA-07 | Standard patterns: controls in expected places, standard symbols, standard navigation and modality | met | Menu bar, steps |
| BRA-08 | Don't repeat the logo through the app | met | No logo |
| BRA-09 | No branded launch or splash screen; a welcome screen is fine | met | Opens on the last state |
| BRA-10 | Keep Apple trademarks out of names and images | met | No Apple names |
| COL-01 | One colour, one meaning; never style static text in the "interactive" colour | met | Accent never on plain text |
| COL-02 | Colours work in light, dark and increased contrast | met | Dark only; system modes not readable |
| COL-04 | Test under bright and dim lighting | not possible | Only on a real screen; for the user |
| COL-05 | Test on several displays and colour profiles (sRGB vs P3, True Tone) | not possible | Only on a real screen; for the user |
| COL-06 | Artwork and translucency change how nearby colours look; adjust the neighbours | met | No text over the roll |
| COL-07 | If people pick colours, use the system colour picker | user's decision | No colour choice (settled) |
| COL-08 | Never rely on colour alone to tell objects or states apart, show interactivity or carry essential information | met | See ACC-15 |
| COL-09 | Avoid hard-to-see combinations | met | Tune yellow and chords grey differ by lightness as well as hue (1.9:1); the roll's tooltip now says which is which |
| COL-10 | Colours mean different things in different cultures | met | Warnings are worded |
| COL-12 | Each palette role only for its job | fixed now | #8A919C no longer for any word: a menu's keys are #BFC5CE |
| COL-14 | Emphasise a primary action with a filled background, not coloured label text; don't fill many controls with the accent | met | No accent-filled primary button; accent = chosen |
| COL-15 | Over colourful content, keep control labels monochrome, or pick an accent clearly unlike the content | met | Labels monochrome |
| COL-16 | Keep content colours from clashing with control colours where they meet; legible at rest | met | Roll on its own ground |
| COL-17 | Embed a colour profile in images (sRGB is fine) | not applicable | No images |
| COL-21 | Alternate row backgrounds | not applicable | No lists or tables |
| COL-22 | Show selection more softly when the window isn't key | user's decision | Dimming selection when REAPER has focus would make a tool window look off while you work; left as is |
| COL-24 | (tvOS) Don't show focus by colour alone | met | Focus ring is a shape |
| COL-25 | (visionOS) Colour works best in bold text and large areas | met | Accent on large fills only |
| COL-26 | (visionOS) Balance brightness; no bright flashing object on a black ground | met | No flashes |
| COL-27 | (watchOS) Colour a background only when it says something; avoid full-window colour on long-lived views | met | No coloured backgrounds |
| DRK-04 | A dark-only interface is fine in rare, media-focused cases | met | Dark only: house scheme, studio use (review above) |
| DRK-05 | A dark palette is not an inversion: dim the backgrounds, brighten the foregrounds | met | Ramp |
| DRK-07 | Contrast 4.5:1 at minimum, aiming for 7:1 for small text | met | 7:1 |
| DRK-08 | Soften white backgrounds in images shown in a dark context | not applicable | No white page |
| DRK-10 | Give an edge to icons that would vanish on a dark ground | met | No dark glyphs on dark |
| DRK-11 | Full-colour images must read in your appearance; adjust them if not | not applicable | No pictures |
| DRK-12 | Use the label tiers (primary to quaternary) | met | Body, secondary, step tiers |
| DRK-13 | Prefer system text fields | met | The idea number is ImGui's field; Choose Folder… falls back to REAPER's own dialog |
| DRK-14 | Raised surfaces lighter | fixed now | Menus and tooltips #2A2F37 with a #3A404A edge (were #1B1F25, darker than the window); menu bar and highlight in house greys |
| DP-01 | Every feature serves the app's purpose | met | See "Already met" |
| DP-02 | Focus: make the core features excellent | met | See "Already met" |
| DP-03 | Don't rebuild what already exists; find your own angle | met | See "Already met" |
| DP-04 | Stay out of the way: take people straight to the task | met | See "Already met" |
| DP-05 | Freedom to explore; no lock-in modes; guided flows can be skipped or escaped | met | See "Already met" |
| DP-06 | Make mistakes cheap to recover from | fixed now | Insert is one REAPER undo step; ideas have back and forward; Keep can now be undone |
| DP-07 | Be transparent about background behaviour | met | Play with REAPER's tooltip says what it does and when it never plays |
| DP-08 | Collect only what's needed and keep it safe | met | See "Already met" |
| DP-09 | Build on concepts people know (the real world and other software) | met | See "Already met" |
| DP-10 | Once a look or behaviour is set, apply it everywhere | met | See "Already met" |
| DP-11 | Clear feedback: show what's available, show when content changes, use system patterns for alerts and choices | met | Hover, press, chosen, playing all distinct |
| DP-12 | Design for everyone; accessibility from the start | met | See "Already met" |
| DP-13 | Preserve context | user's decision | Steps fold by the user's choice (decision 0012) |
| DP-14 | Support many input methods | met | See "Already met" |
| DP-15 | Equal care on every platform supported | not possible | Only the user can run it on Windows and Linux |
| DP-16 | Include only what's needed; let secondary items recede | met | See "Already met" |
| DP-17 | Be concise in labels and copy | met | See "Already met" |
| DP-18 | Clear hierarchy: people know where they are and what's next | met | See "Already met" |
| DP-19 | Craft: deliberate visuals, smooth motion, precise words, thoughtful sound | met | See "Already met" |
| DP-20 | Prototype, iterate, and test in real settings | not possible | Needs REAPER; see below |
| DP-21 | Keep maintaining after release | met | See "Already met" |
| DP-22 | Decide the emotion to evoke | met | See "Already met" |
| DP-23 | Treat small moments, error messages included, as chances for character | met | See "Already met" |
| DP-24 | Delight is not decoration; never at the task's expense | met | See "Already met" |
| ICN-01 | Simple, recognisable glyphs, using a metaphor tied directly to the action or content | not applicable | No icons: < and > are text, with tooltips |
| ICN-02 | All interface icons share size, detail, stroke weight and perspective | not applicable | No icons: < and > are text, with tooltips |
| ICN-03 | Adjust dimensions optically so light and heavy shapes look equal | not applicable | No icons: < and > are text, with tooltips |
| ICN-04 | Match an icon's weight to the text beside it | not applicable | No icons: < and > are text, with tooltips |
| ICN-05 | Centre asymmetric glyphs optically, not geometrically (pad them) | not applicable | No icons: < and > are text, with tooltips |
| ICN-06 | Make a separate selected-state icon only when needed | not applicable | No icons: < and > are text, with tooltips |
| ICN-07 | Inclusive imagery: gender-neutral figures, nothing culture-bound | not applicable | No icons: < and > are text, with tooltips |
| ICN-08 | Letters in an icon only when essential, and localised | not applicable | No icons: < and > are text, with tooltips |
| ICN-09 | Vector icons, or bitmaps at every scale | not applicable | No icons: < and > are text, with tooltips |
| ICN-10 | Text names for icon-only controls | met | < and > have tooltips (Back, Forward) |
| ICN-11 | No replicas of Apple hardware | not applicable | No icons: < and > are text, with tooltips |
| ICN-12 | Use the standard meanings: scissors = cut, two pages = copy, clipboard = paste, check = done or save, X = cancel or close, trash = delete, curved arrows = undo and redo, + = add, … = more, pencil = rename, folder, magnifier = search, three lines = filter, box with up arrow = share or export, printer = print | not applicable | No icons: < and > are text, with tooltips |
| IMG-01 | Lay out in points; the scale factor maps points to pixels | met | Sizes through px() |
| IMG-02 | macOS needs @1x and @2x bitmaps | not applicable | No images; sizes through px() |
| IMG-03 | Design at 1×; put vector points and edges on whole points so they stay crisp at 2× | not applicable | No images; sizes through px() |
| IMG-04 | Formats: de-interlaced PNG; an 8-bit palette when full colour isn't needed; JPEG or HEIC for photos; PDF or SVG for flat art | not applicable | No images; sizes through px() |
| IMG-05 | Embed a colour profile | not applicable | No images; sizes through px() |
| IMG-06 | Test images on real screens | not applicable | No images; sizes through px() |
| IMM-02 | Offer several ways to use it and respect accessibility settings | not applicable | No immersive stages |
| IMM-03 | Start in the least immersive mode; let people opt in | not applicable | No immersive stages |
| IMM-04 | Save immersion for meaningful moments | not applicable | No immersive stages |
| IMM-05 | Guide attention with gentle cues first, and stronger ones only if needed | not applicable | No immersive stages |
| IMM-09 | Don't require people to move | not applicable | No immersive stages |
| IMM-12 | Smooth, predictable transitions | not applicable | No immersive stages |
| IMM-13 | Let people choose when to enter and leave; a clear exit | not applicable | No immersive stages |
| IMM-14 | The exit says whether it goes back or quits; offer to save before quitting | not applicable | No immersive stages |
| IMM-16 | Environments: few distractions, subtle animation, nothing moving at the edges | not applicable | No immersive stages |
| IMM-17 | Mark interactive objects clearly | not applicable | No immersive stages |
| IMM-18 | Preview doesn't stack on playback unexpectedly | met | Play with REAPER plays along on purpose, says so, and never while recording |
| INC-01 | Learn people's goals and perspectives; keep revising | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-02 | Weigh age, gender, culture, ability, education, economics and more | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-03 | Inoffensive isn't the same as inclusive | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-04 | Plain, welcoming tone, not academic | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-05 | Address people as "you"; avoid "the user" or "the player"; keep "we" for the maker | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-06 | Define specialised terms, or say it plainly; make definitions easy to find | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-07 | Swap idioms and colloquialisms for plain words | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-08 | Be careful with humour (it translates badly and wears thin) | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-09 | Approachable: a clear interface, with a way to learn that experts can skip | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-10 | Drop needless gender references ("his or her") | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-11 | Avatars, glyphs and characters not gendered, or customisable | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-12 | Generic people drawn as non-gendered figures | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-14 | Show varied people; avoid role stereotypes | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-15 | Relatable settings and objects; don't assume wealth | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-16 | Question built-in assumptions (family, life events) | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-17 | Support accessibility features; never assume disability means no interest | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-18 | Disability is a spectrum, and also temporary or situational | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-19 | No disability used as a negative ("blind to", "lame", "crippled", "dumb", "sanity check") | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-20 | People-first wording about disability | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-21 | Simple and perceivable | met | Plain musical words; hints explain terms; no gendered or ableist words (grepped) |
| INC-22 | Prepare for other languages and regions (date, time, number formats) | not applicable | English only |
| INC-24 | Check what colours mean in each locale you localise for | not applicable | English only |
| LAY-01 | Most important items at the top and leading edge | met | Steps top to bottom |
| LAY-02 | Align for scanning; indent to show subordination | met | Step headings, rows under them |
| LAY-03 | Group related items with space, containers or separators | met | Numbered steps with gaps |
| LAY-04 | Progressive disclosure | met | Every step but Idea folds |
| LAY-05 | Make controls look distinct from content | met | Dark roll apart from the controls |
| LAY-07 | Adapt to window sizes, aspects and displays; respect margins | fixed now | Correct from the smallest size to full screen at 100% and 200% (tested) |
| LAY-08 | Text growth: wrap instead of crop | fixed now | The New Idea row, the output row, settings side by side, folded summaries and messages now wrap; the New Idea row ran off the edge at 200% |
| LAY-09 | Test the largest and smallest layouts | fixed now | Tested: nothing runs off the edge in every kind, folded and open, playing, warned, at 100% and 200% and the smallest width |
| LAY-10 | Scale background art to fill without changing its aspect ratio | not applicable | No art |
| LAY-11 | (iOS) Lay out by available space (size classes), not device | met | Rows reflow on width |
| LAY-12 | Same functions at every size; extras can move into an overflow | fixed now | Everything wraps, so nothing is out of reach |
| LAY-13 | The layout stays recognisable after a resize | met | Same order at any size |
| LAY-14 | Limit line length | fixed now | Tooltips broken at 64 characters (Play with REAPER's ran to about 400) |
| LAY-15 | Respect safe areas | not applicable | Hosted window |
| LAY-16 | (macOS) No controls or critical information at the window's bottom edge | met | Message at the top |
| LAY-19 | (tvOS) Even spacing in grids | met | One gap |
| LAY-20 | (visionOS) Allow resizing; a min and max size stop overlap, but don't use them to block resizing | fixed now | A smallest size, 400×300 grown with the text |
| LAY-21 | (visionOS) Centre content in very large windows | not applicable | Left-aligned rows wrap; nothing to centre |
| MAT-02 | Over bright content, put about a 35% dark dimming layer behind clear-glass controls | met | No text over graphics |
| MAT-03 | Pick materials by meaning, not by the tint they give | met | Colours by role |
| MAT-05 | Thicker (more opaque) backings for fine text; thinner ones keep context | met | No translucent fills |
| MAT-09 | (derived) Reduce Transparency equivalent | met | Solid window |
| MOT-01 | Only purposeful motion | met | Only the playhead moves, with the music |
| MOT-02 | Motion is optional and never the only carrier of information | met | Only the playhead moves, with the music |
| MOT-03 | Feedback motion follows the gesture and expectation | met | Only the playhead moves, with the music |
| MOT-04 | Feedback animation is short and precise | met | Only the playhead moves, with the music |
| MOT-05 | No added motion on frequent interactions | met | Only the playhead moves, with the music |
| MOT-06 | Motion can be cancelled; never make people wait for it | met | Only the playhead moves, with the music |
| MOT-08 | Games: a steady 30–60 fps by default | not applicable | Not a game |
| MOT-09 | Let people trade visuals for performance or battery | met | Only the playhead moves, with the music |
| MOT-10 | (visionOS) No motion in the periphery; large moving objects; no rotating world | met | Only the playhead moves, with the music |
| MOT-11 | (visionOS) Fade, don't fly, when relocating | met | Only the playhead moves, with the music |
| MOT-12 | (visionOS) A stationary frame of reference | met | Only the playhead moves, with the music |
| MOT-13 | (visionOS) Avoid sustained oscillation, worst near 0.2 Hz (a 5-second cycle); keep the amplitude low | met | Only the playhead moves, with the music |
| MOT-15 | (derived, ACC) No flashing above 3 per second | met | Only the playhead moves, with the music |
| PRV-01 | Ask only for what you need | met | Nothing collected or sent; settings and the export folder in REAPER's ExtState |
| PRV-02 | Be transparent about what's collected and how it's used | met | Nothing collected or sent; settings in REAPER's ExtState |
| PRV-03 | Process on the device | met | Nothing collected or sent; settings in REAPER's ExtState |
| PRV-04 | Use system protections and secure practices | met | Nothing collected or sent; settings in REAPER's ExtState |
| PRV-06 | Ask at the moment of use, not at launch | met | Nothing collected or sent; settings in REAPER's ExtState |
| PRV-13 | Never keep passwords or secrets in plain-text files | met | Nothing collected or sent; settings in REAPER's ExtState |
| PRV-16 | (macOS) Don't assume who is signed in (fast user switching) | met | Nothing collected or sent; settings in REAPER's ExtState |
| RTL-04 | Every item in a list uses the same alignment | met | One alignment |
| RTL-10 | Never flip a control that means a real direction | not applicable | English only |
| SFS-03 | Licence: no SF Symbols, or look-alikes, in app icons, logos or trademarks | not applicable | No icons |
| SFS-04 | Rendering modes (monochrome, hierarchical, palette, multicolour) | not applicable | No icons |
| SFS-05 | Check icon legibility at each size and background | not applicable | No icons |
| SFS-07 | Variable colour shows a changing level (0–100%), not depth | not applicable | No level icons |
| SFS-08 | Match symbol weight to the text weight | not applicable | No icons |
| SFS-09 | Size icons against the text's cap height (small, medium, large) | not applicable | No icons |
| SFS-10 | Variant conventions: slash = unavailable or off; fill = selected; enclosed = clearer at small sizes; outline next to text | not applicable | No icons |
| SFS-12 | Animate symbols sparingly, with purpose, in keeping with the app's tone | not applicable | No icons |
| SFS-13 | Animation meanings: bounce = something happened; pulse or breathe = ongoing; rotate = working; variable colour = progress; wiggle = look here | not applicable | No icons |
| SFS-14 | Custom symbols match the system set: simple, recognisable, inclusive, directly related | not applicable | No icons |
| SFS-15 | Negative side margins so badged icons align optically | not applicable | No icons |
| SFS-19 | No Apple product replicas | not applicable | No icons |
| SPA-03 | Use depth for hierarchy, on big elements, only where it adds value | met | No depth |
| SPA-04 | Don't give text depth | met | No text shadows |
| SPA-05 | Don't open too many windows | met | One window |
| SPA-07 | Leave room round interactive elements (≥16 pt gaps there); never overlap them | met | No overlapping targets |
| SPA-08 | Usable with little physical movement | met | Steps in reading order |
| TYP-01 | macOS: 13 pt default, 10 pt minimum | met | 13 pt |
| TYP-02 | Test legibility in context; fix with size, contrast or a more legible face | not possible | Needs a real screen |
| TYP-03 | Avoid Ultralight, Thin and Light; use Regular through Bold | met | Regular |
| TYP-04 | Hierarchy through weight, size and colour, kept when text is scaled | met | Ratios kept: one size scaled |
| TYP-05 | Few typefaces | met | One face |
| TYP-06 | When scaling, the important content grows; minor chrome may not | met | Everything grows |
| TYP-07 | Use the system font (SF Pro on macOS) | met | System sans |
| TYP-08 | Don't embed or bundle the system fonts | met | No fonts shipped |
| TYP-09 | Use the macOS text styles: Large Title 26/32, Title 1 22/26, Title 2 17/22, Title 3 15/20, Headline 13 Bold/16, Body 13/16, Callout 12/15, Subheadline 11/14, Footnote 10/13, Caption 1 10/13, Caption 2 10 Medium/13 | met | Body 13 throughout |
| TYP-10 | Emphasise with the bold trait (Body emphasised = Semibold; Headline = Heavy) | user's decision | No bold headings: would change the family's look; offered |
| TYP-11 | Looser leading for long or wide passages; tight leading only up to 2 lines | not possible | ReaImGui's line height is the font's |
| TYP-12 | Size-specific tracking (e.g. 10 pt +0.12 pt, 13 pt −0.08 pt, 17 pt −0.43 pt, 26 pt +0.22 pt) | not possible | ImGui has no tracking |
| TYP-13 | Custom fonts stay legible; follow the minimum sizes | not applicable | No custom font |
| TYP-14 | Custom fonts honour accessibility (Bold Text, size changes) | met | Text Size |
| TYP-16 | The layout adapts to every text size | fixed now | Rows wrap at every size |
| TYP-17 | Meaningful icons grow with the text | met | See ACC-07 |
| TYP-18 | Keep truncation to a minimum at large sizes; never truncate scrolling text without a way to read it all | met | Nothing truncated: wrapped instead |
| TYP-19 | Stack, or use fewer columns, at large sizes | fixed now | Rows stack when narrow |
| TYP-20 | Primary elements stay at the top at any size | met | Message and steps stay on top |
| TYP-21 | macOS control, menu and tooltip font variants match system controls | met | Labels and tooltips 13 pt |
| WRI-01 | Choose a voice; keep a list of terms; use them consistently | met | Shared words |
| WRI-02 | Fit the tone to the moment (plain for problems, lighter for success) | met |  |
| WRI-03 | Be clear; cut words; read it aloud | met |  |
| WRI-04 | Write for everyone: plain, accessible, translatable, without jargon or gendered terms | met |  |
| WRI-05 | Most important first; easy to read; split separate ideas | met |  |
| WRI-06 | Active voice; buttons lead with a verb; clear rather than cute | met | Verbs first |
| WRI-07 | Descriptive link text, never "Click here" | not applicable | No links |
| WRI-08 | Reuse language patterns | met |  |
| WRI-09 | One capitalisation style per kind of element, used throughout | met | Title style on controls |
| WRI-10 | Multi-step flows: consistent Get Started → Continue/Next → Done | not applicable | No multi-step flows |
| WRI-11 | Few possessives ("Favorites", not "Your Favorites"); one perspective | met |  |
| WRI-12 | Avoid "we" (errors read "Unable to …") | met | No "we" (grepped) |
| WRI-13 | The right verbs for the device ("click" on a Mac) | met | "click" |
| WRI-14 | Empty states say what to do | met | There is always an idea |
| WRI-15 | Nothing crucial only in a temporary state | met | Summaries of folded steps stay on screen |
| WRI-16 | Prevent errors first | met | No dead controls |
| WRI-17 | Show an error as close to the problem as possible | met | Messages at the top (family decision) |
| WRI-18 | No blame; say how to fix it, positively | met |  |
| WRI-19 | No "Oops" or "Uh-oh" | met |  |
| WRI-20 | If many people hit an error, redesign the interaction | met |  |
| WRI-21 | Choose how to deliver a message by its urgency | met | Status line, no dialogs |
| WRI-22 | Toggle hints describe the on state | fixed now | Loop's tooltip added; Play New Ideas and Play with REAPER already said |
| WRI-23 | Send people to a setting with a button, not directions | met | Text Size in the View menu |
| WRI-24 | Text fields: a clear label | met | "Idea number" beside its field |
| WRI-25 | Field errors beside the field | met | A number out of range is put in range, nothing to report |
| APP-01 | A distinctive app icon | not applicable | No toolbar art shipped |
| COL-11 | Don't hard-code system colours | met | Colours named by role in `THEME` |
| COL-20 | macOS's dynamic colour roles | met | A token for each role used: text, secondary, disabled, separator, focus ring |
