# Reading notes: the Educational Materials

Notes from reading the Educational Materials zip the user uploaded, written
for whoever works on Good Idea next. Each source: what it is, what it says
that bears on the engine, where Good Idea already agrees, and what it
suggests that Good Idea does not do yet ("Ideas"). Nothing here is a
decision; the decisions are in `decisions/`. Sources are kept in the zip,
not in the repo.

What is in the zip (about 870,000 words):

| | |
| --- | --- |
| `MusicTheory-Sep-2025_compressed.pdf` | Robert Hutchinson, *Music Theory for the 21st-Century Classroom* (University of Puget Sound, 2025 edition; GFDL). 35 chapters, fundamentals to minimalism. The book whose website is blocked from the container. |
| `Open Music Theory.zip` | 100 pages of *Open Music Theory* (Gotham et al.), saved from the web. |
| `List of chords - Wikipedia.html` | The chord table Good Idea's names come from (via Starting Blocks). |
| `pg33900.txt` | Rimsky-Korsakov, *Principles of Orchestration* (Project Gutenberg). |
| `pg73991.txt` | Esther Singleton, *The Orchestra and Its Instruments* (Project Gutenberg, 1917). (The Idiomatic Orchestra folder's `pg73991.html` is that book's own introduction, "Idiomatic Practice", not Singleton.) |
| `Berlioz Treatise on orchestration.html` | Berlioz, *Treatise on Instrumentation* (extract). |
| `Orchestration - Wikipedia.html` | The Wikipedia article. |
| `Alan Belkin.zip` | Alan Belkin's online orchestration course (7 pages and a PDF). |
| `The Idiomatic Orchestra.zip` | *The Idiomatic Orchestra* (online book, 23 pages). |
| `Orchestration Analysis.zip` | *Orchestration Analysis* (online, 6 chapters). |
| `ACTOR Orchestration.zip` | The ACTOR project's *Timbre and Orchestration Resource* (38 pages: every instrument family). |
| `The Orchestra User's Manual.zip` | *The Orchestra: A User's Manual* (155 pages, instrument by instrument). |
| `REAPER API functions.html`, `REAPER - ReaScript.html`, `JSFX Programming Reference.zip`, `REAPER - JSFX ... Language Essentials.html` | REAPER's scripting documentation (already used: every `reaper.` call was checked against the API page). |

## What it adds up to

Everything below was read for one question: what do these books say Good
Idea should do that it does not? Read in full: Hutchinson, the 100 Open
Music Theory pages (the post-tonal ones more quickly), Belkin,
*Orchestration Analysis*, *The Idiomatic Orchestra*, Rimsky-Korsakov's
chapters on melody and harmony, the general ACTOR pages, the List of
chords, the ReaScript page. Skimmed for what bears on Good Idea: the
instrument-by-instrument pages (ACTOR, the User's Manual), Berlioz's
excerpts, Singleton's history, the JSFX reference. Each section says which.

**Where Good Idea goes against the books** (each found in more than one):

1. **Doubling an inverted chord's bass.** G/B in Close plays B in the
   chord too: the leading tone doubled, the first error every harmony book
   names (Hutchinson ch. 26; Open Music Theory, basso continuo; Rimsky:
   "the bass of an inversion of the dominant chord should never be doubled
   in any of the upper parts").
2. **A seventh on a half cadence's V** (Mixed): "almost invariably a
   triad, rather than a seventh chord" (Open Music Theory, cadence types).
3. **Bass and chords too far apart, or crossing**: "the bass should rarely
   lie more than an octave from the part above it" (Rimsky; Hutchinson
   ch. 26 on spacing); no hole in the
   middle, no crossing (Belkin, *Orchestration Analysis*, *The Idiomatic
   Orchestra*). Not measured yet.
4. **The tune inside the chords**: one foreground, on top or apart; the
   accompaniment's top should "just touch" the tune (Belkin, *Orchestration
   Analysis*; Rimsky: a melody stands out least in the middle). Not
   measured yet.
5. **A seventh that doesn't fall by step** (Hutchinson ch. 27; Open Music
   Theory, tendency tones) and **parallel octaves and fifths between tune
   and bass** (Hutchinson ch. 26; Open Music Theory, counterpoint) - the
   voicer and the walk don't look.
6. **Every note at one velocity**: dynamics should be in the notes (Belkin,
   *The Idiomatic Orchestra*, ACTOR on the piano and on MIDI).
7. Smaller: two leaps the same way that don't outline a triad (Open Music
   Theory, cantus firmus); minor keys' cadences on the minor v rather than
   the leading-tone V (Hutchinson ch. 7).

**What they suggest adding**, most common first: **applied (secondary)
dominants**, the commonest chromatic chord in every style; **named
progressions and schemata** (doo-wop, singer/songwriter, Puff, lament,
Andalusian, double plagal, circle of fifths; the galant Meyer - Prinner -
cadence); **deceptive and evaded cadences** that stretch a phrase;
**accented non-chord tones** (appoggiatura, suspension) and anticipations;
the **hybrid theme forms** and the small ternary; accompaniment ideas - a
held **Pedal** chord style, the tune **doubled in thirds**, chords that fill
the tune's gaps; **dynamics by beat**; rhythms (clave, tresillo, the
3+3+2 family, the offbeat skank); a **key change** for a last section
(step-up, truck-driver); chord types 6/9 and the power chord. Details,
sources and how each would fit are in the sections below.

---

## Hutchinson, *Music Theory for the 21st-Century Classroom*

The most useful of all: it ties harmony to the phrase, uses pop examples
throughout, and teaches melody by motive and subphrase - the same way Good
Idea builds ideas.

### Ch. 1-3: pitch, major and minor scales

- Real music in minor mixes the three minor scales: natural minor's chords,
  with the **raised seventh at cadences** (harmonic minor's major V and
  vii). "The three minor scales are distillations of composers' actual
  practice."
- *Good Idea:* the Minor scale is natural minor, so its cadences use the
  minor v or VII (`T.cadenceChords`). Harmonic Minor gives the major V.
- *Idea:* a raised-seventh dominant at cadences in Minor (would need a
  setting: it changes old minor ideas).

### Ch. 4: rhythm

- Syncopation: notes on weak beats or weak parts of beats emphasised, nearby
  strong beats de-emphasised (ties across them). The common written-out
  exceptions are the 2-beat eighth-quarter-eighth and the 4-beat (3+3+2)
  patterns. *Agrees* with the Syncopated groove (Euclidean, turned off the
  beat) and 1.5 a bar (3+3+2).

### Ch. 6: triads

- sus4 and sus2 both keep a perfect fifth; the text does not invert sus
  chords; slash chords (C/E) name root then bass. *Agrees* with the
  flavours and inversions (0018).
- Power chords (C5, root and fifth) and incomplete chords (no fifth) are
  common in rock and pop. *Idea:* a "5" chord colour for rock.

### Ch. 7: Roman numerals and cadences

- Chords commonly used in minor: i, ii°, III, iv, VI, VII from natural minor;
  **V and vii°** from harmonic minor. The minor v and III+ are "rare".
- Four cadences: authentic (V I), plagal (IV I), **deceptive (V vi, or V to
  anything but I)**, half (ends on V).
- *Good Idea* has full (PAC), imperfect (IAC), half (HC) and open endings.
  *Idea:* a deceptive cadence - useful at the end of the first half of a
  Period or to extend a phrase.

### Ch. 8: seventh chords

- Five common sevenths: maj7, dominant 7, m7, half-diminished, diminished 7.
- **IV/5 (F/G in C), or ii7/5 (Dm7/G)** is a pop stand-in for V7 - "the
  sus dominant". *Idea:* a flavour for V (G9sus4 without its fifth).

### Ch. 9: harmonic progression and function

- Four functions: **tonic** (I); **tonic prolongation** (vi, iii: they share
  two notes with I, follow it, and lead to the pre-dominant);
  **pre-dominant** (IV, ii); **dominant** (V, vii°). Exceptions: the plagal
  IV I and deceptive V vi; I6/4 has dominant function before V; IV going to
  I is tonic prolongation.
- In pop, **bVII** can precede tonic, dominant or pre-dominant; endings
  VII IV I are common ("Hey Jude").
- Stock progressions, each with rotations: the **circle of fifths** (I IV
  vii iii vi ii V I; minor i iv VII III VI ii° V i) and its fragments (ii V I;
  vi ii V I, I vi ii V, ii V I vi; iii vi ii V; ii V iii vi); the **'50s**
  I vi IV V (and I vi ii6 V); the **"best-seller"** I V vi IV (vi IV I V,
  IV I V vi; minor i VI III VII); **i VII VI VII** (Stairway, Rolling in
  the Deep); the **Andalusian** i VII VI V.
