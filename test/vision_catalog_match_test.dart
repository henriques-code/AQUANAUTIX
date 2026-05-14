import 'package:aquanautix/core/species/species_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SpeciesCatalog.instance.resetForTest();
  });

  test('matchByScientific encontra robalo', () async {
    await SpeciesCatalog.instance.ensureLoaded();
    expect(
      SpeciesCatalog.instance.matchByScientific('Dicentrarchus labrax')?.id,
      'dicentrarchus_labrax',
    );
    expect(
      SpeciesCatalog.instance.matchByScientific('dicentrarchus labrax')?.id,
      'dicentrarchus_labrax',
    );
  });
}
