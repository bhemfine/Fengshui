import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// The home's floor plan, kept only in this app's private folder on the phone.
/// Android backup is off for the app, so it never leaves the phone.
class SavedPlan {
  const SavedPlan({required this.file, required this.source, required this.confirmed});
  final File file;

  /// "listing" (downloaded from a listing) or "upload" (picked by the user).
  final String source;

  /// The user confirmed this plan is their home's.
  final bool confirmed;
}

class HomePlanStore {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/home_plan');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  static Future<SavedPlan?> load() async {
    try {
      final d = await _dir();
      final meta = File('${d.path}/plan.json');
      if (!meta.existsSync()) return null;
      final m = jsonDecode(meta.readAsStringSync()) as Map<String, Object?>;
      final f = File('${d.path}/${m['file']}');
      if (!f.existsSync()) return null;
      return SavedPlan(file: f, source: '${m['source']}', confirmed: m['confirmed'] == true);
    } catch (_) {
      return null; // No plugin in tests, or nothing saved yet.
    }
  }

  static Future<SavedPlan> save(
    Uint8List bytes, {
    required String ext,
    required String source,
    bool confirmed = false,
  }) async {
    final d = await _dir();
    for (final f in d.listSync()) {
      f.deleteSync();
    }
    final name = 'plan.${ext.toLowerCase()}';
    final f = File('${d.path}/$name')..writeAsBytesSync(bytes, flush: true);
    File('${d.path}/plan.json').writeAsStringSync(jsonEncode({'file': name, 'source': source, 'confirmed': confirmed}));
    return SavedPlan(file: f, source: source, confirmed: confirmed);
  }

  static Future<void> confirm() async {
    final p = await load();
    if (p == null) return;
    final d = await _dir();
    File(
      '${d.path}/plan.json',
    ).writeAsStringSync(jsonEncode({'file': p.file.uri.pathSegments.last, 'source': p.source, 'confirmed': true}));
  }

  static Future<void> remove() async {
    try {
      final d = await _dir();
      if (d.existsSync()) d.deleteSync(recursive: true);
    } catch (_) {}
  }

  /// Downloads a plan image from a listing (on request only).
  static Future<SavedPlan> download(String url, {http.Client? client}) async {
    final c = client ?? http.Client();
    final r = await c
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Mobile Safari/537.36',
            'Accept': 'image/*',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200 || r.bodyBytes.length < 500) throw Exception('Download failed (${r.statusCode})');
    final type = r.headers['content-type'] ?? '';
    final ext = type.contains('png') ? 'png' : (type.contains('webp') ? 'webp' : 'jpg');
    return save(r.bodyBytes, ext: ext, source: 'listing');
  }
}
