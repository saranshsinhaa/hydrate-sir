@AGENTS.md

## Claude Code specifics

- `.claude/settings.json` blocks installs and git/GitHub write commands. Don't try to work around it.
- Never commit, push, tag or change git state. When a change is ready, end with a suggested one-line Conventional Commit message for the human to use.
- Never add attribution (`Co-Authored-By`, "Generated with Claude Code") to commit messages, PR text or files.
- For live testing, run `flutter run` in the background and hot reload. Use `adb logcat` and `adb shell dumpsys alarm` to debug reminders.
- Use subagents only for wide searches or independent checks, not for small edits.
