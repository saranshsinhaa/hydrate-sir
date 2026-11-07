# Hydrate, Sir — Design Specification

> The single source of truth for how the app looks, sounds and behaves.
> Changes to look, voice or behaviour go through this file first. Deliberate departures from the original mockups are recorded in §14.

---

## 1. Concept

**Hydrate, Sir** is a water reminder for Android, presented as a personal butler named **Hargreaves**.

- **Visual language:** vintage apothecary / Victorian household — cream label paper, bottle-green ink, typewriter numerals, a red rubber stamp. Analog, printed, tactile. No gradients, no glassmorphism, no emoji.
- **Verbal language:** a discreet, dry, impeccably polite Victorian English butler. First person ("I shall…"), addresses the user as *sir*, *madam* or by name.
- **Core metaphor:** each reminder is a **glass** Hargreaves brings at a set time. The day is a row of glasses to be taken. History is **The Cellar Book**.

### Glossary (use these words in UI, code comments and strings)

| Concept | UI term | Code name |
|---|---|---|
| App | Hydrate, Sir | `hydrate_sir` |
| Persona | Hargreaves | — |
| One reminder / one logged serving | a **glass** | `Glass`, `IntakeEntry` |
| Daily target | **water each day** / "the agreed amount" | `dailyGoalMl` |
| Size of one serving | **size of each glass** | `glassSizeMl` |
| Onboarding result | **The Arrangements** | `ArrangementsScreen` |
| History | **The Cellar Book** | `CellarBookScreen` |
| Settings | **Standing Instructions** | `InstructionsScreen` |
| Form of address | **Address me as** | `Address { sir, madam, name }` |
| How reminders appear | **How I announce myself** | `ReminderStyle { note, door }` |

---

## 2. Colour

All colours are flat. Never use opacity to create new text colours; use the tokens.

| Token | Hex | Use |
|---|---|---|
| `paper` | `#E9E1CC` | Screen background |
| `label` | `#F7F2E4` | Cards / label surfaces, text on ink |
| `ink` | `#1F3B2D` | Primary text, borders, primary buttons, filled glasses |
| `inkDeep` | `#16291F` | Dark backdrop (full-screen reminder, splash) |
| `stamp` | `#A3271F` | Rubber stamps, overdue glass, destructive action, goal line |
| `rule` | `#CFC5AA` | Hairline dividers, ledger lines |
| `sage` | `#7C8F80` | Decorative only (e.g. quiet-hour band). **Never for text.** |
| `water` | `#A9C2B3` | Water fill in illustrations only |

**Contrast (checked):** ink on paper ≈ 9:1, ink on label ≈ 10:1, stamp on label ≈ 6.7:1, label on ink ≈ 10:1. All pass WCAG AA for body text.

**Dark mode:** v1 ships light only (the paper metaphor *is* the brand). Force `ThemeMode.light`. A dark "candlelight" theme may come later. The full-screen reminder uses `inkDeep` as its backdrop.

---

## 3. Typography

Two families, both **SIL Open Font License**, bundled in `assets/fonts/` with their `OFL.txt` (never fetched at runtime).

| Role | Family | Weights | Why |
|---|---|---|---|
| **Serif** — headings, body, Hargreaves' voice | **Libre Caslon Text** | 400, 400 italic, 700 | Classic English book face |
| **Mono** — numbers, times, labels, buttons, stamps | **Courier Prime** | 400, 700 | Typewriter; reads as "printed label" |

### Type scale (logical px; respect system text scaling)

