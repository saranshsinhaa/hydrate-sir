import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/updates.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateCurrent extends UpdateState {
  const UpdateCurrent(this.version);
  final String version;
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.release, {required this.installed});
  final ReleaseInfo release;
  final String installed;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.release, this.progress);
  final ReleaseInfo release;
  final double progress;
}

/// Android must allow "install unknown apps" first.
class UpdateNeedsPermission extends UpdateState {
  const UpdateNeedsPermission(this.release);
  final ReleaseInfo release;
}

/// Handed to Android's installer; the user confirms there.
class UpdateInstalling extends UpdateState {
  const UpdateInstalling(this.release);
  final ReleaseInfo release;
}

enum UpdateFailure { offline, checksum }

class UpdateFailed extends UpdateState {
  const UpdateFailed(this.reason, {this.release});
  final UpdateFailure reason;
  final ReleaseInfo? release;
}

/// Checks GitHub for a new edition, downloads it and hands it to Android.
class UpdateController extends Notifier<UpdateState> {
  static const _lastCheckKey = 'updates.lastCheck';
  static const _dismissedKey = 'updates.dismissed';
  static const daily = Duration(hours: 24);

  @override
  UpdateState build() => const UpdateIdle();

  UpdateService get _service => ref.read(updateServiceProvider);

  /// Asks GitHub once a day, if the user allows it. Quiet on failure.
  Future<void> autoCheck() async {
    if (!ref.read(profileProvider).lookForUpdates) return;
    if (state is! UpdateIdle) return;
    final prefs = ref.read(sharedPrefsProvider);
    final last = prefs.getInt(_lastCheckKey);
    final now = ref.read(clockProvider)();
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < daily) {
      return;
    }
    await check(quiet: true);
  }

  Future<void> check({bool quiet = false}) async {
    state = const UpdateChecking();
    try {
      final installed = await _service.installed();
      final latest = await _service.latest();
      await ref
          .read(sharedPrefsProvider)
          .setInt(
            _lastCheckKey,
            ref.read(clockProvider)().millisecondsSinceEpoch,
          );
      state =
          latest != null && compareVersions(latest.version, installed.name) > 0
          ? UpdateAvailable(latest, installed: installed.name)
          : UpdateCurrent(installed.name);
    } catch (_) {
      state = quiet
          ? const UpdateIdle()
          : const UpdateFailed(UpdateFailure.offline);
    }
  }

  /// Downloads, verifies and installs the edition on offer.
  Future<void> fetch() async {
    final release = switch (state) {
      UpdateAvailable(:final release) => release,
      UpdateNeedsPermission(:final release) => release,
      UpdateFailed(:final release?) => release,
      _ => null,
    };
    if (release == null) return;
    if (!await _service.canInstall()) {
      state = UpdateNeedsPermission(release);
      await _service.openInstallSettings();
      return;
    }
    state = UpdateDownloading(release, 0);
    try {
      final sha = release.checksumUrl == null
          ? null
          : await _service.checksum(release.checksumUrl!);
      final path = await _service.download(release, (p) {
        state = UpdateDownloading(release, p);
      });
      await _service.install(path, sha256: sha);
      state = UpdateInstalling(release);
    } on Exception catch (e) {
      final checksum = e.toString().contains('checksum');
      state = UpdateFailed(
        checksum ? UpdateFailure.checksum : UpdateFailure.offline,
        release: release,
      );
    }
  }

  /// "Later": don't mention this edition on Today again.
  Future<void> dismiss() async {
    final s = state;
    if (s is UpdateAvailable) {
      await ref
          .read(sharedPrefsProvider)
          .setString(_dismissedKey, s.release.version);
    }
    ref.invalidateSelf();
  }

  /// Whether Today should mention the edition on offer.
  bool get announce {
    final s = state;
    if (s is! UpdateAvailable) return state is UpdateDownloading;
    return ref.read(sharedPrefsProvider).getString(_dismissedKey) !=
        s.release.version;
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
