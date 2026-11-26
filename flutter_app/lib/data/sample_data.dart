// Example data only — not a live reading. Mirrors DESIGN §8 and the prototype.

class Person {
  const Person({
    required this.name,
    required this.birthLabel,
    required this.place,
    required this.gender,
    this.kua,
    this.birthTimeKnown = true,
  });
  final String name;
  final String birthLabel;
  final String place;
  final String gender;
  final int? kua;
  final bool birthTimeKnown;
}

class HomeInfo {
  const HomeInfo({
    required this.type,
    required this.town,
    required this.address,
    required this.facingDegrees,
    required this.facingLabel,
    required this.period,
    required this.completed,
  });
  final String type;
  final String town;
  final String address;
  final int facingDegrees;
  final String facingLabel;
  final int period;
  final int completed;
}

class DoubleHour {
  const DoubleHour({
    required this.english,
    required this.chinese,
    required this.meaning,
    required this.range,
    this.isGood = false,
  });
  final String english;
  final String chinese;

  /// Translation (the hour's animal).
  final String meaning;
  final String range;
  final bool isGood;
}

class Almanac {
  const Almanac({required this.goodFor, required this.avoid});
  final List<String> goodFor;
  final List<String> avoid;
}

class Master {
  const Master({
    required this.name,
    required this.glyph,
    required this.specialities,
    required this.languages,
    required this.rating,
    required this.price,
    this.verified = true,
    this.tappable = false,
  });
  final String name;
  final String glyph;
  final String specialities;
  final String languages;
  final String rating;
  final String price;
  final bool verified;
  final bool tappable;
}

class ShopItem {
  const ShopItem({required this.name, required this.category, required this.note, required this.price, this.glyph = '✦'});
  final String name;
  final String category;
  final String note;
  final String price;
  final String glyph;
}

class TarotCardData {
  const TarotCardData({required this.name, required this.meaning, this.reversedMeaning});
  final String name;
  final String meaning;
  final String? reversedMeaning;
}

class Palace {
  const Palace({required this.direction, required this.mountain, required this.water, required this.tip});
  final String direction;
  final int mountain;
  final int water;
  final String tip;
}

class PlacementTip {
  const PlacementTip({required this.room, required this.text, required this.good});
  final String room;
  final String text;
  final bool good;
}

class Pillar {
  const Pillar({required this.label, required this.stem, required this.branch, required this.element, this.isSelf = false});
  final String label;
  final String stem;
  final String branch;
  final String element;
  final bool isSelf;
}

class LuckPillar {
  const LuckPillar({required this.age, required this.chinese, this.current = false});
  final int age;
  final String chinese;
  final bool current;
}

class Booking {
  const Booking({
    required this.dateLabel,
    required this.timeLabel,
    required this.duration,
    required this.price,
    required this.master,
  });
  final String dateLabel;
  final String timeLabel;
  final String duration;
  final String price;
  final String master;
}

class PrescriptionStep {
  const PrescriptionStep({required this.title, required this.detail});
  final String title;
  final String detail;
}

// ---- Household ----

const meiLin = Person(
  name: 'Mei Lin',
  birthLabel: '12 Mar 1992, 08:15',
  place: 'Singapore (example) · UTC+8',
  gender: 'Female',
  // Female, solar year 1992: (1992 % 9 + 4) % 9 = 7. Checked by test/kua_sample_test.dart.
  kua: 7,
);

const weiHao = Person(
  name: 'Wei Hao',
  birthLabel: '3 Aug 1989',
  place: 'Singapore (example)',
  gender: 'Male',
  birthTimeKnown: false,
);

const sampleHome = HomeInfo(
  type: '4-room HDB',
  town: 'Tampines',
  address: 'Block 123 Tampines Street 11, #08-45 (example)',
  facingDegrees: 142,
  facingLabel: 'South-east',
  period: 8,
  completed: 2012,
);

// ---- Today ----

const todayWeekday = 'Monday';
const todayDay = 23;
const todayMonthYear = 'November 2026';
const todayLunar = 'Lunar 10th month, day 15 — full moon (example)';
const todayLucky = 'Lucky: face north-east when you work. Lucky colour: deep green (example).';

const sampleAlmanac = Almanac(
  goodFor: ['Sign papers', 'Travel', 'Visit family'],
  avoid: ['Move heavy furniture', 'Start renovation', 'Cut hair'],
);

