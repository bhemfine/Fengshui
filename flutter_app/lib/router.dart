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
}

GoRoute _r(String path, Widget child) => GoRoute(
      path: path,
      pageBuilder: (context, state) => fadeRisePage(state: state, child: child),
    );

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.welcome,
  routes: [
    _r(Routes.welcome, const WelcomeScreen()),
    _r(Routes.birth, const BirthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          InkShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          _r(Routes.today, const TodayScreen()),
          _r(Routes.monthly, const MonthlyScreen()),
          _r(Routes.yearly, const YearlyScreen()),
        ]),
        StatefulShellBranch(routes: [
          _r(Routes.floorUpload, const FloorUploadScreen()),
          _r(Routes.floorResult, const FloorResultScreen()),
          _r(Routes.houseCheck, const HouseCheckScreen()),
          _r(Routes.shop, const ShopScreen()),
          _r(Routes.quickCheck, const QuickCheckScreen()),
          GoRoute(
            path: Routes.quickCheckResult,
            pageBuilder: (context, state) => fadeRisePage(
              state: state,
              child: QuickCheckResultScreen(input: state.extra is QuickCheckInput ? state.extra as QuickCheckInput : null),
            ),
          ),
          _r(Routes.directionCalculator, const DirectionCalculatorScreen()),
          _r(Routes.homeChecklist, const HomeChecklistScreen()),
        ]),
        StatefulShellBranch(routes: [
          _r(Routes.readings, const ReadingsScreen()),
          _r(Routes.tarot, const TarotScreen()),
          _r(Routes.palm, const PalmScreen()),
          _r(Routes.bazi, const BaziScreen()),
          _r(Routes.compatibility, const CompatibilityScreen()),
        ]),
        StatefulShellBranch(routes: [
          _r(Routes.masters, const MastersScreen()),
          _r(Routes.masterProfile, const MasterProfileScreen()),
          _r(Routes.bookingPending, const BookingPendingScreen()),
          _r(Routes.bookingConfirm, const BookingConfirmScreen()),
          _r(Routes.prescription, const PrescriptionScreen()),
        ]),
        StatefulShellBranch(routes: [
          _r(Routes.profile, const ProfileScreen()),
          _r(Routes.paywall, const PaywallScreen()),
        ]),
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
          navigationShell.goBranch(i,
              initialLocation: i == navigationShell.currentIndex);
        },
      ),
    );
  }
}
