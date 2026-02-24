import 'package:flutter/services.dart';

class MapsApiKeyProvider {
  static const MethodChannel _channel = MethodChannel('zuburb_rider/maps');

  const MapsApiKeyProvider._();

  /// Returns the API key.
  /// Priority: --dart-define > native AndroidManifest / Info.plist.
  static Future<String?> getApiKey() async {
    // 1. Check --dart-define passed at build time.
    const dartDefineKey = String.fromEnvironment('MAPS_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;

    // 2. Fall back to native platform channel.
    try {
      final key = await _channel.invokeMethod<String>('getApiKey');
      if (key == null || key.trim().isEmpty) return null;
      return key.trim();
    } catch (_) {
      return null;
    }
  }
}
