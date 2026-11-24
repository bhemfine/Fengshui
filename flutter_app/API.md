# Inkstone foundation API (for lib/screens/*)

Imports: `package:inkstone/widgets/widgets.dart`, `package:inkstone/theme/colors.dart`, `package:inkstone/theme/typography.dart`, `package:inkstone/motion/motion.dart`, `package:inkstone/data/sample_data.dart`, `package:inkstone/router.dart` (Routes), `package:go_router/go_router.dart` (context.go/push/pop).

## Routing (lib/router.dart)
- `Routes.welcome|birth|today|monthly|yearly|floorUpload|floorResult|houseCheck|readings|tarot|palm|bazi|compatibility|shop|masters|masterProfile|bookingPending|bookingConfirm|prescription|profile|paywall` (String paths).
- `appRouter` (GoRouter, initial `/welcome`). Shell branches: 0 Today(today, monthly, yearly) · 1 Home(floor-upload, floor-result, house-check, shop) · 2 Readings(readings, tarot, palm, bazi, compatibility) · 3 Masters(masters, master-profile, booking-pending, booking-confirm, prescription) · 4 Me(profile, paywall).
- `InkShell({required StatefulNavigationShell navigationShell})`.
- Screens expected: `const XScreen()` in `lib/screens/<name>_screen.dart`.

## Theme
- `AppColors.ink, ink2, lacquer, panel, gold, gold2, goldDeep, goldHi, goldDim, silver, ivory, ivory2, ox, ox2, good, care, primaryTop, primaryBottom, cardFill, field, navFill, scrim, hairline`.
- `InkText.display({double size=22, FontWeight weight=w600, Color color=goldHi, double? height=1.15, double? letterSpacing=0.4})`
- `InkText.body({double size=16, FontWeight weight=w400, Color color=ivory, double? height=1.45, double? letterSpacing})`
- getters: `hero, h1, h2, topBar, section, bodyLg, small, caption, button, tab, score`; `InkText.textTheme()`.
- `ThemeData buildInkTheme()`.

## Motion
- `Motion.screenEnter, countUp, floorScan, tarotShuffle, tarotSettle, tarotFlip, palmScan, burst, sheet, snack, glint, pulse, shimmer, ringSlow, ringRotate, orbit1, orbit2, orbit3` (Duration); curves `Motion.settle, Motion.count, Motion.flip`.
- `bool reduceMotion(BuildContext context)`.

## Widgets
- `InkstoneScaffold({String? title, bool showBack=false, bool example=false, List<Widget> actions=const [], required List<Widget> children, Widget? stickyCta, String? stickyNote, ScrollController? controller, EdgeInsetsGeometry padding=EdgeInsets.fromLTRB(20,8,20,28), String fallbackRoute='/today', Widget? overlay})`
- `InkIconButton({required IconData icon, required VoidCallback? onTap, String? semanticLabel})`
- `void showInkSnack(BuildContext context, String text)` (clears previous; 2.6s).
- `MidnightButton({required String label, VoidCallback? onPressed, IconData? icon, bool pulse=false, bool expand=true})`
- `GhostButton({required String label, VoidCallback? onPressed, IconData? icon, bool expand=true})`
- `LinkButton({required String label, VoidCallback? onPressed, Color color=AppColors.gold2, bool center=true})`
- `ButtonRow({required Widget first, required Widget second})`
- `InkstoneCard({required Widget child, String? title, bool example=false, String? source, VoidCallback? onTap, EdgeInsetsGeometry padding, EdgeInsetsGeometry margin=EdgeInsets.only(top:12), Color? borderColor})`
- `SectionHeader({required String title, bool example=false, String? source, Widget? trailing, EdgeInsetsGeometry padding})`
- `ScreenTitle({required String title, bool example=false, String? subtitle, bool center=false, double size=30})`
- `Term({required String english, required String chinese, String? meaning, TextStyle? style, TextAlign? textAlign})`
- `ExampleBadge({String label='Example'})`; `SourceBadge({required String label})` with `SourceBadge.calculated|photo|masterTan`; `InkChip({required String label, bool selected=false, VoidCallback? onTap})`
- `AlmanacList({required List<String> goodFor, required List<String> avoid})`
- `DoubleHourStrip({List<DoubleHour> hours=sampleDoubleHours, int currentIndex=3})`
- `ScoreRing({required int value, double size=96, Color color=AppColors.good, int max=100})`
- `ScoreBar({required int value, Color color=AppColors.good, int max=100, bool showNumber=true})`
- `CustomTransitionPage<void> fadeRisePage({required GoRouterState state, required Widget child})`
- `TarotDeck({TarotDeckController? controller, List<TarotCardData> cards=sampleTarotCards, ValueChanged<TarotDraw>? onDrawn, ValueChanged<TarotPhase>? onPhaseChanged, double height=280})`; `TarotDeckController()` → `.shuffle()`, `.reset()`, `.phase`; `enum TarotPhase {idle, shuffling, arc, flipping, revealed}`; `TarotDraw({card, reversed})`.
- `HdbScan({HdbScanController? controller, List<Palace> palaces=samplePalaces, double facingDegrees=142, String? facingLabel='142° SE', int? selected, ValueChanged<int>? onZoneTap, VoidCallback? onScanComplete, bool autoplay=true})`; `HdbScanController()` → `.scan()`; `hdbZoneRects` (List<Rect>, 9).
- `StarBurst({Alignment origin=Alignment(0,-0.5), bool play=true})` (IgnorePointer, one-shot).
- `StickyCta({required Widget child, String? note})`
- `InkBottomNav({required int currentIndex, required ValueChanged<int> onTap})`
- `Starfield({int starCount=120})` (already in app builder).

## Sample data (lib/data/sample_data.dart) — all Example
- Classes: `Person{name,birthLabel,place,gender,kua?,birthTimeKnown}`, `HomeInfo{type,town,address,facingDegrees,facingLabel,period,completed}`, `DoubleHour{english,chinese,meaning,range,isGood}`, `Almanac{goodFor,avoid}`, `Master{name,glyph,specialities,languages,rating,price,verified,tappable}`, `ShopItem{name,category,note,price,glyph}`, `TarotCardData{name,meaning,reversedMeaning?}`, `Palace{direction,mountain,water,tip}`, `PlacementTip{room,text,good}`, `Pillar{label,stem,branch,element,isSelf}`, `LuckPillar{age,chinese,current}`, `Booking{dateLabel,timeLabel,duration,price,master}`, `PrescriptionStep{title,detail}`.
- Values: `meiLin`, `weiHao`, `sampleHome`, `todayWeekday`, `todayDay`, `todayMonthYear`, `todayLunar`, `todayLucky`, `sampleAlmanac`, `sampleDoubleHours`, `sampleCurrentHourIndex`, `monthGoodDays`, `monthCareDays`, `monthLeadingBlanks`, `monthDays`, `monthOutlook` (List<(String,String)>), `yearMonths` (List<(String,String)>), `samplePalaces`, `samplePlacementTips`, `houseCheckScores` (List<(String,int,bool good)>), `compatibilityScore`, `sampleBaziPillars`, `sampleElementBalance` (List<(String,int)>), `sampleLuckPillars`, `kuaGoodDirections`, `kuaCareDirections`, `sampleMasters`, `sampleSlots`, `sampleBooking`, `samplePrescription`, `shopCategories`, `sampleShopItems`, `sampleTarotCards`.
