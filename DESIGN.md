# DESIGN.md — Inkstone, Option B3 (softer gold astrolabe)

Clickable prototype for the Ultimate Feng Shui Android app. Working title **Inkstone** (open to change). This document describes the approved B3 visual system so **bhemfine** can match it in Flutter. Example data only — not a live reading.

## 1. Working name and product voice

- Name: Inkstone. The welcome seal uses the character 砚, always labelled “Inkstone”.
- Voice: calm, plain English, specific, never alarming. Short sentences. Do not invent prices or medical claims.
- Remedies and prescriptions are optional and “not medicine”. Masters do not auto-add items to a cart.
- Every sample chart, price, master and reading is marked **Example**. Source markers distinguish Calculated, Read from your photo, and From Master Tan.

## 2. Visual world

A midnight astrolabe: deep navy ink, thin champagne / antique gold instrument rings, ivory lettering, and a field of slowly twinkling stars. Gold is metal, not canary yellow — used sparingly as borders, ticks and quiet glints. Headings are ivory or pale champagne, never a loud gold fill. The primary button is midnight with a thin champagne edge, not a gold slab.

Astrolabe rings sit behind several screens and rotate slowly. A canvas starfield (`#sky`) twinkles continuously, with occasional cross flares and a rare shooting star.

## 3. Colour tokens

Use these exact values from the prototype.

### 3.1 Primitives

| Token | Hex / value | Role |
|---|---|---|
| `ink` | `#0b1026` | Page and phone fill |
| `ink2` | `#121a3a` | Elevated panels, sheet |
| `lacquer` | `#161e42` | Secondary panel |
| `panel` | `#141b3c` | Cards, dialog |
| `gold` | `#bfa577` | Antique / champagne gold (borders, ticks) |
| `gold2` | `#e3d6b8` | Lighter gold for labels and highlights |
| `goldDeep` | `#8a7350` | Recessed gold, bezel-adjacent |
| `goldHi` | `#efe6d2` | Pale champagne highlight, glint |
| `goldDim` | `rgba(191,165,119,.36)` | Hairline borders, chip outlines |
| `silver` | `#e4e6ec` | Cool star / silver-white accent |
| `ivory` | `#f4efe4` | Primary text and headings |
| `ivory2` | `#d8d2c4` | Secondary text |
| `ox` / `ox2` | `#8e2a22` / `#a8362c` | Rare alert / seal accent |
| `good` | `#9fd3a8` | Favourable, “Good fit”, “Good for” |
| `care` | `#efb894` | Take care, “Avoid” |

Phone bezel: `1.5px solid #8a7656`, plus a hairline `#2a2418` and a soft outer ring `rgba(191,165,119,.18)`.

### 3.2 Contrast and dark theme

This is a dark-only UI. Body text is ivory on midnight. Aim for WCAG AA for body copy (ivory on `#0b1026` is comfortable at 16px+). Do not set body text in gold; gold is for chrome. Do not place `--care` or `--good` at small sizes on mid-navy without checking contrast — use them for labels and icons, not long paragraphs.

### 3.3 Semantic roles

- Favourable: `--good` (mint), often with a filled dot.
- Take care: `--care` (warm apricot), often with a small triangle.
- Example badge: outlined champagne chip, ivory2 text.
- Source chip (“Calculated”): same family, slightly quieter.
- Snack: `--goldHi` background, `ink` text.

## 4. Typography

### 4.1 Families (Google Fonts)

- Display / titles: **Cormorant SC** (small caps serif), weights 500, 600, 700. Headings, day numerals, card names, BaZi stem-branch glyphs may also use this.
- Body: **Source Serif 4** (optical size 8–60), weights 400 and 600. All UI copy, buttons, tabs, form labels.
- Do **not** use Inter, Roboto, Arial, or a generic system sans as the UI face. A system serif fallback (`Georgia, serif`) is acceptable while fonts load.

### 4.2 Scale

Typical sizes in the prototype (logical pixels at 390-wide):

- Hero day number / welcome title: ~52–57px, display, weight 600
- Screen title (top bar): ~20–22px, display
- Section heading: ~17–18px, display or body 600
- Body / list: 16–17px, body 400, line-height ~1.45
- Secondary / captions: 13–15px, `ivory2`
- Tab labels: 12px, body 600
- Button: 17px, body 600
- Score numerals: ~34px, display 600

### 4.3 Rules

- Plain English first. Any Chinese term is followed in the same phrase by a translation, e.g. `Flying Stars (飞星 — energy in each area of the home)`, `Good for (宜)`, `Avoid (忌)`, `Tai Sui (太岁 — the year's ruling star)`, `Day Master (日主)`, `Kua number (卦 — your personal direction number)`, `Luck pillars (大运 — ten-year phases)`, `BaZi (八字 — four pillars of destiny)`.
- Double hours show the English name and the character, e.g. Mao (卯).
- Do not set long paragraphs in all small caps. Cormorant SC is for titles, not body.

## 5. Spacing, shape, elevation

