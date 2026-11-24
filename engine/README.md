# inkstone_engine

Pure-Dart, offline chart engine for the **Inkstone** feng shui app. No Flutter, no network.

## WARNING — read before shipping

* **All results MUST be verified against at least 20 known charts** from reputable references
  and established software before release. Cross-check at minimum:
  * Solar term instants (Li Chun 立春 *Start of Spring*, the 12 *jie* 节 terms, solstices) against
    the Hong Kong Observatory / Purple Mountain Observatory tables, for 1930–2050.
  * Year, month, day and hour pillars (四柱 *Si Zhu*, Four Pillars) against at least two
    independent Ba Zi programs, including births within ±1 day of Li Chun and of month *jie*
    terms, births between 23:00 and 01:00, and births with true-solar-time correction.
  * Hidden stems (藏干 *Cang Gan*) tables and element counts.
  * Kua (命卦 *Ming Gua*) numbers for both genders, pre- and post-2000, January/early-February births.
  * Flying Stars (玄空飞星 *Xuan Kong Fei Xing*) natal charts for all 24 mountains in Periods 7, 8, 9,
    and annual/monthly star charts.
  * Day Officers (建除十二神 *Jian Chu Shi Er Shen*) against a printed Tong Shu (通书 almanac).
* **Flying Stars replacement charts (替卦 *Ti Gua*) are NOT implemented** (TODO). Charts whose facing
  lies near a mountain boundary may need a replacement chart in practice.
* **Strength, favourable elements and daily scores are heuristics for entertainment only.**
  They are not a substitute for a professional reading.

## What it computes

| Module | Content |
|---|---|
| `stems_branches.dart` | 10 Heavenly Stems (天干 *Tian Gan*), 12 Earthly Branches (地支 *Di Zhi*), 60-cycle (甲子 *Jia Zi*), element relations |
| `solar_terms.dart` | Low-precision apparent solar longitude (Meeus ch. 25), 24 solar terms (节气 *Jie Qi*) solver |
| `bazi.dart` | Four Pillars (八字 *Ba Zi*), Day Master (日主 *Ri Zhu*), element counts, strength heuristic |
| `kua.dart` | Kua number, East/West group, 8 directions |
| `flying_stars.dart` | 24 mountains, periods, natal/annual/monthly flying star charts |
| `almanac.dart` | Day officer, clash animal, lucky double hours, daily score, tag keys |

## Conventions

* **Input time**: wall-clock birth time plus a fixed **UTC offset in hours** (e.g. `+8.0` for Singapore).
  No IANA database; the caller must supply the historical offset (incl. DST).
* **Year boundary**: Li Chun 立春 (*Start of Spring*, solar longitude 315°), not Chinese New Year.
* **Month boundary**: the 12 *jie* 节 terms (solar longitude 315° + 30°·k).
* **Day boundary**: 23:00 by default (start of the Zi 子 *Rat* double hour). Alternative:
  `ZiConvention.dayChangesAtMidnight` (late Zi 夜子 *Ye Zi*: day pillar keeps the date, hour stem
  uses the next day's stem).
* **True solar time**: optional, off by default; uses *mean* solar time from longitude
  (equation of time not applied — TODO).
* **Delta T**: constant 69 s (adequate for 1950–2050 at minute precision).

## Running tests

```
dart pub get
dart test
dart analyze
```

Tests marked `TODO-verify` encode values believed correct but not yet cross-checked.
