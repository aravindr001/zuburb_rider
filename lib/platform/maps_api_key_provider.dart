import 'package:flutter/services.dart';

class MapsApiKeyProvider {
  static const MethodChannel _channel = MethodChannel('zuburb_rider/maps');

  const MapsApiKeyProvider._();

  static Future<String?> getApiKey() async {
    try {
      final key = await _channel.invokeMethod<String>('getApiKey');
      if (key == null || key.trim().isEmpty) return null;
      return key.trim();
    } catch (_) {
      return null;
    }
  }
}
