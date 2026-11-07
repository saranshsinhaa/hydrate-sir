# Running it yourself

A short guide for building Hydrate, Sir on your own computer. You need no Android Studio and no emulator, just a phone and a cable.

## What to install

- [Flutter](https://docs.flutter.dev/get-started/install) **3.47.9** (the version is pinned in `pubspec.yaml`)
- **JDK 17**
- The [Android command-line tools](https://developer.android.com/studio#command-line-tools-only), with `ANDROID_HOME` set and `$ANDROID_HOME/platform-tools` on your `PATH`

On a Mac with Homebrew:

```bash
brew install --cask temurin@17 android-commandlinetools flutter
sdkmanager "platform-tools" "platforms;android-37.0" "build-tools;36.0.0"
yes | sdkmanager --licenses
```

## First run

```bash
git clone https://github.com/saranshsinhaa/hydrate-sir.git
cd hydrate-sir
scripts/setup.sh     # checks your tools, fetches packages, turns on the git hooks
flutter run          # with your phone plugged in and USB debugging on
```

## Checks

```bash
scripts/check.sh format analyze test   # what runs before each commit
scripts/check.sh all                   # adds a release build and the permission check (CI runs this)
```

## Screenshots

The README pictures are drawn from the real screens with made-up data:

```bash
flutter test tool/screenshots --update-goldens
```

## Further reading

- [design.md](design.md): the look, the voice and the rules behind them
- [AGENTS.md](../AGENTS.md): house rules for contributors and coding assistants
