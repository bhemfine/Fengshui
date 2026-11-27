import 'crash_log.dart';
import 'current_home.dart';
import 'house_records.dart';
import 'household.dart';
import 'home_plan_store.dart';
import 'local_store.dart';
import 'notifications.dart';
import 'onboarding.dart';

/// Clears everything this build stores on the phone and resets the example home.
Future<void> deleteAllUserData() async {
  await DailyNotifications.cancel();
  await HomePlanStore.remove();
  await CrashLogStore.clear();
  await LocalStore.instance.clearAll();
  currentHome.value = exampleHome;
  resetHouseholdDefaults();
  resetHouseRecords();
  // Do not send the user back through welcome/birth after a wipe.
  await restoreOnboardingComplete();
}
