import 'package:flutter/services.dart';

/// Text shared to Inkstone from another app (Android "Share" → Inkstone),
/// e.g. a PropertyGuru, 99.co or HDB Flat Portal link. Handled in memory only.
class ShareIntent {
  static const _channel = MethodChannel('com.inkstone.app/share');

  /// Starts listening; [onText] gets the cold-start share and any later ones.
  static Future<void> listen(void Function(String text) onText) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText' && call.arguments is String) onText(call.arguments as String);
    });
    try {
      final first = await _channel.invokeMethod<String>('initialText');
      if (first != null && first.trim().isNotEmpty) onText(first);
    } on MissingPluginException {
      // Widget tests and non-Android hosts.
    } on PlatformException {
      // Ignore.
    }
  }
}
