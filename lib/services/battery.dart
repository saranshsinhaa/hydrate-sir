import 'package:flutter/services.dart';

/// Whether Android's battery saving may hold back reminders, and the way to
/// the settings page where the user can exempt the app.
class Battery {
  const Battery();

  static const _channel = MethodChannel('hydrate_sir/battery');

  /// True when the app is exempt from battery optimisation. Assumes so on
  /// platforms that can't say, so nobody is nagged without cause.
  Future<bool> isExempt() async {
    try {
      return await _channel.invokeMethod<bool>('isExempt') ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  /// Opens this app's page in Android settings.
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // Not on Android.
    }
  }
}