- Harmonic rhythm: whole-note, half-note; it can change within a piece.
- Harmonic sequences explain progressions that break the flowchart.
- *Good Idea:* the T-S-D walk (`MOVES`) is this flowchart, by semitones
  from the tonic; bVII is in it. *Idea:* name the stock progressions as a
  choice ("Progression: Walk / '50s / Best-seller / Andalusian / Circle /
  ii-V-I"), fitted to the plan's lengths and cadences.

### Ch. 10: non-chord tones

- Nine kinds: passing (step in, step on), neighbour (step out and back),
  appoggiatura (leap in, step out - usually accented), escape tone (step
  in, leap out the other way), double neighbour, anticipation (often at
  cadences), pedal point, suspension (held over, accented, falls a step:
  4-3, 7-6, 9-8, 2-3 in the bass), retardation (held, rises a step).
- *Good Idea's* tune takes chord tones on the beat and leaves every other
  note by step: passing, neighbour and double-neighbour notes only. The
  most expressive kinds are accented (appoggiatura, suspension), or leave
  by leap (escape tone).
- *Idea:* now and then an accented non-chord tone - an appoggiatura or a
  4-3 suspension on a strong beat, resolving by step - and anticipations at
  cadences. Would need the sweep's "a note on the beat is on the chord" rule
  to allow them by name.

### Ch. 11: melodic analysis

- Motive: 2 to 7 notes; fragment: part of a compound motive; subphrase:
  usually 2 bars (a, a', a''; a sequence stays "a"); phrase: usually 4 bars,
  in classical music ending on a cadence (5, 6, 7 and 3 bars happen).
- Seven ways a motive comes back changed: **inversion** (tonal: mirrored in
  the key), **intervallic change**, **augmentation / diminution**,
  **rhythmic change**, **ornamentation** (non-chord tones added),
  **extension**, **retrograde**; plus sequence and fragmentation.
- *Good Idea* uses repeat, answer (a'), sequence (a~) and fragment (f)
  (0004). *Idea:* inversion, rhythmic change and ornamentation as ways a
  Motif's cell comes back.

### Ch. 12: form in popular music

- Verse-chorus (with pre-chorus, post-chorus, bridge; "simple" when verse
  and chorus share a progression, "contrasting" when not); 32-bar **AABA**
  (8-bar sections; the A sections harmonically **closed**, ending on I, the
  B section **open**, ending on V); 32-bar ABAC (or ABAB'); the **12-bar
  blues** (I I I I / IV IV I I / V IV I I).
- Sections leading into a chorus are usually open; a chorus may be either.
- *Good Idea:* the Song form is AABA, with its B open. *Idea:* a **Blues**
  form for the 12-bar Measure (dominant sevenths, the 12-bar pattern); a
  verse-into-chorus pairing for 16 bars.

### Ch. 13: phrases in combination

- **PAC**: V I, both root position, the tonic in the top voice. Anything
  less (an inversion, the third or fifth on top, vii° for V) is an **IAC**.
  *Agrees* (PAC ends the tune on the tonic, IAC on the third or fifth; the
  cadence chords are never inverted).
- **Sentence**: a melodic idea repeated or sequenced, then related or
  unrelated material driving to a cadence. *Agrees* (a a~ f c).
- **Period**: a less conclusive cadence then a more conclusive one - HC
  then PAC, or IAC then PAC; conclusive means ending on I (AC, PC);
  inconclusive, not (HC, DC). **Parallel** periods begin alike;
  **contrasting** ones do not. Also: repeated phrase, asymmetrical period
  (3 or 5 phrases), **double period** (a b a b', antecedent and consequent
  groups), repeated period, phrase group and phrase chain (ending on a HC),
  and **elision** (a phrase's last bar is the next one's first).
- *Good Idea's* Period is parallel, HC then PAC. *Ideas:* IAC-then-PAC
  periods; a contrasting period; a 16-bar double period; elision.

### Ch. 14: accompaniment textures

- **Chorale** (homorhythmic: a chord for nearly every melody note).
- **Arpeggios** with a bass line below (Moonlight Sonata; "If I Ain't Got
  You"): often a **tenth** between bass and top voice; up, down, up and
  down. **Alberti** (low-high-middle-high).
- Block chords in pop rhythms: the **"1 &"** rhythm (a chord on 1 and on
  the "and" of 2: "Let's Get It On", "Thinking Out Loud"), the **"Barbara
  Ann"** rhythm, **repeated eighths** (rock, "We Are Young"), **repeated
  quarters** ("Roxanne", "Cold As Ice").
- **Afterbeats** (chords after the downbeat, Schoenberg's term) and
  **offbeats**: polka (oom-pah) and the **reggae skank** (muted guitar on
  every "and").
- Cross-rhythms: the **son clave** (3-2), its first bar the **tresillo**
  (3+3+2); **3+3+3+3+2+2** in sixteenths ("Shape of You", "All of Me");
  the **habanera** and the **reggaeton** ("dembow") beat; combinations of
  threes and twos ("Party Rock Anthem").
- Distinctive bass and guitar **riffs** carry a song's identity.
- *Good Idea:* Block (held, struck at bar lines, stabs a dotted quarter in
  - which is the "1 &" rhythm), Pulse (on the beat, or a Euclidean
  syncopation), Broken (up, up and down, Alberti, rolling). *Ideas:* an
  **Offbeat** chord style (skank, afterbeats); named rhythm templates for
  Pulse and the Pulse bass (clave, tresillo, 3+3+3+3+2+2, habanera); a
  reggaeton beat for the Drums kind; a riff-style bass.

### Ch. 15: creating contrast between sections

- Sections contrast by changing some of the "elements of music": melody,
  harmony (key, mode), rhythm (the commonest note value), timbre, texture
  (number of parts; rhythmic activity), articulation, dynamics, register.
  "Rude" builds its form from texture alone (no bass and drums in verse 1,
  legato pre-chorus, the hook up high in the chorus).
- *Idea:* a Song's B section (or a second half) in a different chord style,
  pace or register - contrast inside one idea.

### Ch. 16: figured bass

- The six-four (second inversion) occurs in four situations only:
  **cadential** (I6/4 before V; it has dominant function), **passing** (the
  bass three steps one way), **pedal** (the bass held three times), and
  **melodic bass** (the bass carries a tune through the chord's fifth).
  *Agrees* with 1.6, checked now against the book itself.
- Raised 6 and 7 in minor count as diatonic.

### Ch. 17-18: secondary dominants and secondary diminished chords

- **Tonicization**: treating a chord other than I as a tonic by approaching
  it with its own dominant: V/ii, V/iii, V/IV (I7), V/V, V/vi - a major
  triad or dominant seventh whose root is a fifth above the chord it leads
  to; the raised note is that chord's leading tone. Diminished chords (vii°,
  ii° in minor) are not tonicized. **Secondary diminished** chords (vii°7/x,
  viiø7/x) do the same from a half step below; minor chords by fully
  diminished sevenths.
- In pop they often resolve **deceptively**: V/V to IV ("Yesterday",
  "Forget You"), V/V to bVII, V/vi to IV ("Imagine", "Dock of the Bay").
- *Good Idea:* nothing outside the key but the borrowed chord. *Idea:* a
  **Secondary** setting (Off / Rare / Common): now and then a chord is
  preceded by its own dominant (or that dominant replaces the chord before
  it), named V/x in the window like a borrowed chord, with the tune bending
  to its raised note. The biggest harmonic gap the book shows.

### Ch. 19: mode mixture

- Borrowing from the parallel minor into major; the **lowered 6** is the
  commonest borrowed note, then lowered 3 and 7: iv, bVI, bVII, ii°, iiø7,
  bIII, and the fully diminished vii°7. Bass lines 1-7-b7-6 / 6-b6 ("Joy to
  the World", "Beautiful"); I alternating with a borrowed chord.
- The **V bVI** deceptive cadence and the "epic" **bVI bVII I** ending.
- Borrowing from major into minor is rare - but for the **Picardy third**,
  a major tonic to end a piece in minor.
- *Good Idea's* borrowing (0011) matches (parallel minor first, the bVI, the
  iv), and borrows only major or minor triads. *Ideas:* a Picardy-third
  ending for minor; the bVI-bVII-I ending; the borrowed ii° and vii°7.

### Ch. 20: the Neapolitan

- bII, usually in first inversion (N6), a pre-dominant with a special
  colour; film music loves it (Raiders March, Star Trek). *Good Idea* has
  the Phrygian bII only where the scale has it. *Idea:* a Neapolitan before
  V in minor, as a flavour.

### Ch. 21: augmented sixth chords

- Pre-dominants whose notes close in on 5 from a half step either side
  (b6 and #4): Italian, French, German. In jazz and pop they are spelled as
  a dominant seventh on b6 going to V: Am F7 E ("Friend Like Me",
  "Criminal", the Pink Panther, Coltrane's "Mr. P.C.").
- **Descending chromatic bass lines** (1 7 b7 6 b6 5): Dido's Lament,
  "While My Guitar Gently Weeps", "Stairway to Heaven", "Dream On",
  "Jar of Hearts" - harmonized with inversions, secondary and borrowed
  chords.
- *Idea:* a "line" progression - a held or changing chord over a bass
  falling by step (the inversions code can already put the bass on a step).

### Ch. 22: modulation

- Tonicization (short) versus modulation (confirmed by a cadence, often the
  **full cadence**: pre-dominant, I6/4, V, I). Closely related keys (five,
  a key signature apart); a **pivot chord** usually tonic or tonic
  prolongation in the old key and pre-dominant in the new.
- **Direct modulation** - the pop "key change", usually up a step or half
  step for a last chorus ("Livin' on a Prayer", "My Heart Will Go On",
  "Love on Top"). **Common-tone** modulation through **chromatic
  mediants** (roots a third apart, same quality, one note shared: film
  music, Star Wars). **Sequential** modulation.
- *Ideas:* a last-section key change in a 16-bar Measure; chromatic-mediant
  moves as a "Film" colour.

### Ch. 23: enharmonic modulation

- The harmonic "pun": a V7 respelled as a German sixth (and back); a
  diminished seventh, which points to four keys. Of little use inside 1-16
  bars.

### Ch. 24-25: binary, ternary, sonata and rondo forms

- **Sectional** forms close their first section on the tonic, **continuous**
  ones do not; **rounded binary** brings the opening back (shortened) after
  the contrast; **balanced binary** ends both halves alike; the **binary
  principle**: I to V, then V to I. **Ternary**: statement, digression,
  restatement. Sonata form and rondo build on these.
- Four **structural functions**: expository (stable key, clear phrases),
  transitional (moves on, busier texture, ends on a half cadence and a
  rest), developmental (sequence, fragmentation, irregular phrases),
  terminative (an emphatic tonic-dominant alternation to close).
- *Good Idea's* forms are expository. *Idea:* a terminative tag (I V I V I)
  to close a Measure; a rounded-binary Measure (a b a' with the a shortened).

### Ch. 26: voice leading triads

- No parallel fifths or octaves between voices; parallel 3rds, 4ths, 6ths
  are fine.
- Melody: tendency tones resolve (7 to 1, 4 to 3, 6 and 2 down); no
  augmented intervals; change direction after a large leap; **two leaps in a
  row should outline a triad**.
- Spacing: adjacent upper voices within an octave; the bass may be further
  below (the overtone series puts the wide gaps low).
- Doubling: root position, double the root; **first inversion, do not
  double the bass** (except vii°6 and ii°6, which double it); never double
  the leading tone; second inversion, double the bass (the fifth).
- Bass by a 3rd or 6th: keep two common tones; by a 4th or 5th: keep one,
  or move all upper voices the same way; by a step: upper voices against
  the bass. The deceptive V vi doubles the third of vi.
- *Good Idea:* the tune keeps the melody rules but for "two leaps outline a
  triad". **Gap:** an inverted chord's own bass note is also voiced above
  it - G/B under a close G chord doubles B, the leading tone, which is the
  rule's first-named error. *Fix:* leave the bass note out of the upper
  voicing when a chord is inverted (at least when it is the leading tone).
- *Gap:* nothing checks the tune and the bass for parallel or direct
  octaves and fifths.

### Ch. 27: voice leading seventh chords

- The seventh resolves **down by step** (one licensed exception: I V4/3 I6).
  Successive root-position sevenths alternate complete and incomplete
  (no-fifth) voicings. Sevenths are added most often on dominants (V, vii)
  and pre-dominants (ii, IV); IM7, iii7, vi7 less often. *Agrees* with
  Mixed (0006, 0018). *Idea:* the voicer could prefer the voicing in which
  a seventh falls a step.

### Ch. 28: voice leading with non-chord tones

- A recipe for ornamenting a line, by its motion: a repeated note takes a
  neighbour; a step down takes a suspension, an escape tone, a double
  neighbour, a chromatic passing tone or an anticipation; a step up a
  chromatic passing tone, an anticipation, an appoggiatura, a double
  neighbour or a retardation; a third is filled with a passing tone or
  takes an appoggiatura; **leaps of a fourth or more are not embellished**.
  Two voices ornamented at once move in 3rds or 6ths.
- *Idea:* exactly the rules for an "Ornament" choice (ch. 10, 11).

### Ch. 29: voice leading chromatic harmony

- A secondary dominant's raised note rises; a borrowed b6 falls; the
  Neapolitan doubles its bass and its b2 falls; an augmented sixth's #4
  rises to 5 (b6 falls to 5).

### Ch. 30: counterpoint

- Species rules for two lines: begin and end on an octave or unison, the
  last reached by contrary motion (2-1 against 7-1); perfect intervals only
  by contrary motion (no **direct** fifths or octaves); no more than three
  parallel 3rds or 6ths in a row; dissonance only as passing tones (second
  species), cambiata (third), suspensions 7-6 and 4-3 (fourth); leaps
  limited and recovered; no outlined tritone; no repeated notes.
- Bach's invention exposition: the theme, then the theme an octave lower in
  the other hand, then a fifth higher; fugue: subject, (tonal) answer,
  countersubject, episodes made by fragmenting and sequencing.
- *Ideas:* apply the first-species rules to the **tune against the bass**
  on strong beats (no parallel or direct octaves and fifths, a contrary
  close); an "imitation" texture (a second voice answering the tune).

### Ch. 31: jazz theory

- Labels: "9" includes the seventh; no seventh is "add9" or "add2"; "6"
  only without a seventh (with one it is "13"); "sus" only without a third
  (with one it is "11"); 6/9 chords; minor-major sevenths.
- **Altered dominants** (b9, #9, b5, #5) on a dominant that resolves down a
  fifth.
- **Guide tones** (3rd and 7th) move by step through circle-of-fifths
  progressions.
- Voicings: "spread" - the root, 3rd and 7th lowest (3rd above or below the
  7th), colour tones above in 4ths and 5ths; "close" - the bass in the left
  hand, four notes in close position in the right, the 3rd or 7th lowest.
  Voice a sus4 as a 3rd and a 6th as a 7th.
- Progressions: ii V I (Dm9 G13 Cmaj9; minor Dm7b5 G7alt Cm6/9), the
  **turnaround** iii VI7 ii V (all dominants: E7 A7 D7 G7), the **tritone
  substitution** (Db7 for G7), the jazz blues.
- Scales: the blues scale (minor pentatonic with b5), the bebop dominant;
  chord-scale relationships by filling a chord's gaps without augmented
  seconds or two half steps running.
- *Agrees* with 0018: Shell is the spread voicing's root-3-7, Rootless the
  close voicing over a separate bass, sus and 6 voiced as the book says.
  *Ideas:* guide-tone voice leading in the voicer; altered dominants and
  tritone substitutions as a jazz colour; the turnaround as a Loop ending.

### Ch. 32: impressionism and extended tonality

- **Modes** as alternatives to major and minor (Dorian, Phrygian, Lydian -
  *Good Idea* has all of them); **upper extensions** (9, 11, 13);
  **planing** (a voicing moved in parallel - all voices at once, against
  every classical rule); **pandiatonicism** (a wash of scale notes, no
  functional pull); **quartal, quintal and secundal** chords (Jeopardy,
  CHiPs; the chord table's Q4/3 and So What); **polychords** (the Rite of
  Spring chord).
- *Ideas:* a "Planing" chord style or voicing; a Quartal colour.

### Ch. 33-34: set theory and serialism

- Pitch classes as integers mod 12, normal and prime form; twelve-tone rows
  (P, R, I, RI). This is how Good Idea's arithmetic already works; nothing
  further for tonal ideas.

### Ch. 35: minimalism

- **Additive process** (Glass, *Two Pages*): a pattern repeated, each time
  one note shorter (or longer); chords lengthened by added subdivisions
  (*Einstein on the Beach*).
- **Phase shifting** (Reich, *Piano Phase*, *Clapping Music*): a pattern
  against itself rotated one note at a time.
- *Ideas:* additive and rotating arpeggio patterns for Loops and Broken
  chords; a "phase" variation for Motifs.

(The rest of the PDF is the answer key and the GFDL licence.)

---

## Open Music Theory (100 pages)

*Open Music Theory* (Gotham, Gullings, Hamm, Hughes, Jarvis, Lavengood,
Peterson; open textbook). The pages saved in the zip cover fundamentals,
harmony, counterpoint, galant schemata, classical and pop form, and
post-tonal theory. Notes by topic.

### Pop/rock harmony and schemata

- Pop chords are "almost always **root-position** triads or seventh
  chords"; the bass scale degree nearly always gives the chord (do I, re II,
  mi III or I6, fa IV, sol V, la VI, te bVII, ti V6). So **Inversions on Rare
  is right for pop**; Common suits classical and singer-songwriter styles.
- Stock **schemata**, usually cyclic (and rotated to start anywhere):
  - **'50s doo-wop**: I vi IV V, or I vi ii V ("Duke of Earl", "Total
    Eclipse of the Heart"; "Viva la Vida" starts it on IV).
  - **Singer/songwriter**: vi IV I V in major = i VI III VII in minor (mode
    ambiguous between relative keys); the "With or Without You" rotation
    I V vi IV; a **deceptive** rotation IV I V vi that ends phrases on a
    deceptive cadence.
  - **"Puff"**: I iii IV to open a phrase (the bass mi as III, not I6).
  - **Blues**: 12-bar (I / / / IV / I / V IV I /) and 16-bar (I twice, then
    IV and V phrases), often with a turnaround; alterations common
    ("Don't Be Cruel" ends ii V I).
  - **Pachelbel**: I V vi iii IV I IV V (or with a stepwise bass, I V6 vi
    iii6 IV I6 IV V).
  - **Lament**: i VII VI V.
  - **Circle of fifths in minor**: i iv VII III (leading to the relative
    major); "I Will Survive" all the way round.
  - **Plagal**: I IV oscillation (soul, R&B); the **double plagal** bVII IV
    I ("Hey Jude"); the extended plagal bVI bIII bVII IV I ("Hey Joe").
- Everett's six pop "tonal systems": 1 classical-like; 2 modal (Dorian,
  Mixolydian, Aeolian); 3 classical with modal borrowing; 4 blues-based; 5
  minor-pentatonic; 6 chromatic minor-pentatonic.
- *Good Idea:* the T-S-D walk covers systems 1-3 (and the pentatonic and
  blues scales are there by ear). *Idea:* the named schemata as a
  Progression choice for Loops and Phrases (an idea is still a number: the
  schema, its rotation and its pace are drawn from the dice).

### Pop/rock rhythm

- **Straight syncopation**: take a run of equal notes, halve the first, and
  move the rest early by that half - at the beat level (quarters shifted an
  eighth) or the division level (eighths shifted a sixteenth). The commonest
  pop syncopation; easy to sing because it follows speech.
- **Fake triplets**: 3+3+2 sixteenths (or 3+2+3, 2+3+3) for two beats -
  "more common than real triplets in most pop/rock"; **fake sextuplets**
  3+3+3+3+2+2.
- *Good Idea:* Syncopated takes Euclidean spreads turned off the beat
  (which include 3+3+2); Triplets are real triplets. *Ideas:* a "pushed"
  syncopation by the straight-syncopation recipe (a run of notes anticipated
  by an eighth), and 3+3+2 / 3+3+3+3+2+2 as figures named for what pop calls
  them.

### Pop/rock form

- **Phrase** about 4 bars (a line of lyric); **module** 8-24 bars, 2-4
  phrases (a stanza); **cycle** - the succession of modules ending on the
  primary one: strophic {A}, AABA {AABA}{BA}, verse-chorus {VC}, {VPC},
  {VPCZ}, with a bridge replacing V or VP late on.
- Module shapes: **aa'** (antecedent, consequent), ab, **aa'b** (the
  blues), abb', and **srdc** (statement, restatement, departure,
  conclusion - the pop sentence; aaba or aabc).
- Functions: **strophe** (primary, closed, tonic prolongation; srdc
  inside); **chorus** (primary, lyric-invariant, on-tonic, more intense -
  denser texture, backing vocals, **higher register**); **verse**
  (narrative, on-tonic, open since the 1960s); **prechorus** (energy gain:
  fragmentation, faster harmonic rhythm, away from tonic, open - the old d
  of srdc); **bridge** (contrast, non-tonic, often ending on V, demands the
  primary module after it); **postchorus**; intro, outro, coda; refrain,
  climb. "On-tonic", "off-tonic", "harmonically closed / open",
  "turnaround" (a V at the end of a closed unit leading back to I).
  "Chorusification": later cycles drop the verse and prechorus.
- *Good Idea:* the Sentence is srdc; the Song is AABA (A closed, B open);
  the Loop is a cyclic module. *Ideas:* a 16-bar **Verse-Chorus** form (8
  bars of open verse, 8 of on-tonic chorus with the tune higher and the
  chords busier); a turnaround to end Loops.

### Classical cadences, syntax and functions

- **Cadence types**: PAC (V I, the tune on do), IAC (the tune on mi or
  sol), HC (ends on V; the tune on re, ti or sol). **At a half cadence the
  V is "almost invariably a triad, rather than a seventh chord", and in root
  position.** The tune's final do is approached by step, preferably from
  re. Compound cadences: a 4-3 suspension over the V, the cadential 6/4
  (6-5 with 4-3 over a repeated sol in the bass); the double cadence.
- **The idealized phrase**: T -> (S) -> D -> T, beginning on I and ending
  with an authentic cadence; functions are *zones*, triggered by a fixed bass
  degree (T1, S2, S4, D5 - the "functional" or "cadential" chords) and
  prolonged by "contrapuntal" chords (any bass).
- **Functions by scale degree** (Quinn): T is triggered by 1 and 3 (5 and 6
  associates), S by 4 and 6 (1 and 2), D by 5 and 7 (2); vi (6 1 3) is a
  "destabilized tonic". In classical music a chord's notes decide its
  function; in pop, context does (IV can be many things).
- *Good Idea:* `T.functionOf` reads function off the root's distance from
  the tonic - the same grouping. **Gap:** with Mixed (0006) the V of a half
  close takes its seventh; the book says a half cadence's V is a plain
  triad. *Fix:* keep the HC's dominant a triad. (Its tune already lands on
  the V's notes.)

### Galant schemata

Gjerdingen's "stock musical phrases" - melody and bass skeletons, one stage
per bar (or two per bar), with fixed harmonies:

- **Openings** (presentation phrases, prolonging I): **Meyer** (melody do ti
  fa mi over do re ti do: I V V I); **Jupiter** (do re fa mi over do ti ti
  do); **Aprile** (do ti re do); **Pastorella** (mi re fa mi over do sol sol
  do); **Do-Re-Mi**; **Sol-Fa-Mi** (over do re ti do, I ii V I or I vii V I);
  **Romanesca** (bass do ti la mi: I V6 vi I6, slower movements).
- **Continuations**: **Prinner** (melody la sol fa mi over fa mi re do in
  parallel tenths: IV I6 vii6 I, or with a sol inserted, IV I6 vii6 V I) -
  "the typical response to an opening schema"; the **modulating Prinner**
  (to V); **Passo Indietro** (half a Prinner); **Fonte** (a two-bar model,
  then the same a step lower - V/ii ii V I); **Monte** (the same a step
  higher - V/IV IV V/V V); **Ponte** (holding V, delay not motion).
- **Cadences**: simple PAC (re do over sol do), simple IAC (fa mi), the
  **fa-fi-sol HC** (ii6 V6/5/V V), compound PAC, IAC and HC (with the
  cadential 6/4).
- **A sentence from schemata**: a four-stage opening schema (two bars per
  stage pair, the idea and its varied repeat), then a 5-stage Prinner (or a
  Passo Indietro, or a Prinner twice as fast - fragmentation) and a cadence;
  the schema's melody notes on the downbeats; the tune more original at the
  start and more formulaic towards the cadence.
- *Ideas:* a **Galant** style for Phrases and Measures in major: an idea's
  number picks an opening schema, a continuation and a cadence; the tune's
  downbeats follow the schema's melody, the bass its bass, and the walk
  fills between. Calculated, named, and the window could say "Meyer -
  Prinner - PAC". The Fonte and Monte as sequences for the B of a Song.

### Theme types (Caplin)

- **Functions**: *initiating* (presentation: a basic idea twice over a tonic
  prolongation; antecedent: basic idea + contrasting idea, ending weakly -
  HC or IAC), *medial* (continuation: fragmentation, liquidation, sequence,
  faster notes, **faster chords**), *closing* (cadential: T (S) D5 (T1), a
  conventional falling tune; consequent: the antecedent's basic idea again,
  ending with a PAC).
- **Sentence** (8 bars): presentation (bi bi, tonic prolonged) +
  continuation (fragments, sequence, acceleration) ending PAC, IAC or HC.
  The continuation is the part most often stretched (4 + 6 bars).
- **Period** (8 bars): antecedent (bi ci -> HC/IAC) + consequent (bi ci' ->
  PAC). The consequent's ci is often the antecedent's, altered for the
  stronger close - or entirely new.
- **Hybrids**: antecedent + continuation; antecedent + cadential;
  compound basic idea (bi ci over a tonic prolongation, no cadence) +
  continuation; CBI + consequent.
- **Compound** (16-bar) period and sentence: the same at double size.
- *Good Idea:* `I.FORMS` has Sentence and Period (0004) and the units speed
  the harmony up in a fragment (`countFor`), as "continuation" says. The
  hybrids are four more forms in the same `letter:bars:cadence` notation -
  `a:2 b:2:H f:1 f:1 c:2:X` (antecedent + continuation), `a:2 b:2 c:4:X`
  (CBI + cadential). *Idea:* add them as Measure forms (new values outside
  Any). **Liquidation** (the tune gets plainer and falls towards the
  cadence) is not modelled: the cadential unit could bias the contour down
  and the walk to steps.

### Embellishing tones and tendency tones

- **The non-chord tones**: passing (chord-step-chord, filling a third, two
  filling a fourth; accented or not), complete neighbour (mostly unaccented),
  double neighbour (above then below, unaccented), incomplete neighbour (leap
  in, step out to an accented chord tone), **appoggiatura** (accented, leap in
  - usually up - then step the other way), **escape tone** (unaccented, step
  in - usually up - then leap the other way), **anticipation** (the next
  chord's note early, struck again on the change; at phrase ends),
  **syncopation** (the same, tied over), **suspension** (prepared, held over
  the change, resolved down by step).
- **Tendency tones**: ti goes to do (strongest in a dominant chord, resolving
  when the function changes) - except inside a falling scale (re do ti la
  sol), or in an inner voice (the "frustrated leading tone" may drop to sol).
  le goes to sol, whatever the function.
- **Functional dissonances**: in T, 7 (and 5 when 6 is there); in S, 3 (and
  1 when 2 is there); in D, 4 and 6. These are every chord's seventh, fa in
  vii, ti/te in iii. They want to be approached by common tone or step, and
  to fall by step when the function changes.
- *Good Idea:* the walk allows passing and neighbour tones only off the beat
  and leaves a non-chord tone by step (that covers the passing tone, both
  neighbours, the escape tone's step in). It has no accented non-chord tones
  (appoggiatura, suspension, accented passing tone), and no anticipation.
  The tune's leading tone already leans to do through the cadence goals, not
  everywhere. **Gap:** the chords part does not make a chord's seventh fall
  by step (0006 voices nearest, which often does, but not always). *Ideas:* a
  "Tension" setting (Off / Rare / Common) that lets the tune lean on the
  beat - an appoggiatura or a suspension, resolving down a step; an
  anticipation of the last chord's note, a sixteenth or eighth early, at a
  closing unit; in the voicer, a seventh's next note a step below when one
  is near.

### Expansions

- Classical phrases stretch the four-bar norm by **repeating a motive inside
  an idea**, and by **delaying the cadence**: an IAC or a deceptive cadence
  where a PAC was due, then the continuation again ("one more time"), or an
  *evaded* cadence (the leading tone left unresolved).
- **Prefix** (an accompaniment bar before the tune), **suffix**: a closing
  section after a PAC (the tune round do, ii V I repeated), **standing on the
  dominant** after an HC.
- *Good Idea:* every unit is a whole number of bars and every form an even
  length. *Ideas:* an "Ending" value that cadences weakly (IAC or deceptive)
  and repeats the continuation to a PAC - a 10- or 12-bar Measure that earns
  its length; a one-bar accompaniment lead-in before the tune.

### Chromatic harmony

- **Modal mixture**: chords from the parallel key - iv, bVI, bVII, bIII, ii
  half-diminished in major; the Picardy third (a major I at the end in
  minor). Only a cadence confirms a new key; otherwise it is borrowed.
- **Applied (secondary) chords**: V or vii of any major or minor chord of
  the key, just before it - an altered T before S, an altered S before D, an
  altered D before T. viio/V V I is still S D T: fa raised to fi.
- **Chromatic subdominants**: the **Neapolitan** (ra fa le, usually in first
  inversion, fa doubled, before V or the cadential 6/4), and the **augmented
  sixths** (le in the bass, fi above: Italian le do fi; French le do re fi;
  German le do me fi, mostly in minor and before a cadential 6/4).
- **Modulation**: tonicization has no cadence in the new key, modulation
  has. Direct (phrase) modulation; the pop **step-up** (whole or half step,
  near the end); the **truck-driver** (old I, then the new key's V, then the
  new I a step up); the **pivot chord** (a chord in both keys, best with the
  same function in both - commonly S).
- **Plagal pop**: I-IV vamps (Soul Man, In the Midnight Hour); the
  **double plagal** bVII IV I (Hey Jude's coda); the extended plagal
  bVI bIII bVII IV I (Hey Joe).
- **Circle of fifths in minor**: i iv VII III (the turn from VII to III
  sounds like V I in the relative major); the whole circle, i iv VII III VI
  ii V (I Will Survive).
- *Good Idea:* 0011's borrowing is modal mixture, and its source scales
  include the parallel minor, so bVI, bVII, iv and bIII already happen. **The
  biggest harmonic gap is applied dominants** (V/V, V/vi, viio/V) - the most
  common chromatic chord in both classical and pop. *Idea:* an "Applied
  chords" setting (Off / Rare / Common) that turns a chord before a major or
  minor chord into that chord's V (or V7, or viio) where the bass then moves
  down a fifth - its own dice, labelled V/V, and the tune fitted to it as
  for a borrowed chord. Then the Neapolitan and the augmented sixths before
  a cadence's V (rarer, and only before a dominant). A "Key change" for a
  Song's last section: step-up or truck-driver.

### Style and tendency

Meyer: *laws* (from how we hear, near universal), *rules* (a style's, e.g.
no parallel fifths - descriptive: it happens rarely, in particular places),
*strategies* (a composer's). Most voice-leading "rules" are style rules,
better thought of as tendencies. *Good Idea's* rules are this kind:
probabilities that make the usual likely and the unusual rare, with a few
held as guarantees (`I.untangle`) where breaking them sounds like a mistake.

### Counterpoint and thoroughbass

- **A good line** (the cantus firmus): begins and ends on do, approached by
  step (re-do, or ti-do); a range of a tenth at most, usually under an
  octave; **one climax, heard once**; mostly steps, some small leaps; a leap
  of a fourth or more followed by a step the other way; no more than two
  leaps running, and never two the same way **unless they outline a triad**;
  the leading tone goes to do.
- **Huron's five tendencies** of melody: pitch proximity (steps over leaps),
  **step declination** (falling steps more often than rising), **step
  inertia** (a line keeps its direction more often than it turns), melodic
  regression (extremes come back towards the middle), and arch contours.
- **Two lines**: begin and end on perfect consonances; approach the last
  interval in contrary motion by step; the two climaxes not together; no
  crossing or overlap; no parallel fifths or octaves; prefer thirds and
  sixths, but not more than three running; leap within the bar rather than
  over the barline; a long line has one or two lower secondary climaxes.
  Second species brings the passing tone, third the neighbour, fourth the
  **suspension** (7-6, 4-3, 9-8 above; 2-3 below).
- **Thoroughbass / keyboard style**: three upper voices within an octave
  over the bass. In a triad double the bass for 5/3 and 6/4, and for 6/3
  when the bass is do, re, fa or sol; **for a 6/3 over mi, la or ti (a
  variable degree) double an upper note instead**; never double a chromatic
  note. Schoenberg's **law of the shortest way** (move each voice as little
  as possible), and the right hand against the bass in contrary or oblique
  motion. No parallel fifths or octaves; no contrary ones between the outer
  voices; no hidden octave between the outer voices unless the top steps.
- *Good Idea:* the walk already has steps likeliest, a step back after a
  leap, a single climax for the Arch (at the golden section), leap limits,
  and the PAC goal approached by step. `T.voice` is the law of the shortest
  way. **Gaps:** (1) **doubling in first inversion** - G/B in Close doubles
  B, the leading tone, which this rule forbids (fixed by voicing a first
  inversion's upper notes from the root and fifth when its bass is mi, la or
  ti); (2) the two-leaps-only-as-a-triad rule is not in the walk; (3) step
  declination and step inertia could be stated in `MOVES` - the demo would
  say whether the tunes need it; (4) tune against bass: no check for
  parallel octaves and fifths between the tune and the bass.

### Metre, scales, the larger forms, and the rest

- **Metre**: simple / compound by the beat's division, duple / triple /
  quadruple by grouping; the top number of 6, 9, 12 means compound. Triplets
  are a compound division *borrowed* into simple metre, duplets the
  reverse. *Good Idea:* `I.meter` does the same (6/8, 9/8, 12/8 have a
  dotted-quarter beat), and the figures' triplets are borrowed divisions.
  *Idea:* duplets (two dotted eighths) over a 6/8 beat as a figure.
- **Collections**: the seven modes; the pentatonic (no 4 and 7, no half
  steps, any note can be the centre); whole-tone (two of them); octatonic
  (three; Messiaen's modes of limited transposition); acoustic (the
  overtone series: Lydian with a flat seventh). *Good Idea* has ScaleView's
  scales, among them the pentatonics, whole-tone and octatonic, and builds
  their chords by ear (0006).
- **Small ternary** (A B A'; A ends PAC, may modulate to V or III; A'
  always ends I:PAC; B is loose, often standing on the dominant before A'
  returns); **minuet and trio** (rounded binary: ||: A :||: B A' :||);
  **rondo** (ABACA, the refrain always in the tonic); **sonata** (P TR ' S /
  C: the medial caesura, a pause after an HC, before the second theme; the
  development touches minor keys and ends on the home V; the recapitulation
  ends with the I:PAC).
- *Good Idea:* a Measure's longest form is 16 bars, so these are bigger
  than one idea - but the **small ternary at 12 or 16 bars** (a:4:P b:4:H
  a:4:X, B standing on the dominant) is the Song form with an ending for
  B. The **medial caesura** - a beat or two of silence after a half
  cadence - is a cheap, idiomatic touch for a Period's answer.
- **Harmonies by bass degree** (Shaffer's chart): over do, I or II4/2; over
  re, II, V6/4 (passing) or VII6; over mi, I6 or III; over fa, IV or II6,
  V4/2; over sol, V, the cadential 6/4, or a passing I6/4; over la, IV6 or
  VI; over ti, V6 or VII. The chromatic chart adds the applied chords by
  their bass (fi = viio/V or V6/5/V, di = V6/5/ii, si = V6/5/vi, ...).
  *Good Idea:* `I.invert` chooses inside this table already (first
  inversions by bass step, six-fours only as passing, pedal, cadential).
- **Lead-sheet symbols** (Shaffer): C, C/E, C/G; Csus(4), Csus2; C2 =
  Cadd2 = Cadd9; CM7, C7, Cm7, Cø7 (half-diminished), Cdim7; C7/E, C7/G,
  C7/B; C7sus4. *Good Idea's* chord line writes these, `m7b5` for ø7.
- **Post-tonal** (atonal analysis, sets, twelve-tone rows, symmetry,
  centricity "by emphasis: the lowest, highest, loudest or longest note"):
  outside what Good Idea calculates; noted for completeness. Centricity by
  emphasis is how the by-ear scales (0006) hold together.
- **Analysing poetry**: for song lyrics; nothing for Good Idea.

## Orchestration

Good Idea writes three parts (tune, chords, bass) or a drum part, not an
orchestra - but these books are about **what each part should do so the
whole is clear**, which is exactly the arrangement question.

### Alan Belkin, *Orchestration* (web pages and the PDF)

- **Planes of tone** (Tovey): a plane is one instrument or a blended group
  sharing one rhythmic outline. The ear can follow **one foreground**; any
  number of background planes may coexist. Within a plane blend comes from
  like timbre and rhythm, **close spacing with no large gaps**, and
  balance; between planes, difference of **register, timbre or rhythm**.
- **The foreground** stands out by being louder, more characterful, and
  usually **on top**. "The top line normally attracts the most attention",
  and "the ear follows **activity**": strings playing busy counterpoint
  cover a voice that held notes would not.
- **Background** is *movement* (trills or tremolos, repeated notes, scales,
  **arpeggiation** - "limited to one or two mildly varied motives, with a
  high degree of consistency", lightened with rests) or *resonance* (held
  notes, the softest sounds, **in the same register as the foreground**).
- **Accompanying a soloist**: bring the solo out by **contrast** - of
  timbre, **of register** (a cello solo with only upper strings), or **of
  rhythm (the solo busier than the accompaniment)**; aerate the
  accompaniment with rests and plucked or staccato basses; keep held notes
  in dull registers; vary the relationship (dialogue, then accompaniment);
  for force, alternate soloist and band.
- **Register**: most music sits in the middle; a blended chord follows the
  **overtone series - wide at the bottom, close at the top, no large gaps
  in the middle** (a gap splits the sound into separate planes); loud
  textures with a hole in the middle sound feeble; don't fill the whole
  range all the time; extremes tire the ear.
- **Form**: a change of sound is a formal articulation; it belongs between
  phrases or at a motive change, a climax or a cadence, and its size should
  match the size of the formal break. Crescendo = add instruments in order,
  diminuendo = take them away. **One climax, near the end, with something
  kept back for it.**
- **Doubling**: unison doubling thickens (adds "volume", not loudness) and
  greys; the octave is more transparent; better still: heterophony (an
  ornamented version), partial doubling (only the highlights), doubling that
  turns into counterpoint. "Do not double at the unison unless there is a
  definite need." Poor orchestration: feeble, tiring (extremes, too much
  colour), **grey (too much unison), heavy (too much doubling, an
  overloaded low register)**, confused planes, arbitrary changes.
- **Character glossary**: luminous (soft sustained background + soft high
  brass, flutes, high metal percussion), mysterious (delicate resonance,
  quiet movement), menacing (low drum rolls, low close strings), brilliant
  (high brass, fast rising lines), playful (rests, high staccato,
  pizzicato), sad (slow low sustained strings, a solo wind over them).
- *Good Idea:* this confirms 0009 (only the tune takes the accent) and the
  0018 rule that a spread voicing goes **over the tune or under it, never
  through it** - Belkin's "planes" in other words. **Gaps:** (1) the chords
  part can sit in the **same register as the tune**, moving in the same
  rhythm (Block on every note) - two planes merging; a test could measure
  how often the top of a chord is within a tone of the tune note sounding,
  and a voicing could stay a step below the tune's lowest note in that
  chord; (2) the low-interval limit (0018) is half of "wide at the bottom";
  Close voicings low down can still leave a gap of more than an octave
  between bass and chord - the other half (no hole in the middle) is not
  checked. *Ideas:* an "Accompaniment" setting that makes the chords
  **busier where the tune holds and quieter where it moves** (the tune's
  rhythm read first, the chords' strokes placed in its gaps - call and
  response at the beat level); chord velocities a little under the tune's
  (they are now the same Velocity), and a crescendo by adding parts for a
  Measure's last unit.
- The PDF (*Artistic Orchestration*, 2001/2008) is the same book with its
  introduction and conclusion; its two principles behind every rule about
  gaps: "musical elements in separate registers are not perceived as being
  on the same plane of tone", and "for fullness of sound, the ear requires
  fairly complete registral saturation, especially in the middle range".
  Orchestration is "composing with timbres", and these principles hold for
  electronic music too.

### *Orchestration Analysis* (texture, layout, doublings, perception)

- **Orchestration of something**: take away instruments and doublings and
  a texture is left - elements that are *singular* (one note at a time) or
  *compound* (several at once), each *coordinate* or *subordinate* by its
  dynamics, character and **activity**. Good Idea's block is this
  reduced texture: tune (singular), chords (compound), bass (singular).
- **Layout**: *linear* orchestration (one instrument has the whole line)
  keeps an element's identity; *split* (passed between instruments) colours
  it but makes it harder to follow. **Octave position**: low notes' clashing
  overtones are louder, so "composers typically keep a larger interval (an
  octave or more) between co-occurring notes in the bass register"; **close
  registers mask each other, more than two octaves apart sounds unrelated;
  "subtly overlapping registers are often preferred - the melody just
  touches the top of the accompaniment"**, with the bass further away.
  **Depth** (front and back) comes from dynamics, but as much from
  register, activity and articulation: "the more penetrating, lively and
  irregular an element, the more it grabs attention; repeating patterns,
  long notes in an inconspicuous register, static articulation are easy to
  overlook".
- **Doublings** don't add elements: unison (fuses, "wet"), octave (enlarges;
  two octaves apart no longer fuses), parallel at an interval (thirds in
  the scale - a colour "like an organ mixture"), similar motion, temporal
  displacement (echo; further, canon), by contour, partial (accents).
  **Chord spacing follows the harmonic series**: wider intervals low down,
  **the root doubled most**; a dissonance is harsher low, doubled, or in
  like timbres, and softens as its notes are spread apart.
- **Perception** (Gestalt; Bregman, Huron): notes near in pitch and time
  and alike in sound make one stream; to keep parts apart give each small
  intervals, **its own register**, and its own articulation; parts collapse
  into one stream with big leaps, **crossings**, split colours and one
  articulation. *Common fate*: notes that start together and move together
  group together. *Figure and ground*: a clear, information-rich,
  non-repeating line comes forward; a static, repetitive one goes back.
  *Prägnanz*: we hear few, stable streams.
- **Strategies**: Ravel (rapid changes, complex blends, a static ostinato
  against them), Lutoslawski (orchestration as composition; every
  instrument paired with a similar one), Sciarrino (instruments as material;
  foreground soloists, anonymous background).
- *Good Idea:* the measure to add is the one in the Belkin notes above -
  **does the tune ever sound inside the chords?** The book's answer is that
  "just touching" the top of the accompaniment is best, so the rule would be
  a chord's top note at or under the tune, not a gap. And the bass: an
  octave or more under the chords' lowest note (Close voicings near C3 can
  come within a third of the bass). *Ideas:* "Thirds" - the tune doubled in
  thirds or sixths in the scale (a parallel doubling) as a tune style; the
  chords' first stroke after a tune note held (common fate keeps them
  apart if they don't start together).

### *The Idiomatic Orchestra*

- **Orchestration as translation**: the content stays, the way it is said
  changes. "An orchestrated crescendo cannot be overlooked": build
  dynamics, accents and articulation into **which parts play**, not only
  into the markings (Beethoven 9, Berlioz adding instruments beat by beat).
- **Segments**: group what a score holds by similarity, function and
  character - melody in octaves is one segment; viola chords and the bass
  another (Mozart 40). **Unisono** in the wide sense: anything that behaves
  as one line - *linear* (one instrument), *split* (phrases passed between
  instruments - question and answer).
- **Doublings**: perfect unison (fusion, density); octaves ("by far the
  most common"); **parallel doubling in thirds, fifths or sixths adjusted to
  the scale** (more volume and density than octaves; Ravel's *Bolero* builds
  its crescendo out of them, ending in parallel triads); mixtures (the
  overtones added softly - horn plus celesta an octave up, piccolos a
  twelfth and two octaves and a third up, each in its own key); partial
  doubling and heterophony (the basses play a simpler version of the
  cellos; the woodwinds double only the main notes).
- **Foreground and background**: the accompaniment is "harmony set in
  motion" - the **Alberti bass** (broken chords in a fixed pattern) is the
  model, but idiomatic only on keyboards; a background uses **discreet
  sounds, low activity, figures that don't invite renewed attention
  (repetitions, trills, scales)**, and usually sits **in the same register
  as the foreground** so as not to draw the ear.
- **Active harmony**: accompaniment that becomes a field of sound (the
  *Rheingold* prelude, Debussy, Ligeti's clusters).
- **Chords and balance**: Rimsky-Korsakov's balance ratios (in forte: one
  trumpet or trombone = two horns = two woodwinds, roughly) let one count
  how much of a chord's weight is on each note. Final chords of the
  classical and romantic repertoire put **57-70% of the weight on the
  root**; the low register holds **octaves, then fifths, the third only
  higher up**, because a low third's overtones clash in the middle of the
  hearing range; "all chords tend to put the largest intervals in the
  bass". The weight of a balanced chord sits in the middle register.
- **Reverberation**: temporal doubling (an echo a beat or an eighth late);
  the **orchestrated sustain pedal** - held notes in the horns' middle
  register (an octave either side of middle C) binding a texture together.
- **Polyphony**: orchestral "voices" are rarely one instrument each;
  composers ignore chorale voice-leading in inner parts for colour's sake.
- **Form**: "tone-colour tempo" - how often the sound changes (Mozart 40:
  18 changes in 100 bars, one every six); a colour held back is fresh when
  it returns; dualism of first and second themes in the scoring.
- **Dynamics and articulation** notation is ambiguous; orchestrate them.
- *Good Idea:* (1) the balance chapter is the strongest support yet for
  the doubling gap: **double the root, keep thirds out of the low
  register** - `T.voice` builds close triads near C3-C4 (a third at E3
  is fine), but Shell and Rootless voicings put a third or seventh at the
  bottom, which the 0018 low-interval limit already keeps above C3; the
  Phrase's own bass under a Close chord can be a third below its lowest
  note. (2) A **Pedal** chord style - one held chord (or the chord's root
  and fifth) under the tune for each chord, an "orchestrated sustain
  pedal" - is a plain, idiomatic fourth option beside Block, Pulse, Broken.
  (3) Broken already plays the **Alberti** pattern (1 3 2 3) among its
  four - the book's model accompaniment. (4) A
  **Thirds** tune style: the tune doubled a third (or sixth) below in the
  scale, as one more part or in the tune's own track.

### ACTOR *Timbre and Orchestration Resource* (Freund and Cutler, *Extreme Orchestration*; the Chinese orchestra pages; two articles)

Read in full: effective instrumental writing, piano essentials and the
piano in the orchestra, percussion introduction, drums and scoring.
Skimmed for register, blend and accompaniment: the string, brass,
woodwind, harp, mallet and Chinese-orchestra pages, the tuba history
article and the bass drum page.

- **Register is colour**: every instrument is several instruments (low,
  middle, high); dark low, bright high. An orchestrator may move a passage
  up or down an octave, or one note of it.
- **Context makes colour**: many instruments in unison grey each other out;
  a solo projects more colour; a sound is striking after a long absence.
- **Dynamics**: players respond to wide contrasts; "for noticeable
  contrast skip at least one gradation"; beware of beginning on mf or mp;
  shape held notes (a crescendo or diminuendo rather than flat).
- **Voicing**: "chord voicings sound natural and balanced when they follow
  the harmonic series - larger intervals on the bottom, smaller ones
  higher up" (said in nearly every book in the zip).
- **MIDI**: "fast MIDI music can be somewhat convincing, slow passages are
  often unbearable"; "everything may be in tune and in time, but it loses
  its humanity"; MIDI players never breathe.
- **Piano**: a percussion instrument "masquerading as a sustaining, lyric
  instrument"; louder notes decay faster, so **velocity is accent**; a
  singing tone up to C6, the bottom fifth growly; **four-note arpeggios are
  easier than triads** (smaller skips); the three-layer keyboard texture is
  melody, bass and a flowing inner voice, the inner voice played softest.
  In an orchestra the piano works best as a distinct colour, in clear,
  unified gestures, often at the extremes, not filling in.
- **Drums** (orchestral): snare, bass drum (single hits under a busier
  snare; "be specific about durations"), toms (high to low; often paired
  with the bass drum as its lowest), timbales, bongos and congas, the
  tambourine; rolls, flams, drags, ruffs, rim shots and rim clicks. The pages
  link to drum-kit videos (swing and rock sets) but have no text on grooves.
- **Ensemble notes**: horns blend with everything ("dual citizenship" with
  the woodwinds); a single trumpet in its middle-high register is heard
  through anything; **mallet instruments manage parallel intervals or a tune
  with simple accompaniment far more easily than two independent lines**;
  harp chords are rolled upwards, thick voicings resonate, thin ones sound
  meek. The Chinese-orchestra pages: the bowed strings "sandwich" a melody,
  lines told apart by register yet blending as a whole.
- *Good Idea:* (1) **velocity**: one Velocity for every note in a part.
  A piano's (and most sample libraries') colour follows velocity, and a
  human player accents the beat. *Idea:* a "Dynamics" or "Feel" amount -
  downbeats a little louder, off-beats and triplet notes a little softer
  (by `I.strength`), the chords' inner notes softer than their top, and the
  tune a touch over the chords: calculated, no dice, so no idea number
  changes. This answers the MIDI complaint directly. (2) Broken's patterns
  over four-note voicings are easier and more pianistic than over triads -
  already true of Drop 2 and Open.

### Andrew Hugill, *The Orchestra: A User's Manual* (154 pages)

Mostly short pages pointing to recordings (the Philharmonia's archive) and
range charts that are pictures (no text came through). Read: the section
combinations, tuttis, string/woodwind/brass section pages, the piano and
keyboard pages, MIDI, voices; skimmed: the instrument technique pages
(articulations, effects, extended techniques, mutes, bowing, plucking,
beaters), history, seating, score layout, longest notes and dynamic shapes.

- **Voice ranges**: soprano C4-C6 (choir D4-G5, untrained children
  C4-D5), mezzo G3-Bb5, alto F3-Gb5 (choir G3-C5), tenor C3-C5 (choir
  C3-G4), baritone G2-E4, bass Eb2-D4. An untrained voice has about an
  octave and a third.
- **Combinations** heard again and again: the horn filling in with the
  woodwinds; **a tune in octaves over string accompaniment**; bassoons in
  thirds over pizzicato strings; woodwinds in thirds and sixths
  accompanying; strings in close harmony; **chords voiced by the harmonic
  series** ("an octave between the lowest notes, then intervals getting
  closer together the higher they are... a very smooth sound"); piccolo on
  top of a tutti for brightness; Holst's *Jupiter* orchestrating the same
  tune six ways.
- **Piano** in the orchestra: little sustain, "swallowed up" in the wash.
- **MIDI and General MIDI**: notes on and off, sixteen channels, 128
  programs; the percussion set separate, each sound on one key (35 Acoustic
  Bass Drum, 36 Bass Drum 1, 38 Acoustic Snare, 42 Closed Hi-Hat, 46 Open
  Hi-Hat, 49 Crash, 51 Ride...).
- *Good Idea:* `I.melodyRange` gives the tune a tenth (nine steps of a
  seven-note scale), centred on the fifth above the tonic nearest the
  register: inside an untrained voice's octave and a third, and the
  cantus firmus's "a tenth at most". The drum notes follow the General MIDI
  set on channel 10, as this page lists. *Idea:* the idea's parts could
  carry a General MIDI program change (piano for chords, bass for bass), so
  a fresh track sounds right with a GM synth - but most REAPER users load
  their own instruments, so off by default if ever.

### Rimsky-Korsakov, *Principles of Orchestration* (1912, Gutenberg 33900)

Read: the preface and axioms, Chapter II's opening (melody) and its
section headings, all of Chapter III (harmony). Skimmed: Chapter I (the
instruments), IV (composition of the orchestra), V-VI (voices), which are
about instruments Good Idea does not have.

- **Axioms**: "in the orchestra there is no such thing as ugly quality of
  tone"; "orchestral writing should be easy to play"; write for the
  orchestra that will play it.
- **Melody** must stand out from the accompaniment: by dynamics, by
  contrast of timbre, by doubling, by crossing above other parts; "melody
  planned in the upper parts stands out from the very fact of position
  alone", less so in the bass, **least in the middle**. Melodies in octaves,
  double octaves, **in thirds and sixths**.
- **Harmony is four parts** with duplications: extra parts are the three
  upper parts doubled an octave up, the bass doubled an octave down. "Every
  transition from four-part harmony to three... must coincide with a new
  idea". **"Unsatisfactory resonance is often solely the outcome of faulty
  handling of parts"** - a passage with good voice-leading "will sound
  equally well if played by strings, woodwind or brass".
- **"The bass of an inversion of the dominant chord should never be
  doubled in any of the upper parts"** - nor that of other seventh and
  diminished-seventh chords. Consecutive octaves between upper parts are
  not allowed; fifths from doubling chords of the sixth don't matter.
- **Spacing**: chords follow the natural harmonic scale - **wide intervals
  (octaves and sixths) at the bottom, fifths and fourths in the middle,
  thirds and seconds on top**. "**The bass should rarely lie at a greater
  distance than an octave from the part directly above it**." "Nothing is
  worse than writing chords the upper and lower parts of which are
  separated by wide, empty intervals, especially in forte; in piano such
  distribution may be possible." When parts diverge, fill the middle; when
  they converge, drop middle parts one by one. Close writing is the norm.
- **Balance**: each chord either all doubled or all single; follow the
  normal order of registers; give concords (octaves, thirds, sixths), not
  discords, to like instruments; "one tone quality for the stationary and
  another for the moving parts"; the extreme parts are the thinnest, the
  middle the fullest. The horn and bassoon reconcile woodwind and brass;
  a full brass chord doubled by the same chord in full woodwind gives "a
  magnificent and uniform tone".
- *Good Idea:* two concrete gaps, both now confirmed by three sources:
  (1) **don't double an inverted chord's bass above it** - a first or
  third inversion's chords part (and a Close voicing over a Phrase's own
  bass) should leave the bass note out of the upper voices when it is the
  third, the seventh or the leading tone; (2) **bass to chords: no more than
  an octave gap** - measure how often the gap between the bass part and the
  lowest chord note exceeds an octave (likely in Measures with a low bass
  and a Close chord near C4) and how often they cross. The sweep can
  tally both before anything changes.

### Berlioz, *Treatise on Instrumentation* (Michel Austin's translated excerpts)

The page is a selection: the preface, chapter 1, excerpts on each
instrument, the orchestra and its layout, and *On the Art of Conducting*.
Read: preface, introduction, chapter 1, the orchestra and conducting
chapters; sampled the instrument excerpts.

- "**Any sounding body that is used by a composer is a musical
  instrument.**" Instrumentation "colours the melody, harmony and rhythm,
  or produces effects sui generis". It cannot be taught "from a poetical
  point of view"; one can only point to what the masters did.
- "What results in a good effect is good, and what results in a bad one is
  bad" - against rules for their own sake.
- Practical: to give power to a violin line, unison is better than the
  second violins an octave below; the cellos usually double the basses an
  octave up but are better freed for melody, or for faster figuration over
  the basses' simpler line; instruments too powerful or characterful
  (trombones, trumpets) are wasted "merely to provide the harmony"; the
  oboe for simplicity, grace or a weak soul's grief - never for heroics
  (the same tune on clarinets keeps its nobility). Choruses: write within
  the comfortable middle, divide voices at the extremes.
- On layout and balance: opera orchestras added brass without adding
  strings, "so the tonal balance is destroyed, the violins can scarcely be
  heard".
- *Good Idea:* "any sounding body" is the spirit of Good Idea's MIDI: the
  musician picks the instrument. The tune/chords/bass roles hold whatever
  plays them, which is Rimsky's point too (good part-writing sounds well
  on anything).

### Esther Singleton, *The Orchestra and its Instruments* (1917, Gutenberg 73991)

A popular history: the orchestra's growth from the court bands, then each
instrument's history and character, written for concert-goers. Skimmed by
chapter. Nothing in it changes how Good Idea calculates an idea; its
descriptions of character (the bassoon's comedy, the horn's romance, the
oboe's pastoral) agree with Belkin's glossary and Berlioz.

### Wikipedia, *Orchestration*

Orchestration is "the assignment of different instruments to play the
different parts (melody, bassline, etc.)"; a C major chord's notes are
placed by instrument and register (low C to cellos and basses, G to the
violas, E to the violins in two octaves); a melody on the first violins is
commonly doubled an octave below by the seconds, **or harmonised in thirds
and sixths**; colour doublings (violins with glockenspiel, piccolo with
celesta). Transcription follows the original closely; arrangement changes
it. Big-band arrangers "flesh out" a **lead sheet** - melody and chords -
into parts, which is the step Good Idea's chords and bass take.

### Wikipedia, *List of chords*

The table of named chords with their pitch classes (major, minor,
augmented, diminished; sixth, added second/ninth, 6/9; sevenths of every
quality, ninths, elevenths, thirteenths; suspended and 7sus4; dominant
7#9 "Hendrix"; the augmented sixths; the Neapolitan; secondary dominants,
leading-tone and supertonic chords; named sonorities - Tristan, Petrushka,
Mystic, Elektra, Farben, So What, Psalms, Dream - and the power chord, a
bare fifth). *Good Idea:* every chord Good Idea makes is in this list, and
`T.flavourChord`'s names match it (add2 = "major added-second", 6 =
"major sixth", sus = "suspended"). Not yet made: **6/9**, **power chord**
(a fifth, for a rock style of Chords), and the chromatic ones (secondary
dominants, Neapolitan, augmented sixths; see Chromatic harmony above).

### REAPER: ReaScript, the API functions page, and the JSFX reference

- **ReaScript** (REAPER 7.79): EEL2, **Lua 5.4** (embedded; REAPER 6 used
  5.3) and Python; scripts are added through the Actions window and can be
  bound to keys or toolbars; the API documentation is generated by REAPER
  itself (Help > ReaScript documentation). Good Idea's Lua runs on 5.4 in
  the tests as in REAPER.
- **API functions**: checked against every call in `gi_place.lua` and the
  window on 2026-10-01 (see CLAUDE.md, "REAPER, from a script"); nothing in
  this session added a call.
- **JSFX** (EEL2 effects: language essentials, special variables, user
  functions, strings, file I/O, memory/FFT, graphics, the preprocessor,
  MIDI). Read the MIDI page (`midirecv`/`midisend` in `@block`, passing
  through what isn't handled) and skimmed the rest. Good Idea writes MIDI
  items; it needs no JSFX. A JSFX would be the way to make Good Idea play
  *live* (generating notes as the transport runs), which is a different
  program.
