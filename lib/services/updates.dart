import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Where new editions are announced: this repository's latest GitHub release.
const updateFeed =
    'https://api.github.com/repos/saranshsinhaa/hydrate-sir/releases/latest';

/// The installed edition.
class AppVersion {
  const AppVersion(this.name, this.code);

  final String name;
  final int code;
}

/// A published edition, as described by the release feed.
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.apkUrl,
    required this.sizeBytes,
    this.checksumUrl,
    this.notes = '',
  });

  final String version;
  final Uri apkUrl;
  final int sizeBytes;
  final Uri? checksumUrl;
  final String notes;
}

/// Compares "1.2.0" with "v1.10.0" and the like. A pre-release ("1.2.0-beta")
/// sorts before its release. Returns <0, 0 or >0.
int compareVersions(String a, String b) {
  (List<int>, String) parse(String v) {
    final s = v.trim().replaceFirst(RegExp('^[vV]'), '');
    final dash = s.indexOf('-');
    final core = dash < 0 ? s : s.substring(0, dash);
    final pre = dash < 0 ? '' : s.substring(dash + 1);
    final nums = core
        .split('.')
        .map((p) => int.tryParse(p.split('+').first) ?? 0)
        .toList();
    while (nums.length < 3) {
      nums.add(0);
    }
    return (nums, pre);
  }

  final (an, ap) = parse(a);
  final (bn, bp) = parse(b);
  for (var i = 0; i < 3; i++) {
    if (an[i] != bn[i]) return an[i].compareTo(bn[i]);
  }
  if (ap == bp) return 0;
  if (ap.isEmpty) return 1;
  if (bp.isEmpty) return -1;
  return ap.compareTo(bp);
}

/// Reads GitHub's "latest release" JSON. Returns null when it holds no APK.
ReleaseInfo? parseRelease(Map<String, Object?> json) {
  if (json['draft'] == true || json['prerelease'] == true) return null;
  final tag = json['tag_name'];
  final assets = json['assets'];
  if (tag is! String || assets is! List) return null;
  Map<String, Object?>? apk;
  Map<String, Object?>? sum;
  for (final a in assets.whereType<Map<String, Object?>>()) {
    final name = a['name'];
    if (name is! String) continue;
    if (name.endsWith('.apk')) apk = a;
    if (name.endsWith('.apk.sha256')) sum = a;
  }
  final url = apk?['browser_download_url'];
  if (url is! String) return null;
  final sumUrl = sum?['browser_download_url'];
  final body = json['body'];
  return ReleaseInfo(
    version: tag.replaceFirst(RegExp('^[vV]'), ''),
    apkUrl: Uri.parse(url),
    sizeBytes: apk?['size'] is int ? apk!['size']! as int : 0,
    checksumUrl: sumUrl is String ? Uri.parse(sumUrl) : null,
    notes: body is String ? body : '',
  );
}

/// Talks to the release feed and to Android's installer. Nothing about the
/// user is sent; these are plain GET requests.
class UpdateService {
  UpdateService({this.feed = updateFeed});

  final String feed;
  static const _channel = MethodChannel('hydrate_sir/updates');

  HttpClient _client() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'hydrate-sir-updater';

  Future<AppVersion> installed() async {
    final m = await _channel.invokeMapMethod<String, Object?>('appVersion');
    return AppVersion(
      (m?['name'] as String?) ?? '0.0.0',
      (m?['code'] as int?) ?? 0,
    );
  }

  /// The newest published edition, or null if there is none yet.
  Future<ReleaseInfo?> latest() async {
    final client = _client();
    try {
      final req = await client.getUrl(Uri.parse(feed));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode == HttpStatus.notFound) {
        await res.drain<void>();
        return null;
      }
      if (res.statusCode != HttpStatus.ok) {
        await res.drain<void>();
        throw HttpException('Release feed answered ${res.statusCode}');
      }
      final text = await res.transform(utf8.decoder).join();
      return parseRelease(jsonDecode(text) as Map<String, Object?>);
    } finally {
      client.close();
    }
  }

  /// The SHA-256 published beside the APK, as `hash  filename`.
  Future<String?> checksum(Uri url) async {
    final client = _client();
    try {
      final res = await (await client.getUrl(url)).close();
      if (res.statusCode != HttpStatus.ok) {
        await res.drain<void>();
        return null;
      }
      final text = await res.transform(utf8.decoder).join();
      final hash = text.trim().split(RegExp(r'\s+')).first.toLowerCase();
      return RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ? hash : null;
    } finally {
      client.close();
    }
  }

  /// Downloads the APK into the app's private cache, reporting 0..1.
  Future<String> download(
    ReleaseInfo release,
    void Function(double progress) onProgress,
  ) async {
    final dir = await _channel.invokeMethod<String>('downloadDir');
    final file = File('$dir/hydrate-sir-${release.version}.apk');
    final client = _client();
    try {
      final res = await (await client.getUrl(release.apkUrl)).close();
      if (res.statusCode != HttpStatus.ok) {
        await res.drain<void>();
        throw HttpException('Download answered ${res.statusCode}');
      }
      final total = res.contentLength > 0
          ? res.contentLength
          : release.sizeBytes;
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress((received / total).clamp(0, 1));
        }
      } finally {
        await sink.close();
      }
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Whether Android lets this app install updates.
  Future<bool> canInstall() async =>
      await _channel.invokeMethod<bool>('canInstall') ?? false;

  Future<void> openInstallSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');

  /// Verifies the checksum, then hands the APK to Android's installer.
  Future<void> install(String path, {String? sha256}) =>
      _channel.invokeMethod<void>('install', {'path': path, 'sha256': sha256});
}
