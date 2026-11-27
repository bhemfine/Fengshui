import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Local crash records. No names, birth dates, addresses or floor plans.
/// Kept in the app's private folder (Android backup is off).
class CrashRecord {
  const CrashRecord({
    required this.at,
    required this.message,
    required this.stack,
    required this.appVersion,
    this.device,
    this.os,
  });
  final DateTime at;
  final String message;
  final String stack;
  final String appVersion;
  final String? device;
  final String? os;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'message': message,
        'stack': stack,
        'appVersion': appVersion,
        'device': device,
        'os': os,
      };

  factory CrashRecord.fromJson(Map<String, Object?> m) => CrashRecord(
        at: DateTime.tryParse('${m['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        message: '${m['message'] ?? ''}',
        stack: '${m['stack'] ?? ''}',
        appVersion: '${m['appVersion'] ?? ''}',
        device: m['device'] as String?,
        os: m['os'] as String?,
      );

  String get asShareText =>
      'Inkstone crash report (no personal data)\n'
      'Time: ${at.toIso8601String()}\n'
      'App: $appVersion\n'
      'Device: ${device ?? 'unknown'}\n'
      'OS: ${os ?? 'unknown'}\n'
      'Error: $message\n'
      '$stack';
}

class CrashLogStore {
  CrashLogStore._();
  static const _fileName = 'crash_log.json';
  static const _keep = 20;
  static const appVersion = '0.1.0+1';
  static Directory? debugDirectory;

  static Future<File?> _file() async {
    try {
      final dir = debugDirectory ?? await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (_) {
      return null; // Tests or a missing plugin.
    }
  }

  static Future<List<CrashRecord>> load() async {
    final f = await _file();
    if (f == null || !f.existsSync()) return const [];
    try {
      final raw = jsonDecode(f.readAsStringSync()) as List;
      return [for (final x in raw) CrashRecord.fromJson(x as Map<String, Object?>)];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> record(Object error, StackTrace stack, {String? device, String? os}) async {
    await recordFlutter(FlutterErrorDetails(exception: error, stack: stack), device: device, os: os);
  }

  static Future<void> recordFlutter(FlutterErrorDetails details, {String? device, String? os}) async {
    final rec = CrashRecord(
      at: DateTime.now().toUtc(),
      message: details.exceptionAsString(),
      stack: (details.stack ?? StackTrace.empty).toString(),
      appVersion: appVersion,
      device: device,
      os: os,
    );
    try {
      final all = [...await load(), rec];
      final kept = all.length <= _keep ? all : all.sublist(all.length - _keep);
      final f = await _file();
      if (f == null) return;
      f.writeAsStringSync(jsonEncode([for (final r in kept) r.toJson()]), flush: true);
    } catch (_) {
      // Never throw from a crash hook.
    }
  }

  static Future<void> clear() async {
    try {
      final f = await _file();
      if (f != null && f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  static String shareText(List<CrashRecord> records) {
    if (records.isEmpty) return 'Inkstone: no crash reports are stored on this phone.';
    return records.reversed.map((r) => r.asShareText).join('\n---\n');
  }
}
