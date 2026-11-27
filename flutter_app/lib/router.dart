import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/welcome_screen.dart';
import 'screens/birth_screen.dart';
import 'screens/today_screen.dart';
import 'screens/monthly_screen.dart';
import 'screens/yearly_screen.dart';
import 'screens/floor_upload_screen.dart';
import 'screens/floor_result_screen.dart';
import 'screens/house_check_screen.dart';
import 'screens/readings_screen.dart';
import 'screens/tarot_screen.dart';
import 'screens/palm_screen.dart';
import 'screens/bazi_screen.dart';
import 'screens/compatibility_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/masters_screen.dart';
import 'screens/master_profile_screen.dart';
import 'screens/booking_pending_screen.dart';
import 'screens/booking_confirm_screen.dart';
import 'screens/prescription_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/quick_check_screen.dart';
import 'screens/quick_check_result_screen.dart';
import 'screens/direction_calculator_screen.dart';
import 'screens/home_checklist_screen.dart';
import 'screens/map_bearing_screen.dart';
import 'screens/listing_import_screen.dart';
import 'screens/saved_homes_screen.dart';
import 'package:latlong2/latlong.dart';
import 'data/house_records.dart';
import 'data/onboarding.dart';
import 'data/quick_check.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/transitions.dart';

/// Route path constants.
abstract final class Routes {
  static const welcome = '/welcome';
  static const birth = '/birth';
  static const today = '/today';
  static const monthly = '/monthly';
  static const yearly = '/yearly';
  static const floorUpload = '/floor-upload';
  static const floorResult = '/floor-result';
  static const houseCheck = '/house-check';
  static const readings = '/readings';
  static const tarot = '/tarot';
  static const palm = '/palm';
  static const bazi = '/bazi';
  static const compatibility = '/compatibility';
  static const shop = '/shop';
  static const masters = '/masters';
  static const masterProfile = '/master-profile';
  static const bookingPending = '/booking-pending';
  static const bookingConfirm = '/booking-confirm';
  static const prescription = '/prescription';
  static const profile = '/profile';
  static const paywall = '/paywall';
  static const quickCheck = '/quick-check';
  static const quickCheckResult = '/quick-check-result';
  static const directionCalculator = '/direction-calculator';
  static const homeChecklist = '/home-checklist';
  static const mapBearing = '/map-bearing';
  static const listingImport = '/listing-import';
  static const savedHomes = '/saved-homes';
}

GoRoute _r(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (context, state) => fadeRisePage(state: state, child: child),
);

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.welcome,
  redirect: (context, state) {
    // The router is built at import time, before bootstrap, so we cannot
    // bake the start path in. After a finished first run, skip Welcome.
    // /birth stays reachable from Me ("Edit birth details").
    if (onboardingComplete && state.matchedLocation == Routes.welcome) {
      return Routes.today;
    }
    return null;
  },
  routes: [
    _r(Routes.welcome, const WelcomeScreen()),
    _r(Routes.birth, const BirthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          InkShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            _r(Routes.today, const TodayScreen()),
            _r(Routes.monthly, const MonthlyScreen()),
            _r(Routes.yearly, const YearlyScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _r(Routes.floorUpload, const FloorUploadScreen()),
            _r(Routes.floorResult, const FloorResultScreen()),
            _r(Routes.houseCheck, const HouseCheckScreen()),
            _r(Routes.shop, const ShopScreen()),
            GoRoute(
              path: Routes.quickCheck,
              pageBuilder: (context, state) => fadeRisePage(
                state: state,
                child: QuickCheckScreen(
                  prefill: state.extra is QuickCheckPrefill
                      ? state.extra as QuickCheckPrefill
                      : null,
                  draft: state.extra is HouseRecord
                      ? state.extra as HouseRecord
                      : null,
                ),
              ),
            ),
            GoRoute(
              path: Routes.quickCheckResult,
              pageBuilder: (context, state) => fadeRisePage(
                state: state,
                child: QuickCheckResultScreen(
                  input: state.extra is QuickCheckInput
                      ? state.extra as QuickCheckInput
                      : null,
                ),
              ),
            ),
            _r(Routes.directionCalculator, const DirectionCalculatorScreen()),
            _r(Routes.homeChecklist, const HomeChecklistScreen()),
            GoRoute(
              path: Routes.mapBearing,
              pageBuilder: (context, state) {
                final a = state.extra is MapBearingArgs
                    ? state.extra as MapBearingArgs
                    : null;
                return fadeRisePage(
                  state: state,
                  child: MapBearingScreen(
                    initialCenter: a?.lat != null && a?.lng != null
                        ? LatLng(a!.lat!, a.lng!)
                        : null,
                    initialQuery: a?.query,
                    facingHint: a?.facingHint,
                  ),
                );
              },
            ),
            GoRoute(
              path: Routes.listingImport,
              pageBuilder: (context, state) => fadeRisePage(
                state: state,
                child: ListingImportScreen(
                  args: state.extra is ListingImportArgs
                      ? state.extra as ListingImportArgs
                      : const ListingImportArgs(),
                ),
              ),
            ),
            _r(Routes.savedHomes, const SavedHomesScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _r(Routes.readings, const ReadingsScreen()),
            _r(Routes.tarot, const TarotScreen()),
            _r(Routes.palm, const PalmScreen()),
            _r(Routes.bazi, const BaziScreen()),
            _r(Routes.compatibility, const CompatibilityScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _r(Routes.masters, const MastersScreen()),
            _r(Routes.masterProfile, const MasterProfileScreen()),
            _r(Routes.bookingPending, const BookingPendingScreen()),
            _r(Routes.bookingConfirm, const BookingConfirmScreen()),
            _r(Routes.prescription, const PrescriptionScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _r(Routes.profile, const ProfileScreen()),
            _r(Routes.paywall, const PaywallScreen()),
          ],
        ),
      ],
    ),
  ],
);

/// Tab shell: transparent so the starfield shows, custom bottom nav.
class InkShell extends StatelessWidget {
  const InkShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: InkBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