| Style | Family | Size / line-height | Weight | Notes |
|---|---|---|---|---|
| `display` | Caslon | 34 / 1.05 | 700 | Brand lock-up "HYDRATE," (+ italic 400 "Sir") |
| `h1` | Caslon | 30 / 1.15 | 700 | Screen titles |
| `h2` | Caslon | 26 / 1.25 | 700 | Welcome greeting |
| `bigNumber` | Caslon | 40 / 1.05 | 700 | "1 250" ml taken today |
| `numberXL` | Courier Prime | 40 / 1.0 | 700 | The Arrangements daily amount |
| `numberL` | Courier Prime | 26–34 / 1.0 | 700 | Steppers (70 kg, 07:00) |
| `voice` | Caslon *italic* | 16–18 / 1.4–1.6 | 400 | Anything Hargreaves *says* |
| `body` | Caslon | 16 / 1.5 | 400 | Row labels, descriptions |
| `small` | Caslon italic | 12–13 / 1.4 | 400 | Hints, disclaimers |
| `button` | Courier Prime | 16, letter-spacing 0.08em, UPPERCASE | 700 | Primary buttons |
| `chip` | Courier Prime | 13–14, UPPERCASE | 700 | Option chips |
| `eyebrow` | Courier Prime | 11–12, letter-spacing 0.12–0.24em, UPPERCASE | 400 | Section labels: "ABOUT YOU" |
| `stamp` | Courier Prime | 11–15, letter-spacing 0.08em, UPPERCASE | 700 | Rubber stamps |
| `time` | Courier Prime | 12–13 | 400 | Glass slot times |

**Number formatting:** thousands separated by a **space**: `2 800 ml`, never `2,800`. Times are 24-hour `HH:mm`. Dates: `SAT 7 NOV` (eyebrow) or `Saturday, 7 November` (prose).

**Rule of thumb:** *Hargreaves speaks in Caslon italic; the household's records are typed in Courier.*

---

## 4. Shape, spacing, elevation

- **Spacing scale:** 4, 6, 8, 10, 12, 14, 16, 18, 22, 26 px. Screen side padding **18–22 px**; top padding **26–28 px**.
- **Corner radius:** **0** for buttons, chips, steppers, label cards. Exceptions: glass slots and toggles are fully round; the brand label on Welcome uses 6 px.
- **Borders:** ink, **1.5 px** for interactive outlines; **2 px outer + 1 px inner** (4 px gap) for the double-ruled label card; **1 px `rule`** for dividers; **1 px dashed `rule`** for ledger lines.
- **Elevation / shadows:** none. Depth comes from borders and the paper/label contrast.
- **Touch targets:** minimum **48 × 48** (Android guideline; mockups show 44); primary buttons are **60 px** tall.

---

## 5. Components (`lib/app/widgets/`)

### 5.1 Label card (`LabelCard`)
The signature surface. `label` fill, 2 px ink border, 4 px padding, inner 1 px ink border, inner padding 14–18 px.

### 5.2 Rubber stamp (`Stamp`)
Text in `stamp` colour, 2–2.5 px `stamp` border, padding 1–4 × 6–10 px, **rotated −6° to −9°** (or +8° for "AS YOU WISH"). Courier Prime 700 uppercase, may be two lines. At most one per card. Decorative duplicate of nearby text, so excluded from semantics.

### 5.3 Glass slot (`GlassSlot`)
Circle + time label below (Courier 12).

| State | Circle | Content | Time colour |
|---|---|---|---|
| upcoming | 1.5 px ink border, transparent | — | ink |
| taken | ink fill | `label`-coloured check mark (stroke 2.4) | ink |
| overdue | 2 px `stamp` border | `!` in stamp, Courier 700 | stamp |

Grid: 6 columns on Today, 5 on The Arrangements.

### 5.4 Buttons
- **Primary (`InkButton`):** ink fill, `label` text, Courier 700 16 uppercase, 60 px tall, square, full width.
- **Secondary / icon (`InkOutlineButton`):** transparent, 1.5 px ink border, ink icon (e.g. undo, 60 × 60).
- **Text link (`InkLink`):** Caslon italic 14, underlined, ink.
- **Destructive:** Courier 700 13 uppercase, `stamp`, underlined.

### 5.5 Option chips (`ChoiceChips`)
Equal-width grid, 48 px tall, 1.5 px ink border, square. Selected = ink fill + label text, `Semantics(selected: true)`.

### 5.6 Stepper (`InkStepper`)
Value in Courier 700 (26–34) with unit in Courier 400 14; two 48 px square outline buttons `−` `+`. Long-press repeats. Steps: weight 1 kg (30–200), age 1 yr (12–100), times 15 min, daily amount 50 ml (1 000–6 000).

