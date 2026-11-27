import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/crash_log.dart';
import 'data/current_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(CrashLogStore.recordFlutter(details));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(CrashLogStore.record(error, stack));
    return true;
  };
  await bootstrapCurrentHome();
  runApp(const InkstoneApp());
}
