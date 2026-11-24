import 'package:flutter/widgets.dart';

/// Motion tokens (DESIGN §7.2).
abstract final class Motion {
  static const screenEnter = Duration(milliseconds: 220);
  static const countUp = Duration(milliseconds: 480);
  static const floorScan = Duration(milliseconds: 2500);
  static const tarotShuffle = Duration(milliseconds: 1900);
  static const tarotSettle = Duration(milliseconds: 500);
  static const tarotFlip = Duration(milliseconds: 1100);
  static const palmScan = Duration(milliseconds: 1100);
  static const burst = Duration(milliseconds: 900);
  static const sheet = Duration(milliseconds: 250);
  static const snack = Duration(milliseconds: 2600);
  static const glint = Duration(seconds: 11);
  static const pulse = Duration(milliseconds: 3600);
  static const shimmer = Duration(milliseconds: 4500);
  static const ringSlow = Duration(seconds: 60);
  static const ringRotate = Duration(seconds: 40);
  static const orbit1 = Duration(seconds: 20);
  static const orbit2 = Duration(seconds: 30);
  static const orbit3 = Duration(seconds: 40);

  /// cubic-bezier(.2,.8,.2,1)
  static const Curve settle = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve count = Curves.easeOut;

  /// cubic-bezier(.4,.1,.2,1)
  static const Curve flip = Cubic(0.4, 0.1, 0.2, 1);
}

/// True when the OS asks for reduced motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