### 5.7 Toggle (`InkSwitch`)
46 × 26 pill, 1.5 px ink border. On: ink track, label knob right. Off: transparent track, ink knob left. Row: Caslon 16 label + Caslon italic 13 hint, min height 56; the whole row is tappable.

### 5.8 Settings row (`InstructionRow`)
Min height 48, Caslon 16 label left, Courier 15 value right + small chevron, 1 px `rule` divider.

### 5.9 Bottom navigation (`LedgerTabs`)
Three text tabs, Caslon italic 15, separated from content by a 1 px ink rule. Active tab 700 weight, non-italic, underlined. Labels: **Today · Cellar Book · Instructions**. No icons.

### 5.10 Progress rule (`ProgressRule`)
6 px tall, 1 px ink border, ink fill to `taken / goal` (capped at 100%).

### 5.11 Cellar Book chart
- Plot area 200 px tall on a label card, x-axis 1.5 px ink.
- Bars: equal width, 10 px gap (week) / 2 px gap (month), 1.5 px ink outline, no bottom border. **Goal met:** solid ink. **Fell short:** 45° hatch, 1 px ink lines every 4 px.
- Goal line: 1.5 px dashed `stamp`, labelled `AGREED 2 800` (Courier 700 11, stamp) at the right.
- Y max = `max(goal × 1.18, maxValue)`; no y-axis labels. Legend: ■ Goal met · ▨ Fell short.
- Hand-rolled `CustomPainter` (no chart package needed for this look).

### 5.12 Illustrations & icons
Line drawings in ink, stroke 2, round caps/joins, drawn with `CustomPainter` or Android vector drawables (no SVG package needed). No icon fonts in the main UI.

- **Tray with glass** (Welcome, 220 × 150) — the glass on a silver tray with a red sparkle.
- **Bow tie** (notification small icon / app mark) — white vector drawable `ic_stat_bowtie` for notifications; accent colour `ink`.
- **Ornament** — a 4-point star in `stamp` between two 1 px ink rules.
- **Launcher icon** — adaptive: foreground ink bow tie, background `label`.

---

## 6. Screens

Phone reference: **390 × 844** logical px. All screens scroll if content exceeds height.

### First visit (onboarding)

**1. Welcome** — tray illustration → brand label card (`IN SERVICE SINCE MMXXVI` / ornament / `HYDRATE,` *Sir* / `HARGREAVES · BUTLER`); h2 "Good day. Hargreaves, at your service."; voice "I shall see to it that you never go thirsty. First, if I may, a few discreet questions."; primary **VERY WELL, PROCEED**; footer "Your particulars never leave this house."

**2. A Few Particulars** (I OF III) — address chips **SIR / MADAM / BY NAME** (by name → name field); weight stepper (70 kg); age stepper (32); exertion chips **LEISURELY / MODERATE / VIGOROUS**; climate chips **TEMPERATE / RATHER WARM**; live dashed box "I should think, daily — **2 800 ml**"; **CONTINUE**; "‹ BACK".

**3. Your Hours** (II OF III) — **YOU RISE AT** (07:00) and **YOU RETIRE AT** (23:00), ±15 min, minimum 6 h awake; 24-hour bar (hatched sleep, ink reminder window, sage quiet hour); legend; voice summary.