- Phone canvas: 390 × 844, corner radius 40px.
- Horizontal padding of a screen: 20px.
- Cards: 16–18px radius, fill `#141b3c` / `#121a3a`, hairline `goldDim` border. No heavy drop shadows; a soft dark bloom is enough.
- Buttons: 14px radius, full width unless in a `.row`.
- Chips: pill (`border-radius: 999px`).
- Status bar area: 36px. Tab bar: 64px tall, sitting 22px above the bottom (home indicator).
- Screens with a tab bar have a 86px bottom inset so content is not hidden.
- Sticky `.foot` CTAs sit just above the tab bar (or the bottom safe area on welcome / birth, where the tab bar is hidden).

## 6. Components

### 6.1 Buttons

- **Primary**: midnight gradient `#1d2552 → #151c40`, ivory label, 1px champagne border, quiet 11s metallic glint (`::after` sweep). Subtle pulse (scale 1 → 1.015) when motion is allowed.
- **Secondary**: transparent / ink2 fill, champagne hairline, ivory2 label.
- **Text**: no fill, champagne or ivory2 label.
- **Icon**: 40px hit target, hairline optional.

### 6.2 Example badge and source marker

Small outlined pills. “Example” appears on every sample chart, price, master and reading. Source markers: Calculated, Read from your photo, From Master Tan.

### 6.3 Almanac (Good for / Avoid)

Two columns or stacked lists. Mint heading “Good for (宜)”, apricot “Avoid (忌)”. Short verb phrases (Sign papers, Cut hair).

### 6.4 Double-hour strip

Horizontal scroll of 12 earthly-branch cells. English name + character + time range. A mint “Good” dot on favourable hours. The current cell (Mao, 5–7, in the example) is outlined and scrolled into view.

### 6.5 Calendar

November 2026, Sunday start, 30 days. Mint dots on good days, apricot marks on take-care days, today (23) highlighted. Tapping a day opens the bottom sheet.

### 6.6 Bottom sheet, dialog, snack

Sheet slides up over a dim scrim (`rgba(5,8,20,.6)`). Dialog is a centred card for “Delete my data” (prototype copy: nothing is really stored). Snack is a goldHi bar above the tab bar, auto-dismiss ~2.6s, and must clear when the route changes.

### 6.7 Floor plan and compass

Reuse the Option B3 Home-check treatment: 4-room Tampines plan, champagne room lines, compass rings, a scan sweep, then Flying Stars (飞星) pairs in each palace. Tapping a square updates a tip. “Scan again” replays the scan. Primary actions “House check” and “Change plan” stay at the top so they are not below the fold.

### 6.8 Tarot card

Reuse the Option B3 single-card draw: seven stacked backs, a shuffle orbit (~1.9s), settle into an arc, tap one, the others fade, the chosen card flips, meaning appears, the button becomes “Shuffle again” and stays fully visible above the tab bar (`#tarot.drawn` hides the question field and tightens the table).

### 6.9 Scores

House check: one bar per person (Boon Eng, Victoria), scored by the engine from the facing's rank in each person's 8 directions, count-up 480ms. Compatibility: 76 in a mint ring (`#cring` stroke-dashoffset from 264). Instant values when reduced motion is on.

### 6.10 Master card and booking tracker

Avatar in a champagne ring, Verified mark, rating line, “From S$xx (example)”. Only Tan’s card is tappable in this prototype. Booking uses a three-step tracker: Requested → Accepted → Confirmed. Payment language is “authorised, not charged”.

### 6.11 Shop crystals

Each item has a small thumbnail with a sweeping shimmer (`thumb::after`). Buy is always optional and only snacks; there is no checkout.

### 6.12 Navigation

Five tabs: Today, Home, Readings, Masters, Me. Hidden on welcome and birth. Tab roots: today, floor-result, readings, masters, profile. Hash routing with back-stack behaviour. A desktop aside lists every screen for reviewers.

## 7. Motion

### 7.1 Principles

Motion is smooth, quiet, and meaningful — an instrument settling, not a carnival. Gold glints are slow (11s+). Prefer transform and opacity.

### 7.2 Tokens

| Moment | Duration | Notes |
|---|---|---|
| Screen enter | 220ms | Fade + slight rise |
| Count-up / bar fill | 480ms | Ease-out |
| Floor scan | ~2.5s | Compass settle, sweep, zones light in sequence |
| Tarot shuffle | ~1.9s | Orbit, then arc settle |
| Tarot flip | ~1.1s | 3D rotateY |
| Palm scan | ~1.1s | Scan bar, then line reveal |
| Booking burst | ~700–1000ms | 16–24 ivory/champagne particles, once |
| Starfield twinkle | continuous | Mixed periods, rare shooting star |
| Ring rotate / glint | 20–40s / 11–28s | Behind content |
| Year-chart orbits | 20s, 30s reverse, 40s | `.orb` groups |
| Primary pulse | slow, subtle | Disabled in reduced motion |

### 7.3 Reduced motion

