# AGENTS.md — rules for contributors and AI coding agents

Hydrate, Sir is an **offline Android water-reminder app** built with Flutter. Its character is Hargreaves, a Victorian English butler who works out how much water you need and politely reminds you to drink it.

This repository will become public. Treat every file as something strangers will read.

---

## 1. Hard rules (never break these)

1. **Offline except for updates.** The app's only network use is checking GitHub Releases for a new version and downloading it.
   - Allowed: `GET` requests to `api.github.com/repos/saranshsinhaa/hydrate-sir/releases/latest` and that release's asset downloads. Nothing about the user is ever sent: no identifiers, no usage data.
   - Never: Firebase, analytics, crash reporting, ads, remote config, `google_fonts` (it downloads fonts at runtime), or any other request.
   - `scripts/check.sh permissions` fails the build if the release APK asks for any permission outside the allowlist in section 10.
   - Fonts are bundled in `assets/fonts/` with their licence files.
   - All user data stays on the device.
2. **Limited git for AI agents.** Agents may read git state and make **local commits** (`git add`, `git commit -m`) in small, gradual steps, each passing the hooks. Agents never push, tag, amend, merge, rebase, reset, checkout/switch, stash, restore, clean, `rm`, delete branches, change git config, or run any `gh` command that creates or changes something on GitHub. Anything destructive needs the human's explicit permission first; pushing is always the human's job.
3. **Nothing installed on the developer's machine.** No `brew`, `sdkmanager`, `npm -g`, `pip`, `dart pub global` and so on. If a tool is missing, stop and print the exact command for the human to run. `flutter pub get` and `flutter pub add` for project dependencies are fine.
4. **Public-safe content only.** Never put private links (private docs, private design files, shared-session URLs), personal emails, device serial numbers, tokens, passwords or local machine paths into tracked files. Links must work for a stranger.
5. **No secrets in git:** `*.jks`, `*.keystore`, `key.properties`, `.env*` are ignored and stay that way.
6. **Ask the human before:** adding a dependency not already listed in section 5, adding an Android permission not listed in section 10, changing the database schema after the first release, changing CI/release workflows, or deleting files you didn't create.

## 2. Tests are required

Every feature, fix and change ships with tests in the same change. Nothing existing may break.

| Kind | Where | What it covers | Runs |
|---|---|---|---|
| Unit | `test/` | Pure logic: goal formula, glass times, streaks, quiet hours, scheduling maths, repositories (in-memory Drift) | pre-commit, CI |
| Widget | `test/` | Each screen renders, buttons do what they say, copy appears, semantics labels exist | pre-commit, CI |
| Integration | `integration_test/` | Real flows on a device: onboarding → today → log a glass → cellar book; reminders scheduled after settings change | before every release, on a phone |

- A bug fix starts with a failing test that reproduces it.
- Test files mirror `lib/` paths: `lib/features/today/x.dart` → `test/features/today/x_test.dart`.
- Time-dependent code takes a clock or `now` parameter so tests are deterministic. No real timers or sleeps in tests.
- Don't delete or weaken an existing test to make a change pass. If a test is genuinely wrong, say why.

## 3. Checks and git hooks

`scripts/check.sh` is the single source of truth, used by the hooks and CI.

| When | Runs |
|---|---|
| `pre-commit` hook | format, analyze (zero issues), unit + widget tests |
| `commit-msg` hook | commit message rules (section 8) |
| CI on push/PR (`ci.yml`) | `scripts/check.sh all`: the above plus a release build and the permission allowlist |

Run `scripts/setup.sh` once after cloning to turn on the hooks. Before saying a task is done, an agent runs `scripts/check.sh format analyze test`. If the UI changed, it also runs the app on a phone and checks it there.

## 4. Commands

```bash
scripts/setup.sh                                          # first-time setup (installs nothing)
flutter run                                               # run on a connected phone
scripts/check.sh format analyze test                      # quick checks
scripts/check.sh all                                      # full checks incl. release build
flutter test integration_test                             # end-to-end on a phone
dart run build_runner build --delete-conflicting-outputs  # regenerate Drift/Riverpod code
dart format lib test integration_test                     # fix formatting
```

## 5. Stack (don't swap without asking)

- **Flutter** version pinned in `pubspec.yaml` (`environment.flutter`); CI reads the same pin.
- **UI:** fully custom theme to match the design, not stock Material.
- **State:** Riverpod.
- **Database:** Drift (SQLite) for the intake log; `shared_preferences` for simple settings.
- **Reminders:** `flutter_local_notifications` + `timezone`. Exact alarms (`SCHEDULE_EXACT_ALARM`), falling back to inexact if the user denies it.
- **Charts and illustrations:** hand-drawn with `CustomPainter`; no chart or SVG packages.
- **Approved packages:** `flutter_riverpod`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `shared_preferences`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `intl`; dev: `build_runner`, `drift_dev`. Anything else needs a one-line reason and the human's approval.

## 6. Project layout

