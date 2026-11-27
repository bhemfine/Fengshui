import 'package:flutter_test/flutter_test.dart';
import 'package:inkstone/data/current_home.dart';
import 'package:inkstone/data/local_store.dart';
import 'package:inkstone/data/quick_check.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    currentHome.value = exampleHome;
  });

  test('setCurrentHome writes facing and address, bootstrap reloads them', () async {
    final home = CurrentHome(
      label: '912 Hougang Street 91',
      facingDegrees: 95,
      completionYear: 2008,
      period: 8,
      example: false,
      address: '912 Hougang Street 91',
      postalCode: '530912',
      floor: '12',
      unit: '12-34',
      type: PropertyType.hdb,
      planRotationDeg: 30,
    );
    await setCurrentHome(home);
    currentHome.value = exampleHome;
    await bootstrapCurrentHome();
    final loaded = currentHome.value;
    expect(loaded.facingDegrees, 95);
    expect(loaded.floor, '12');
    expect(loaded.postalCode, '530912');
    expect(loaded.example, isFalse);
    expect(loaded.type, PropertyType.hdb);
    expect(loaded.planRotationDeg, 30);
  });

  test('useAsCurrentHome keeps the main-door facing and the floor', () async {
    useAsCurrentHome(QuickCheckInput(
      type: PropertyType.condo,
      completionYear: 2016,
      method: FacingMethod.unsure,
      facings: const {FacingMethod.mainDoor: 200, FacingMethod.balcony: 20},
      people: const [],
      home: const HomeDetails(address: 'A condo', postalCode: '098765', floor: '27'),
    ));
    await Future<void>.delayed(Duration.zero);
    expect(currentHome.value.facingDegrees, 200);
    expect(currentHome.value.floor, '27');
    expect(currentHome.value.type, PropertyType.condo);
    expect(currentHome.value.example, isFalse);
  });

  test('LocalStore clearAll drops the saved home key', () async {
    await setCurrentHome(exampleHome.copyWith(facingDegrees: 10, example: false));
    await LocalStore.instance.clearAll();
    currentHome.value = exampleHome;
    await bootstrapCurrentHome();
    expect(currentHome.value.facingDegrees, exampleHome.facingDegrees);
    expect(currentHome.value.example, isTrue);
  });
}