Honour `prefers-reduced-motion: reduce`. Disable or snap: starfield shooting stars, ring rotations, glints, pulses, orbits, screen-enter, scan sweep, shuffle flight, palm scan, burst, count-up (show the final number immediately). Tarot may still change cards, but without the long orbit.

## 8. Screens (21)

welcome, birth, today, monthly, yearly, floor-upload, floor-result, house-check, readings, tarot, palm, bazi, compatibility, shop, masters, master-profile, booking-pending, booking-confirm, prescription, profile, paywall.

Sample household (all Example): main user Chua Boon Eng, 26 Jun 1990, Male, Kua 1 (East), birth time unknown. Partner Chou Jiahui Victoria, 28 Oct 1991, Female, Kua 6 (West), birth time unknown. Home: 4-room HDB Tampines, faces SE 142°, Period 8, completed 2012. “Today” is Monday 23 November 2026, Singapore time (UTC+8). Booking: Tue 24 Nov 2026, 7:30–8:15pm SGT, 45 min video, S$88 authorised not charged.

## 9. Flutter mapping notes

### 9.1 Theme

```dart
// Logical colours — match the HTML tokens, do not approximate a brighter gold.
const ink = Color(0xFF0B1026);
const ink2 = Color(0xFF121A3A);
const panel = Color(0xFF141B3C);
const gold = Color(0xFFBFA577);
const gold2 = Color(0xFFE3D6B8);
const goldDeep = Color(0xFF8A7350);
const goldHi = Color(0xFFEFE6D2);
const silver = Color(0xFFE4E6EC);
const ivory = Color(0xFFF4EFE4);
const ivory2 = Color(0xFFD8D2C4);
const good = Color(0xFF9FD3A8);
const care = Color(0xFFEFB894);

final theme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ink,
  colorScheme: ColorScheme.dark(
    background: ink,
    surface: panel,
    primary: const Color(0xFF1D2552),
    onPrimary: ivory,
    secondary: gold,
    onSecondary: ink,
    error: const Color(0xFF8E2A22),
  ),
);
```

Primary buttons should be a vertical gradient (`#1D2552` → `#151C40`) with a `Border.all(color: gold.withOpacity(0.7))`, not `colorScheme.primary` as a gold fill.

### 9.2 Type

Use `google_fonts`: `GoogleFonts.cormorantSc` for display, `GoogleFonts.sourceSerif4` for body. Set `applyFontVariations` as needed for Source Serif optical sizes. Tab labels and buttons use Source Serif 4 at 600, not a sans.

### 9.3 Components

- Phone / device chrome is prototype-only. In Flutter, use a real status bar and `NavigationBar` (or a custom 5-item bar) with champagne selected state and ivory2 unselected.
- Cards: `BoxDecoration(color: panel, borderRadius: 18, border: Border.all(color: goldDim))`.
- Starfield: a small custom `CustomPainter` (or a looping fragment shader) behind the navigator, paused in `MediaQuery.disableAnimations` / `disableAnimations`.
- Floor plan: `CustomPaint` or `SvgPicture` plus a short `AnimationController` for the sweep. Star tips can be a `showModalBottomSheet` or an in-page tip card, as in the prototype.
- Tarot: `Transform` + `AnimationController` for the shuffle orbit; a `Tween` on `Matrix4.rotationY` for the flip; keep “Shuffle again” in a `SafeArea` above the nav bar.
- Count-up: `IntTween` / `TweenAnimationBuilder`, skipped if `MediaQuery.of(context).disableAnimations`.
- Booking burst: a short particle overlay, one-shot, `IgnorePointer`.

### 9.4 Motion

Prefer `flutter/animation` curves close to `cubic-bezier(.2,.8,.2,1)` for settles and `ease-out` for counts. Respect `MediaQuery.disableAnimations` everywhere listed in §7.3.

### 9.5 Routing and structure

`GoRouter` (or equivalent) with hash-equivalent paths: `/welcome`, `/birth`, `/today`, `/monthly`, `/yearly`, `/floor-upload`, `/floor-result`, `/house-check`, `/readings`, `/tarot`, `/palm`, `/bazi`, `/compatibility`, `/shop`, `/masters`, `/master-profile`, `/booking-pending`, `/booking-confirm`, `/prescription`, `/profile`, `/paywall`. Tabs are a shell route around the five roots. Welcome and birth sit outside the tab shell.

### 9.6 Prototype parity

Match spacing, tokens, copy, and the B3 HDB / tarot motion as closely as practical. The prototype is the visual source of truth. Chart math in the real app stays rule-based; this file does not compute live BaZi.

## 10. Anti-goals

- Do not brighten the gold toward yellow (`#ffd56a` and similar are rejected).
- Do not fill the primary button with gold.
- Do not use Inter or a generic UI sans.
- Do not leave Chinese untranslated.
- Do not hide the main CTA below the first fold; use a sticky footer if the screen is long.
- Do not auto-add prescribed items to a cart or frame remedies as medicine.
- Do not invent billing, live payments, or real-master availability in this prototype.
- Do not leak snackbars across routes.
