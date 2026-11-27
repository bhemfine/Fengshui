import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkstone/data/crash_log.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('inkstone_crash_');
    CrashLogStore.debugDirectory = dir;
  });

  tearDown(() async {
    CrashLogStore.debugDirectory = null;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('records a crash without personal fields and keeps the last 20', () async {
    for (var i = 0; i < 22; i++) {
      await CrashLogStore.record(StateError('boom $i'), StackTrace.current, device: 'Pixel', os: 'Android 15');
    }
    final all = await CrashLogStore.load();
    expect(all.length, 20);
    expect(all.first.message, contains('boom 2'));
    expect(all.last.message, contains('boom 21'));
    final text = CrashLogStore.shareText(all);
    expect(text, contains('Inkstone crash report'));
    expect(text.toLowerCase(), isNot(contains('boon eng')));
    expect(text.toLowerCase(), isNot(contains('birth')));
    await CrashLogStore.clear();
    expect(await CrashLogStore.load(), isEmpty);
  });
}
