import 'package:aquanautix/core/auth/login_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('remember session default true', () async {
    expect(await LoginSessionStore.getRememberSession(), isTrue);
  });

  test('persistAfterLogin guarda email só com remember', () async {
    await LoginSessionStore.persistAfterLogin(
      rememberSession: true,
      email: 'pescador@example.com',
    );
    expect(await LoginSessionStore.getSavedEmail(), 'pescador@example.com');
    expect(await LoginSessionStore.getRememberSession(), isTrue);

    await LoginSessionStore.persistAfterLogin(
      rememberSession: false,
      email: 'pescador@example.com',
    );
    expect(await LoginSessionStore.getSavedEmail(), isNull);
    expect(await LoginSessionStore.getRememberSession(), isFalse);
  });
}
