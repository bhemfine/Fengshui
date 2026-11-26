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

// ---- Today ----

// ---- Month / year ----

// ---- Home / Flying Stars ----

// ---- BaZi ----

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
