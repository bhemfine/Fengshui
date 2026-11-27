import 'package:flutter_test/flutter_test.dart';
import 'package:inkstone/data/household.dart';
import 'package:inkstone/data/user_data.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetHouseholdDefaults();
  });

  tearDown(resetHouseholdDefaults);

  test(
    'active profile is Boon Eng and the partner is Jiahui, computed by the engine',
    () {
      expect(mainUser.name, 'Chua Boon Eng');
      expect(shortName(mainUser), 'Boon Eng');
      expect(mainUser.birth, DateTime(1990, 6, 26, 12));
      expect(mainUser.gender, Gender.male);
      expect(mainUser.timeKnown, isFalse);
      expect(mainUser.example, isTrue);
      expect(mainUser.kua.kua, computeKua(DateTime(1990, 6, 26, 12), Gender.male).kua);
      expect(mainUser.kua.kua, 1);
      expect(mainUser.kua.eastGroup, isTrue);

      expect(partner.name, 'Chou Jiahui Victoria');
      expect(shortName(partner), 'Jiahui');
      expect(partner.birth, DateTime(1991, 10, 28, 12));
      expect(partner.gender, Gender.female);
      expect(partner.timeKnown, isFalse);
      expect(partner.example, isTrue);
      expect(
        partner.kua.kua,
        computeKua(DateTime(1991, 10, 28, 12), Gender.female).kua,
      );
      expect(partner.kua.kua, 6);
      expect(partner.kua.eastGroup, isFalse);

      expect(savedProfiles, [mainUser, partner]);
    },
  );

  test(
    'saving a birth profile persists and Delete my data restores the couple',
    () async {
      await setMainUser(
        KuaPerson(
          name: 'Test User',
          birth: DateTime.parse('1985-03-04T08:30:00'),
          gender: Gender.female,
          saved: true,
          example: false,
          timeKnown: true,
        ),
      );
      expect(mainUser.name, 'Test User');
      expect(shortName(mainUser), 'Test User');
      expect(partner.name, 'Chou Jiahui Victoria');
      expect(shortName(partner), 'Jiahui');

      resetHouseholdDefaults();
      expect(mainUser.name, 'Chua Boon Eng');
      await bootstrapHousehold();
      expect(mainUser.name, 'Test User');
      expect(mainUser.timeKnown, isTrue);
      expect(mainUser.birth, DateTime.parse('1985-03-04T08:30:00'));
      expect(
        mainUser.kua.kua,
        computeKua(DateTime(1985, 3, 4, 8, 30), Gender.female).kua,
      );
      expect(partner.name, 'Chou Jiahui Victoria');

      await deleteAllUserData();
      expect(mainUser.name, 'Chua Boon Eng');
      expect(shortName(mainUser), 'Boon Eng');
      expect(partner.name, 'Chou Jiahui Victoria');
      expect(shortName(partner), 'Jiahui');
      expect(mainUser.example, isTrue);
      await bootstrapHousehold();
      expect(mainUser.name, 'Chua Boon Eng');
      expect(partner.name, 'Chou Jiahui Victoria');
    },
  );
}
