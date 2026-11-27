import 'crash_log.dart';
import 'current_home.dart';
import 'home_plan_store.dart';
import 'local_store.dart';
import 'notifications.dart';

/// Clears everything this build stores on the phone and resets the example home.
Future<void> deleteAllUserData() async {
  await DailyNotifications.cancel();
  await HomePlanStore.remove();
  await CrashLogStore.clear();
  await LocalStore.instance.clearAll();
  currentHome.value = exampleHome;
}
