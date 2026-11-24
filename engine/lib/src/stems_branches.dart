import 'models.dart';

/// Heavenly Stem (天干 Tian Gan).
class Stem {
  const Stem(this.index, this.chinese, this.pinyin, this.english, this.element);
  final int index;
  final String chinese;
  final String pinyin;
  final String english;
  final FiveElement element;

  bool get isYang => index.isEven;

  Map<String, Object?> toJson() => {
        'index': index,
        'chinese': chinese,
        'pinyin': pinyin,
        'english': english,
        'element': element.name,
        'yinYang': isYang ? 'yang' : 'yin',
      };
}

/// Earthly Branch (地支 Di Zhi).
class Branch {
  const Branch(this.index, this.chinese, this.pinyin, this.animal, this.element);
  final int index;
  final String chinese;
  final String pinyin;

  /// Zodiac animal (生肖 Sheng Xiao) in English.
  final String animal;
  final FiveElement element;

  bool get isYang => index.isEven;
  String get english => '$pinyin ($animal)';

  Map<String, Object?> toJson() => {
        'index': index,
        'chinese': chinese,
        'pinyin': pinyin,
        'english': english,
        'animal': animal,
        'element': element.name,
        'yinYang': isYang ? 'yang' : 'yin',
      };
}

const List<Stem> stems = [
  Stem(0, '甲', 'Jia', 'Yang Wood', FiveElement.wood),
  Stem(1, '乙', 'Yi', 'Yin Wood', FiveElement.wood),
  Stem(2, '丙', 'Bing', 'Yang Fire', FiveElement.fire),
  Stem(3, '丁', 'Ding', 'Yin Fire', FiveElement.fire),
  Stem(4, '戊', 'Wu', 'Yang Earth', FiveElement.earth),
  Stem(5, '己', 'Ji', 'Yin Earth', FiveElement.earth),
  Stem(6, '庚', 'Geng', 'Yang Metal', FiveElement.metal),
  Stem(7, '辛', 'Xin', 'Yin Metal', FiveElement.metal),
  Stem(8, '壬', 'Ren', 'Yang Water', FiveElement.water),
  Stem(9, '癸', 'Gui', 'Yin Water', FiveElement.water),
];

const List<Branch> branches = [
  Branch(0, '子', 'Zi', 'Rat', FiveElement.water),
  Branch(1, '丑', 'Chou', 'Ox', FiveElement.earth),
  Branch(2, '寅', 'Yin', 'Tiger', FiveElement.wood),
  Branch(3, '卯', 'Mao', 'Rabbit', FiveElement.wood),
  Branch(4, '辰', 'Chen', 'Dragon', FiveElement.earth),
  Branch(5, '巳', 'Si', 'Snake', FiveElement.fire),
  Branch(6, '午', 'Wu', 'Horse', FiveElement.fire),
  Branch(7, '未', 'Wei', 'Goat', FiveElement.earth),
  Branch(8, '申', 'Shen', 'Monkey', FiveElement.metal),
  Branch(9, '酉', 'You', 'Rooster', FiveElement.metal),
  Branch(10, '戌', 'Xu', 'Dog', FiveElement.earth),
  Branch(11, '亥', 'Hai', 'Pig', FiveElement.water),
];

/// Hidden stems (藏干 Cang Gan) per branch; first entry is the main qi (本气 Ben Qi).
const List<List<int>> hiddenStemTable = [
  [9], // 子 Zi: 癸
  [5, 9, 7], // 丑 Chou: 己 癸 辛
  [0, 2, 4], // 寅 Yin: 甲 丙 戊
  [1], // 卯 Mao: 乙
  [4, 1, 9], // 辰 Chen: 戊 乙 癸
  [2, 6, 4], // 巳 Si: 丙 庚 戊
  [3, 5], // 午 Wu: 丁 己
  [5, 3, 1], // 未 Wei: 己 丁 乙
  [6, 8, 4], // 申 Shen: 庚 壬 戊
  [7], // 酉 You: 辛
  [4, 7, 3], // 戌 Xu: 戊 辛 丁
  [8, 0], // 亥 Hai: 壬 甲
];

List<Stem> hiddenStemsOf(Branch b) => hiddenStemTable[b.index].map((i) => stems[i]).toList();

/// Position (0..59) in the 60-cycle (六十甲子 Liu Shi Jia Zi) or -1 if parity mismatches.
int sexagenaryIndex(int stem, int branch) {
  if ((stem - branch).isOdd) return -1;
  return (6 * stem - 5 * branch) % 60;
}

/// Six Harmony partner (六合 Liu He).
int sixHarmonyPartner(int branch) => (13 - branch) % 12;

/// Clash partner (六冲 Liu Chong).
int clashPartner(int branch) => (branch + 6) % 12;

/// True if two branches belong to the same Three Harmony group (三合 San He).
bool inThreeHarmony(int a, int b) => a != b && (a - b) % 4 == 0;