**4. The Arrangements** (III OF III) — meta row; "I should propose, daily:" stepper; amended note + **AS YOU WISH** stamp; glass size chips **150 200 250 300 350 500**; typed summary + time grid; primary **THAT WILL DO NICELY** → asks for notification permission (with Hargreaves' explanation first), schedules, goes to Today; small print disclaimer.

### Daily use

**5. Today** — greeting + date; label card with **TAKEN TODAY** "1 250 / 2 800 ml", stamp "5 OF 12 TAKEN", progress rule; Hargreaves' line; glass slot grid; undo + **I'VE HAD MY GLASS · 250 ml**; "I had a different amount" sheet (150/250/330/500/750 + custom); bottom nav. If notifications are blocked, Hargreaves says so in a small note with a way to fix it.

**6. Reminders** — see §9.

**7. The Cellar Book** — **WEEK | MONTH**; remark; chart; stats (**DAILY AVG**, **DAYS MET**, **BEST RUN**, today excluded until it ends); recent days list.

**8. Standing Instructions** — ABOUT YOU · YOUR HOURS · THE ARRANGEMENTS · MANNERS (chime, ask again if ignored, respect the silent switch, **How I announce myself**) · **BURN THE CELLAR BOOK** with confirmation ("Burn the Cellar Book, {address}? Every record shall be lost to the flames." **[BURN IT] [ON SECOND THOUGHT]**) · footer `Hydrate, Sir v{version} · Hargreaves, butler`. Changing profile values recalculates the suggestion; if the goal was amended, ask "Shall I revise the daily amount to {n} ml, or keep your {m} ml?"

---

## 7. Voice & copy

All strings live in `lib/copy/` with an `{address}` placeholder.

### Rules for Hargreaves
1. First person, never "we".
2. Address the user at most once per sentence, and not in every line.
3. Apologise before interrupting: "Forgive the intrusion", "If I might".
4. Never nag, never guilt. Overdue is stated, not scolded. Never mention a bad day twice.
5. Praise is dry and sparing: "Most commendable." "Splendid."
6. Short. Notifications ≤ 2 short sentences.
7. No emoji, no exclamation marks.
8. British spelling.

### Today message logic
| Condition | Message |
|---|---|
| all glasses taken | "Every glass taken. Splendid, {address}. That will be all for today." |
| ≥2 overdue | "Forgive me, {address}, but {n} glasses remain untouched. Shall I bring one now?" |
| 1 overdue | "Your {HH:mm} glass is poured and waiting, {address}." |
| before first glass | "Good morning, {address}. Your first glass at {HH:mm}." |
| otherwise | "Your next glass at {HH:mm}, {address}. Do carry on." |
| after last slot, goal not met | "The hour grows late, {address}. Perhaps one more before bed." |

### Cellar Book remarks (ratio of days met, complete days only)
| Days met | Remark |
|---|---|
| 100% | "An immaculate {week/month}, {address}. I am almost moved." |
| ≥70% | "A most creditable {week/month}, {address}, with but a few lapses." |
| ≥40% | "A respectable {week/month}, {address}. Of {worst day}, I shall say nothing." |
| <40% | "A quieter {week/month}, {address}. Tomorrow is, as ever, another day." |
| no complete days yet | "The Cellar Book awaits its first entry, {address}." |

### Greetings
05:00–11:59 "Good morning" · 12:00–17:59 "Good afternoon" · 18:00–04:59 "Good evening".

---

## 8. Logic

### Suggested daily amount
```
perKg    = age < 30 ? 40 : (age <= 55 ? 35 : 30)
exertion = { leisurely: 0, moderate: 350, vigorous: 700 }
climate  = { temperate: 0, warm: 500 }
suggested = roundTo50(weightKg * perKg + exertion + climate)
```
Example: 70 kg, 32 yrs, moderate, temperate → **2 800 ml**. Keep both `suggestedMl` and `dailyGoalMl`.

### Schedule
```
glasses  = ceil(dailyGoalMl / glassSizeMl)
first    = wakeTime
last     = sleepTime − 60 min
interval = (last − first) / (glasses − 1)     // if glasses > 1
times[i] = round(first + i × interval)
```
- Each slot is a daily reminder. **Exact alarms** when the user allows them (reminders arrive on the minute), falling back to inexact (`inexactAllowWhileIdle`) otherwise.
- On any settings change: cancel all, reschedule. Also after reboot and app update.
- Logging is by ml: `glassesTaken = floor(totalMlToday / glassSizeMl)`; slots fill left-to-right.
- When a glass is logged before its slot time, that slot's reminder is skipped for today (no reminding someone who's already drunk).
- "Ask again if I am ignored": one follow-up 15 min after a reminder if nothing was logged; cancelled when intake is logged.
- **Day boundary:** wake time minus 3 h, so a late-night glass counts for the day it belongs to.