const sampleDoubleHours = <DoubleHour>[
  DoubleHour(english: 'Zi', chinese: '子', meaning: 'Rat', range: '11pm–1am', isGood: true),
  DoubleHour(english: 'Chou', chinese: '丑', meaning: 'Ox', range: '1–3am'),
  DoubleHour(english: 'Yin', chinese: '寅', meaning: 'Tiger', range: '3–5am'),
  DoubleHour(english: 'Mao', chinese: '卯', meaning: 'Rabbit', range: '5–7am', isGood: true),
  DoubleHour(english: 'Chen', chinese: '辰', meaning: 'Dragon', range: '7–9am', isGood: true),
  DoubleHour(english: 'Si', chinese: '巳', meaning: 'Snake', range: '9–11am'),
  DoubleHour(english: 'Wu', chinese: '午', meaning: 'Horse', range: '11am–1pm', isGood: true),
  DoubleHour(english: 'Wei', chinese: '未', meaning: 'Goat', range: '1–3pm'),
  DoubleHour(english: 'Shen', chinese: '申', meaning: 'Monkey', range: '3–5pm'),
  DoubleHour(english: 'You', chinese: '酉', meaning: 'Rooster', range: '5–7pm', isGood: true),
  DoubleHour(english: 'Xu', chinese: '戌', meaning: 'Dog', range: '7–9pm'),
  DoubleHour(english: 'Hai', chinese: '亥', meaning: 'Pig', range: '9–11pm'),
];

/// Index of the current double hour (Mao, 5–7am).
const sampleCurrentHourIndex = 3;

// ---- Month / year ----

const monthGoodDays = <int>[2, 6, 9, 13, 17, 20, 23, 27];
const monthCareDays = <int>[4, 11, 15, 22, 29];

/// November 2026 starts on a Sunday (Sunday-start grid → 0 leading blanks).
const monthLeadingBlanks = 0;
const monthDays = 30;

const monthOutlook = <(String, String)>[
  ('Career', 'Steady. Finish what is open before starting new work.'),
  ('Money', 'Good for saving. Delay big purchases to mid-month.'),
  ('Health', 'Rest early on take-care days. Warm food helps.'),
  ('Love', 'Plan time together; small gestures land well.'),
];

const yearMonths = <(String, String)>[
  ('Jan', 'Plan quietly'), ('Feb', 'New starts at work'), ('Mar', 'Watch spending'),
  ('Apr', 'Good for travel'), ('May', 'Rest more'), ('Jun', 'Family first'),
  ('Jul', 'Money flows in'), ('Aug', 'Avoid big moves'), ('Sep', 'Learn something'),
  ('Oct', 'Steady progress'), ('Nov', 'Finish projects'), ('Dec', 'Celebrate gently'),
];

// ---- Home / Flying Stars ----

/// Palaces in grid order NW, N, NE, W, Centre, E, SW, S, SE.
const samplePalaces = <Palace>[
  Palace(direction: 'North-west', mountain: 1, water: 7, tip: 'Steady energy. Good for rest; keep the room tidy.'),
  Palace(direction: 'North', mountain: 6, water: 2, tip: 'Quiet area. Soft light helps.'),
  Palace(direction: 'North-east', mountain: 8, water: 4, tip: 'Strong, lucky area (吉 — favourable). Ideal for the desk or bed head.'),
  Palace(direction: 'West', mountain: 9, water: 5, tip: 'Busy energy. Avoid clutter here.'),
  Palace(direction: 'Centre', mountain: 2, water: 3, tip: 'Heart of the home. Keep it open and bright.'),
  Palace(direction: 'East', mountain: 4, water: 9, tip: 'Growth area. Plants do well here.'),
  Palace(direction: 'South-west', mountain: 5, water: 1, tip: 'Heavy energy. Keep metal decor, not fire colours.'),
  Palace(direction: 'South', mountain: 7, water: 6, tip: 'Warm area. Good for gathering.'),
  Palace(direction: 'South-east', mountain: 3, water: 8, tip: 'The door side. Keep it lit and clear to welcome good energy.'),
];

const samplePlacementTips = <PlacementTip>[
  PlacementTip(room: 'Master bedroom', text: 'headboard to the north-east wall.', good: true),
  PlacementTip(room: 'Kitchen', text: 'keep the stove off the sink line.', good: false),
  PlacementTip(room: 'Study (bedroom 3)', text: 'desk facing north-east, back to a wall.', good: true),
  PlacementTip(room: 'Entrance', text: 'keep it lit and clear.', good: true),
];

const houseCheckScores = <(String, int, bool)>[
  ('Mei Lin', 58, false),
  ('Wei Hao', 54, false),
];

const compatibilityScore = 76;

// ---- BaZi ----

const sampleBaziPillars = <Pillar>[
  Pillar(label: 'Year', stem: '壬', branch: '申', element: 'Water'),
  Pillar(label: 'Month', stem: '癸', branch: '卯', element: 'Wood'),
  Pillar(label: 'You', stem: '丙', branch: '午', element: 'Fire', isSelf: true),
  Pillar(label: 'Hour', stem: '壬', branch: '辰', element: 'Earth'),
];

