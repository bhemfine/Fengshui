import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/crash_log.dart';
import 'data/current_home.dart';
import 'data/household.dart';

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
  await bootstrapHousehold();
  runApp(const InkstoneApp());
}