---

## 9. Reminders

Two styles, chosen in Standing Instructions → **How I announce myself**:

| Style | UI label | Behaviour |
|---|---|---|
| `note` (default) | "A discreet note" | Standard notification in the panel, heads-up when unlocked |
| `door` | "At the door" | Full-screen reminder that lights the screen when locked (like an alarm); heads-up when in use |

### Panel notification
- **Channel:** id `hargreaves`, name "Hargreaves' reminders", importance high. A second channel `hargreaves_door` for full-screen reminders.
- **Small icon:** `ic_stat_bowtie` (white). **Colour:** ink.
- **Title:** "Your {glassSize} ml, {address}." **Body:** "Forgive the intrusion. Glass {i} of {n} is poured and waiting."
- **Actions:** **Thank you** (logs one glass in the background, no app launch) · **In 15 minutes** (one-off snooze) · **Not now** (dismiss).
- **Follow-up:** "If I might, {address}" / "Your {HH:mm} glass remains untouched. I trust all is well."
- **Variants:** first glass "Good morning, {address}. Your first glass, before the household stirs."; halfway by noon "Half the day's water by noon. Most commendable, {address}."; last "The last glass of the evening, {address}. Then, to bed."

### Full-screen reminder ("At the door")
- `inkDeep` backdrop, Hargreaves' line in Caslon italic, the glass illustration, glass i of n and the time.
- Large **I'VE HAD MY GLASS** (logs and closes), **IN 15 MINUTES**, and a quiet **Not now** link.
- Shows over the lock screen without unlocking; never auto-dismisses before the user acts, but stops sounding after 30 s.
- Needs Android's full-screen-intent access; if it's not granted, Hargreaves explains and falls back to the panel.

---

## 10. Motion & feedback

Minimal and mechanical, like a stamp or a typewriter.
- Glass taken: slot fills over 150 ms, check mark draws in 200 ms; light haptic.
- Stamp change: scale 1.15 → 1.0 with a 2° rotation settle, 180 ms, `Curves.easeOutBack`.
- Screen transitions: plain fade 200 ms. No sliding cards, no confetti.
- Honour reduce motion (`MediaQuery.disableAnimations`).

---

## 11. Accessibility

- Every interactive element ≥ 48 × 48.
- Glass slots expose semantics: "07:00, taken" / "13:49, overdue" / "15:11, upcoming".
- Stamps are decorative duplicates → excluded from semantics.
- Chips/toggles expose selected/checked state.
- Overdue is signalled by colour **and** the `!` mark.
- System font scaling up to 1.3× without clipping (screens scroll).

---

## 12. Theme

Implemented in `lib/app/theme/` (`tokens.dart`, `text_styles.dart`, `theme.dart`). Material 3 is used only as plumbing: no ripples (`NoSplash`), square shapes, no elevation.

---

## 13. Don'ts

- No Material default purple, ripples, FABs, rounded pill buttons or elevation shadows.
- No emoji, exclamation-heavy copy, streak-shaming or "You missed your goal!".
- No generic icon fonts in the main UI (text tabs, line drawings only).
- No system fonts — always Caslon or Courier Prime.
- Don't call reminders "doses" or "notifications" in UI copy — they are **glasses**.

---

## 14. Decisions log

Departures from the original mockups, made for the user's sake:

| # | Decision | Why |
|---|---|---|
| 1 | Exact alarms with inexact fallback | A reminder that turns up 10 minutes late feels broken |
| 2 | Two reminder styles: panel note and full-screen "At the door" | Some people want a nudge, others want an alarm |
| 3 | Skip a slot's reminder if the glass was already logged | Don't remind someone who just drank |
| 4 | Touch targets 48 px, not 44 | Android accessibility guideline |
| 5 | Units: millilitres only in v1 | Fluid ounces add conversions everywhere for little gain; can come later |
| 6 | Extra Today message after the last slot; empty Cellar Book remark | Mockups didn't cover these states |
| 7 | No SVG or chart packages; drawn with `CustomPainter` | Fewer dependencies, exact look |
