import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/app/providers.dart';
import 'package:hydrate_sir/features/updates/update_controller.dart';
import 'package:hydrate_sir/services/updates.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

ReleaseInfo edition(String v) => ReleaseInfo(
  version: v,
  apkUrl: Uri.parse('https://example.test/$v.apk'),
  checksumUrl: Uri.parse('https://example.test/$v.apk.sha256'),
  sizeBytes: 100,
);

void main() {
  late FakeUpdateService service;
  late SharedPreferences prefs;
  var now = DateTime(2026, 11, 8, 9);

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        updateServiceProvider.overrideWithValue(service),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    service = FakeUpdateService();
    now = DateTime(2026, 11, 8, 9);
  });

  test('a newer edition is offered', () async {
    service.published = edition('1.1.0');
    final c = await container();
    await c.read(updateControllerProvider.notifier).check();
    final s = c.read(updateControllerProvider);
    expect(s, isA<UpdateAvailable>());
    expect((s as UpdateAvailable).installed, '1.0.0');
    expect(c.read(updateControllerProvider.notifier).announce, isTrue);
  });

  test('the same or an older edition means all is current', () async {
    service.published = edition('1.0.0');
    final c = await container();
    await c.read(updateControllerProvider.notifier).check();
    expect(c.read(updateControllerProvider), isA<UpdateCurrent>());
  });

  test('no release yet is not an error', () async {
    final c = await container();
    await c.read(updateControllerProvider.notifier).check();
    expect(c.read(updateControllerProvider), isA<UpdateCurrent>());
  });

  test(
    'a failed enquiry is reported when asked, silent when automatic',
    () async {
      service.offline = true;
      final c = await container();
      final n = c.read(updateControllerProvider.notifier);
      await n.check();
      expect(c.read(updateControllerProvider), isA<UpdateFailed>());
      c.invalidate(updateControllerProvider);
      await c.read(updateControllerProvider.notifier).autoCheck();
      expect(c.read(updateControllerProvider), isA<UpdateIdle>());
    },
  );

  test('automatic checks happen at most once a day', () async {
    service.published = edition('1.1.0');
    final c = await container();
    await c.read(updateControllerProvider.notifier).autoCheck();
    expect(service.checks, 1);
    c.invalidate(updateControllerProvider);
    now = now.add(const Duration(hours: 23));
    await c.read(updateControllerProvider.notifier).autoCheck();
    expect(service.checks, 1);
    c.invalidate(updateControllerProvider);
    now = now.add(const Duration(hours: 2));
    await c.read(updateControllerProvider.notifier).autoCheck();
    expect(service.checks, 2);
  });

  test('no automatic checks when the user turned them off', () async {
    final c = await container();
    await prefs.setString('profile.v1', '{"lookForUpdates": false}');
    c.invalidate(profileProvider);
    await c.read(updateControllerProvider.notifier).autoCheck();
    expect(service.checks, 0);
  });

  test('without install permission, Android settings are opened', () async {
    service.published = edition('1.1.0');
    service.mayInstall = false;
    final c = await container();
    final n = c.read(updateControllerProvider.notifier);
    await n.check();
    await n.fetch();
    expect(c.read(updateControllerProvider), isA<UpdateNeedsPermission>());
    expect(service.settingsOpened, 1);
    expect(service.installs, isEmpty);
  });

  test('fetch downloads, verifies and hands over to the installer', () async {
    service.published = edition('1.1.0');
    final c = await container();
    final n = c.read(updateControllerProvider.notifier);
    await n.check();
    await n.fetch();
    expect(c.read(updateControllerProvider), isA<UpdateInstalling>());
    expect(service.installs, [('/cache/1.1.0.apk', 'a' * 64)]);
  });

  test('a damaged download is reported and can be retried', () async {
    service.published = edition('1.1.0');
    service.badChecksum = true;
    final c = await container();
    final n = c.read(updateControllerProvider.notifier);
    await n.check();
    await n.fetch();
    final s = c.read(updateControllerProvider);
    expect(s, isA<UpdateFailed>());
    expect((s as UpdateFailed).reason, UpdateFailure.checksum);
    service.badChecksum = false;
    await n.fetch();
    expect(c.read(updateControllerProvider), isA<UpdateInstalling>());
  });

  test('"later" stops Today mentioning that edition', () async {
    service.published = edition('1.1.0');
    final c = await container();
    await c.read(updateControllerProvider.notifier).check();
    await c.read(updateControllerProvider.notifier).dismiss();
    await c.read(updateControllerProvider.notifier).check();
    expect(c.read(updateControllerProvider.notifier).announce, isFalse);
  });
}
