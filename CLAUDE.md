@AGENTS.md

## Claude Code specifics

- `.claude/settings.json` blocks installs, pushes and destructive git/GitHub commands. Don't try to work around it.
- Commit locally in small steps with `git commit -m "<one-line conventional message>"`. Never push, tag, amend or rewrite history.
- Never add attribution (`Co-Authored-By`, "Generated with Claude Code") to commit messages, PR text or files.
- For live testing, run `flutter run` in the background and hot reload. Use `adb logcat` and `adb shell dumpsys alarm` to debug reminders.
- Use subagents only for wide searches or independent checks, not for small edits.
