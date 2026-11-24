import 'package:flutter/material.dart';

/// Exact tokens from DESIGN §3 / §9.1. Do not brighten the gold.
abstract final class AppColors {
  static const ink = Color(0xFF0B1026);
  static const ink2 = Color(0xFF121A3A);
  static const lacquer = Color(0xFF161E42);
  static const panel = Color(0xFF141B3C);
  static const gold = Color(0xFFBFA577);
  static const gold2 = Color(0xFFE3D6B8);
  static const goldDeep = Color(0xFF8A7350);
  static const goldHi = Color(0xFFEFE6D2);

  /// rgba(191,165,119,.36)
  static const goldDim = Color(0x5CBFA577);
  static const silver = Color(0xFFE4E6EC);
  static const ivory = Color(0xFFF4EFE4);
  static const ivory2 = Color(0xFFD8D2C4);
  static const ox = Color(0xFF8E2A22);
  static const ox2 = Color(0xFFA8362C);
  static const good = Color(0xFF9FD3A8);
  static const care = Color(0xFFEFB894);

  // Derived helpers from the prototype.
  static const primaryTop = Color(0xFF1D2552);
  static const primaryBottom = Color(0xFF151C40);
  static const cardFill = Color(0xF0121836); // rgba(18,24,54,.94)
  static const field = Color(0xFF0E1430);
  static const navFill = Color(0xF7090D20); // rgba(9,13,32,.97)
  static const scrim = Color(0x99050814); // rgba(5,8,20,.6)
  static const hairline = Color(0x2EBFA577); // rgba(191,165,119,.18)
}
