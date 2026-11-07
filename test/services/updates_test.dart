import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/services/updates.dart';

void main() {
  group('compareVersions', () {
    test('orders by major, minor, patch numerically', () {
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.2.3', '1.2.3'), 0);
    });

    test('ignores a leading v and build numbers', () {
      expect(compareVersions('v1.2.0', '1.2.0'), 0);
      expect(compareVersions('1.2.0+7', '1.2.0'), 0);
      expect(compareVersions('1.2', '1.2.0'), 0);
    });

    test('a pre-release comes before its release', () {
      expect(compareVersions('1.1.0-beta.1', '1.1.0'), lessThan(0));
      expect(compareVersions('1.1.0', '1.1.0-beta.1'), greaterThan(0));
      expect(compareVersions('1.1.0-beta.2', '1.1.0-beta.1'), greaterThan(0));
    });
  });

  group('parseRelease', () {
    Map<String, Object?> release({
      bool prerelease = false,
      List<Map<String, Object?>>? assets,
    }) => {
      'tag_name': 'v1.1.0',
      'draft': false,
      'prerelease': prerelease,
      'body': 'Fixes and kindnesses.',
      'assets':
          assets ??
          [
            {
              'name': 'hydrate-sir-1.1.0.apk',
              'size': 45000000,
              'browser_download_url':
                  'https://example.test/hydrate-sir-1.1.0.apk',
            },
            {
              'name': 'hydrate-sir-1.1.0.apk.sha256',
              'size': 90,
              'browser_download_url':
                  'https://example.test/hydrate-sir-1.1.0.apk.sha256',
            },
          ],
    };

    test('reads the version, APK and checksum', () {
      final r = parseRelease(release())!;
      expect(r.version, '1.1.0');
      expect(r.apkUrl.path, '/hydrate-sir-1.1.0.apk');
      expect(r.checksumUrl!.path, '/hydrate-sir-1.1.0.apk.sha256');
      expect(r.sizeBytes, 45000000);
      expect(r.notes, 'Fixes and kindnesses.');
    });

    test('pre-releases are not offered', () {
      expect(parseRelease(release(prerelease: true)), isNull);
    });

    test('a release without an APK is not offered', () {
      expect(parseRelease(release(assets: [])), isNull);
    });
  });
}
