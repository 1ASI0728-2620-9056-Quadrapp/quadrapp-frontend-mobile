import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

void main() {
  group('UserRole (la experiencia que le toca)', () {
    test('solo admin y operator son de Operación; driver es Conductor', () {
      expect(UserRole.driver.isOperations, isFalse);
      expect(UserRole.admin.isOperations, isTrue);
      expect(UserRole.operator.isOperations, isTrue);
    });
  });

  group('EmailAddress', () {
    test('se normaliza a minúsculas y sin espacios', () {
      expect(
        EmailAddress.create('  Conductor@UPC.edu.pe ').valueOrNull?.value,
        'conductor@upc.edu.pe',
      );
    });

    test('un formato inválido es un error de validación', () {
      for (final raw in ['', 'sin-arroba', 'a@b', 'a b@c.pe', '@upc.edu.pe']) {
        expect(
          EmailAddress.create(raw).failureOrNull,
          isA<ValidationFailure>(),
          reason: raw,
        );
      }
      expect(
        EmailAddress.create('${'a' * 250}@upc.pe').failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  group('OtpCode (6 dígitos)', () {
    test('acepta exactamente 6 dígitos', () {
      expect(OtpCode.create('123456').valueOrNull?.value, '123456');
      expect(OtpCode.create(' 000000 ').valueOrNull?.value, '000000');
    });

    test('rechaza otra longitud o caracteres que no son dígitos', () {
      for (final raw in ['12345', '1234567', '12a456', '', '12 456']) {
        expect(
          OtpCode.create(raw).failureOrNull,
          isA<ValidationFailure>(),
          reason: raw,
        );
      }
    });
  });

  group('secretos: toString nunca muestra su valor', () {
    test('tokens, código OTP y correo', () {
      final secrets = {
        'access-SECRET': accessToken('access-SECRET'),
        'refresh-SECRET': refreshToken('refresh-SECRET'),
        '123456': OtpCode.create('123456').valueOrNull,
        'conductor@upc.edu.pe': email(),
      };

      for (final MapEntry(key: secret, value: object) in secrets.entries) {
        expect('$object', isNot(contains(secret)));
        expect(object.toString(), isNot(contains(secret)));
      }
      // Tampoco cuando van dentro de otro objeto (Equatable).
      expect('${sampleGrant()}', isNot(contains('access-1')));
      expect('${sampleStored()}', isNot(contains('refresh-1')));
    });

    test('un token vacío no es válido', () {
      expect(AccessToken.create('  ').failureOrNull, isA<ValidationFailure>());
      expect(RefreshToken.create('').failureOrNull, isA<ValidationFailure>());
    });
  });

  group('OtpChallenge (vigencia con el reloj monótono)', () {
    OtpChallenge challenge(FakeClock clock) => OtpChallenge(
      email: email(),
      expiresIn: const Duration(minutes: 5),
      receivedAt: clock.monotonic(),
    );

    test('cuenta regresiva hasta cero y luego vence', () {
      final clock = FakeClock();
      final code = challenge(clock);

      expect(code.remaining(clock), const Duration(minutes: 5));
      expect(code.isExpired(clock), isFalse);

      clock.advance(const Duration(minutes: 4, seconds: 30));
      expect(code.remaining(clock), const Duration(seconds: 30));

      clock.advance(const Duration(minutes: 1));
      expect(code.remaining(clock), Duration.zero);
      expect(code.isExpired(clock), isTrue);
    });

    test('no depende de la hora de pared del teléfono', () {
      final clock = FakeClock();
      final code = challenge(clock);

      clock.wallClock = DateTime.utc(2035);

      expect(code.remaining(clock), const Duration(minutes: 5));
      expect(code.isExpired(clock), isFalse);
    });
  });
}