```
lib/
  main.dart
  app/            theme (colours, fonts, text styles), router, app widget
  features/
    onboarding/   welcome, particulars, hours, arrangements
    today/        daily screen
    cellar_book/  history
    instructions/ settings
  data/           drift database, repositories, settings store
  services/       reminder scheduler, notification action handler
  copy/           every user-facing string (Hargreaves' voice)
assets/fonts/
test/             mirrors lib/
integration_test/ on-device flows
docs/             development.md, design.md, screenshots/
tool/screenshots/ renders the README screenshots
scripts/          setup.sh, check.sh
.githooks/        pre-commit, commit-msg
```

- Widgets never talk to the database directly: widget → provider → repository → Drift.
- Business logic is plain Dart in pure functions, with unit tests.

## 7. Design

**[docs/design.md](docs/design.md) is the full specification** (colours, type, components, screens, copy, logic, reminders). Read it before building any UI or copy. The summary below is for quick reference; docs/design.md wins if they differ.

- **Colours:** paper `#E9E1CC`, card `#F7F2E4`, bottle green `#1F3B2D`, deep green `#16291F`, stamp red `#A3271F`, rule line `#CFC5AA`.
- **Fonts:** Libre Caslon Text for body and headings; Courier Prime for labels, numbers and buttons (uppercase, letter-spaced). Both are SIL Open Font License; ship the licence files.
- **Accessibility:** touch targets at least 48 dp, text contrast at least 4.5:1, semantic labels on icon-only buttons, layouts that survive large font scales.
- **Daily goal formula:** weight × 40 ml (under 30), × 35 ml (30–55), × 30 ml (over 55); +350 ml moderate exertion, +700 ml vigorous; +500 ml warm climate; rounded to the nearest 50 ml. Glasses = goal ÷ glass size, rounded up, spread evenly from waking until one hour before bed. Shown as a rough guide, not medical advice.
- **Screens:** Welcome, A Few Particulars, Your Hours, The Arrangements, Today, reminder notification, The Cellar Book (history), Standing Instructions (settings).
- When the design is unclear, pick the simplest option that fits and say so. Don't invent features.

## 8. Git conventions

- `main` is always green. Work happens on short branches: `feat/…`, `fix/…`, `chore/…`, `docs/…`, `test/…`, `ci/…`.
- **Commit messages are one line only**, in [Conventional Commits](https://www.conventionalcommits.org/) form, with no body and no trailers:
  - `type(scope): summary`, where type is one of `feat fix docs style refactor perf test build ci chore revert`
  - lowercase summary in the imperative mood, no trailing full stop, 72 characters at most
  - examples: `feat(today): add glass tracker`, `fix(reminders): reschedule after reboot`, `test(goal): cover over-55 formula`
- **No attribution of any kind:** no `Co-Authored-By`, no "Generated with …", no tool or AI names.
- The `commit-msg` hook rejects anything else.
- Releases are tag-based (`vX.Y.Z`): pushing a tag builds and publishes the APK.

## 9. Hargreaves' voice: Victorian English

All user-facing text, including notifications, errors, empty states, permission requests and settings labels, is written in the voice of a Victorian English butler.

- **British spelling** throughout (colour, organise, millilitre, programme); the app locale is `en-GB`.
- **Formal Victorian register:** "I should be obliged…", "If I may be so bold…", "Very good, sir.", "Most commendable.", "I shall attend to it directly." No modern slang, emoji, exclamation-heavy cheerleading or tech jargon in the app's copy ("sync", "app", "data", "error" become things like "records", "the household", "a small mishap").
- **First person**, addressing the user as Sir, Madam or their name, whichever they chose.
- **Manners:** apologises before interrupting, never nags, praises sparingly and dryly, never mentions a bad day twice.
- **Names:** glasses (not doses), The Arrangements (the plan), The Cellar Book (history), Standing Instructions (settings).
- Every string lives in `lib/copy/`, never inline in widgets, so the voice stays consistent and testable.
- Clarity beats flourish: a button's meaning must be obvious at a glance ("I'VE HAD MY GLASS", not riddles).

## 10. Reminders on Android

- **Approved permissions:** `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`, and for updates only `INTERNET` and `REQUEST_INSTALL_PACKAGES`. The list lives in `scripts/check.sh`.
- Ask for `POST_NOTIFICATIONS` at the end of onboarding, with Hargreaves explaining why.
- Reschedule every reminder when settings change, after a reboot (`RECEIVE_BOOT_COMPLETED`) and after an app update.
- Guide the user to exempt the app from battery optimisation; some manufacturers' Android builds (including Nothing OS) delay background alarms.
- Notification actions (Thank you / In 15 minutes / Not now) work without opening the app.
- Reference test device: Nothing Phone (3), Android 17.

## 11. Licence

The app is GPL-3.0 (`LICENSE`). Contributions are accepted under the same licence. Any new dependency or bundled asset must be GPL-3.0-compatible (MIT, BSD, Apache-2.0, OFL and the like); check before adding.

## 12. Public docs

- `README.md` is for people who want to **use** the app, written in Hargreaves' voice. No build or release instructions there.
- Developer setup lives in `docs/development.md`; keep it short.
- When a screen changes, regenerate the README screenshots: `flutter test tool/screenshots --update-goldens`. They use made-up data; never use real device screenshots with personal details.

## 13. Working style

- Read the relevant code and this file before changing anything.
- Make the smallest change that does the job; don't refactor unrelated code.
- Show real command output when something fails. Never claim something works without running it.
- Keep explanations short and plain.
