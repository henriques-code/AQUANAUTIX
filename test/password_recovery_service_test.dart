import 'package:aquanautix/core/auth/password_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateEmail rejeita formatos inválidos', () {
    final svc = PasswordRecoveryService.instance;
    expect(svc.validateEmail(''), isNotNull);
    expect(svc.validateEmail('sem-arroba'), isNotNull);
    expect(svc.validateEmail('a@b'), isNotNull);
    expect(svc.validateEmail('user@example.com'), isNull);
  });
}
