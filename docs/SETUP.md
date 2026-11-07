# Local setup

This sets up the smallest toolchain that builds the app and runs it on a real Android phone. You don't need Android Studio or an emulator.

## Versions

| Tool | Version |
|---|---|
| Flutter | 3.47.9 (pinned in `pubspec.yaml`) |
| JDK | 17 (Temurin) |
| Android SDK platform | 36 |
| Android build-tools | 36.0.0 |

## 1. Install the tools

### macOS (Homebrew)

```bash
brew install --cask temurin@17 android-commandlinetools flutter
```

Add to `~/.zshrc`, then open a new terminal:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

### Linux / Windows

Install [Flutter](https://docs.flutter.dev/get-started/install), a JDK 17 and the [Android command-line tools](https://developer.android.com/studio#command-line-tools-only). Set `JAVA_HOME` and `ANDROID_HOME`, and add `$ANDROID_HOME/platform-tools` to `PATH`.

## 2. Install the Android SDK parts

```bash
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
yes | sdkmanager --licenses
```

## 3. Point Flutter at them

```bash
flutter config --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME" --no-enable-web --no-enable-ios --no-enable-macos-desktop
flutter doctor
```

`Flutter` and `Android toolchain` should be green. Warnings about Xcode, Chrome or Android Studio can be ignored.

## 4. Prepare the repo

```bash
git clone https://github.com/saranshsinhaa/hydrate-sir.git
cd hydrate-sir
scripts/setup.sh
```

`scripts/setup.sh` checks your tools (it installs nothing), fetches packages and turns on the git hooks in `.githooks/`.

## 5. Connect your phone

1. Settings › About phone › tap **Build number** seven times.
2. Settings › Developer options › turn on **USB debugging**.
3. Plug in with a data cable and tap **Allow** on the phone.
4. `adb devices` should list it as `device`.

## 6. Run

```bash
flutter run
```

Press `r` to hot reload and `R` to restart.

## Checks

```bash
scripts/check.sh format analyze test   # what the pre-commit hook runs
scripts/check.sh all                   # adds a release build and the offline check (pre-push and CI)
flutter test integration_test          # end-to-end tests, needs a connected phone
```