const sampleElementBalance = <(String, int)>[
  ('Wood', 2), ('Fire', 2), ('Earth', 1), ('Metal', 1), ('Water', 3),
];

const sampleLuckPillars = <LuckPillar>[
  LuckPillar(age: 2, chinese: '甲辰'),
  LuckPillar(age: 12, chinese: '乙巳'),
  LuckPillar(age: 22, chinese: '丙午'),
  LuckPillar(age: 32, chinese: '丁未', current: true),
  LuckPillar(age: 42, chinese: '戊申'),
];

// Mei Lin, Kua 7 (West group).
const kuaGoodDirections = 'NW, SW, NE, W';
const kuaCareDirections = 'N, S, SE, E';

// ---- Masters & booking ----

const sampleMasters = <Master>[
  Master(
    name: 'Tan Su Ling',
    glyph: '谭',
    specialities: 'Flying Stars, BaZi, new homes',
    languages: 'English / Mandarin / Hokkien',
    rating: 'Excellent · 4.9 · 212 readings',
    price: 'From S\$88 (example)',
    tappable: true,
  ),
  Master(
    name: 'Lim Boon Kiat',
    glyph: '林',
    specialities: 'Commercial feng shui, dates',
    languages: 'English / Mandarin / Cantonese',
    rating: 'Very good · 4.7 · 98 readings',
    price: 'From S\$120 (example)',
  ),
  Master(
    name: 'Nur Aisyah Rahman',
    glyph: 'N',
    specialities: 'BaZi for careers, compatibility',
    languages: 'English / Malay',
    rating: 'Very good · 4.8 · 64 readings',
    price: 'From S\$70 (example)',
  ),
];

const sampleSlots = <String>['Tue 24 Nov, 7:30pm SGT', 'Wed 25 Nov, 8:00pm SGT'];

const sampleBooking = Booking(
  dateLabel: 'Tue 24 November',
  timeLabel: '7:30–8:15pm SGT',
  duration: '45 min video',
  price: 'S\$88 (example) — authorised, not charged',
  master: 'Master Tan',
);

const samplePrescription = <PrescriptionStep>[
  PrescriptionStep(title: 'Move the bed', detail: 'Master bedroom, headboard to north-east wall.'),
  PrescriptionStep(title: 'Light the entrance', detail: 'South-east door. Warm lamp on in the evening.'),
  PrescriptionStep(title: 'Calm the kitchen', detail: 'Small plant between stove and sink.'),
];

// ---- Shop ----

const shopCategories = <String>['Wealth', 'Love', 'Protection', 'Home'];

const sampleShopItems = <ShopItem>[
  ShopItem(name: 'Citrine cluster', category: 'Wealth', note: 'Supports the wealth star by the door. Place in the south-east.', price: 'S\$38', glyph: '◆'),
  ShopItem(name: 'Black tourmaline', category: 'Protection', note: 'Steadies busy energy. Place near the entrance shoe rack.', price: 'S\$24', glyph: '◈'),
  ShopItem(name: 'Salt water cure', category: 'Home', note: 'Softens the take-care star. Place in the kitchen corner.', price: 'S\$15', glyph: '◌'),
  ShopItem(name: 'Brass wu lou', category: 'Home', note: 'Traditional gourd for rest. Place on the bedside table.', price: 'S\$32', glyph: '⚱'),
  ShopItem(name: 'Rose quartz pair', category: 'Love', note: 'Shared calm. Place in the south-west of the bedroom.', price: 'S\$28', glyph: '❦'),
];

// ---- Tarot ----

const sampleTarotCards = <TarotCardData>[
  TarotCardData(name: 'Temperance', meaning: 'Mix slowly. Patience brings the balance you want.'),
  TarotCardData(name: 'The Star', meaning: 'Hope returns. Take one small hopeful step.'),
  TarotCardData(name: 'Eight of Pentacles', meaning: 'Practise the craft. Steady work pays.'),
  TarotCardData(name: 'The Hermit', meaning: 'Step back and think before you answer.'),
  TarotCardData(name: 'Two of Cups', meaning: 'A partnership deepens. Say thank you.'),
  TarotCardData(name: 'The Sun', meaning: 'Clear skies. Share good news simply.'),
  TarotCardData(name: 'Strength', meaning: 'Gentle firmness works better than force.'),
  TarotCardData(name: 'The Empress', meaning: 'Tend what you have. Care makes it grow.'),
  TarotCardData(name: 'Ace of Wands', meaning: 'A small spark. Start the first page today.'),
  TarotCardData(name: 'Six of Swords', meaning: 'Move on calmly. Calmer water is ahead.'),
];
