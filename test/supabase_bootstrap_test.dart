import 'package:aquanautix/core/supabase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('supabase_bootstrap (sem --dart-define)', () {
    test('isSupabaseConfigured é false sem chaves compile-time', () {
      expect(isSupabaseConfigured, isFalse);
    });

    test('canUseSupabase é false sem init', () {
      expect(canUseSupabase, isFalse);
      expect(isSupabaseReady, isFalse);
    });

    test('supabaseClientOrNull não rebenta sem init', () {
      expect(supabaseClientOrNull, isNull);
    });

    test('supabaseAuthStateChangesOrNull é null sem cliente', () {
      expect(supabaseAuthStateChangesOrNull, isNull);
    });

    test('isSupabaseAuthenticated é false em modo convidado', () {
      expect(isSupabaseAuthenticated, isFalse);
    });
  });
}
