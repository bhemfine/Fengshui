import 'household.dart';
import 'local_store.dart';

/// Set once the user has left the first-run welcome/birth flow.
/// Loaded in [bootstrapOnboarding] before the app is shown.
const onboardingKey = 'onboarding.complete.v1';

bool onboardingComplete = false;

Future<void> bootstrapOnboarding() async {
  final saved = await LocalStore.instance.loadBool(onboardingKey);
  if (saved == true) {
    onboardingComplete = true;
    return;
  }
  // Upgrading from a build that already saved a household: do not ask again.
  final householdRaw = await LocalStore.instance.loadString(householdKey);
  if (householdRaw != null && householdRaw.isNotEmpty) {
    onboardingComplete = true;
    await LocalStore.instance.saveBool(onboardingKey, true);
    return;
  }
  onboardingComplete = false;
}

Future<void> markOnboardingComplete() async {
  onboardingComplete = true;
  await LocalStore.instance.saveBool(onboardingKey, true);
}

/// After "Delete my data" wipes prefs. Keep the user in the app so they are
/// not sent back to the birth form; profiles have already been reset.
Future<void> restoreOnboardingComplete() async {
  onboardingComplete = true;
  await LocalStore.instance.saveBool(onboardingKey, true);
}

void resetOnboardingForTest() {
  onboardingComplete = false;
}
