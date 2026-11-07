import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_day.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_time_slot.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import 'support.dart';

void main() {
  group('ClockTime', () {
    test('acepta de 00:00 a 23:59', () {
      expect(ClockTime.create(0, 0).valueOrNull?.minutesOfDay, 0);
      final last = ClockTime.create(23, 59).valueOrNull!;
      expect((last.hour, last.minute), (23, 59));
    });

    test('rechaza horas y minutos fuera de rango', () {
      for (final (hour, minute) in [(24, 0), (-1, 0), (7, 60), (7, -1)]) {
        expect(
          ClockTime.create(hour, minute).failureOrNull,
          isA<ValidationFailure>(),
        );
      }
    });
  });

  group('AlertTimeSlot (desde < hasta)', () {
    test('una franja válida se crea', () {
      expect(
        AlertTimeSlot.create(from: time(7, 30), to: time(9, 0)).isSuccess,
        isTrue,
      );
      // Un minuto de diferencia basta.
      expect(
        AlertTimeSlot.create(from: time(7, 30), to: time(7, 31)).isSuccess,
        isTrue,
      );
    });

    test('hora de fin igual o anterior es un error de validación', () {
      for (final (from, to) in [
        (time(9, 0), time(9, 0)),
        (time(9, 0), time(7, 30)),
        // No cruza la medianoche.
        (time(22, 0), time(1, 0)),
      ]) {
        final result = AlertTimeSlot.create(from: from, to: to);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect((result.failureOrNull! as ValidationFailure).errors, {
          'to': ['after-from'],
        });
      }
    });
  });

  group('AlertSubscriptionDraft (US33)', () {
    Result<AlertSubscriptionDraft> draft(Iterable<int> days) =>
        AlertSubscriptionDraft.create(
          lotId: lotId,
          days: days,
          from: time(7, 30),
          to: time(9, 0),
        );

    test('ordena los días y quita los repetidos', () {
      final created = draft([5, 1, 1, 3]).valueOrNull!;

      expect(created.days, [
        AlertDay.monday,
        AlertDay.wednesday,
        AlertDay.friday,
      ]);
    });

    test('admite los 7 días', () {
      expect(draft([1, 2, 3, 4, 5, 6, 7]).valueOrNull?.days, hasLength(7));
    });

    test('sin días o con un día fuera de 1..7 es un error de validación', () {
      for (final days in [
        <int>[],
        [0],
        [8],
        [1, 9],
      ]) {
        final failure = draft(days).failureOrNull;
        expect(failure, isA<ValidationFailure>(), reason: '$days');
        expect((failure! as ValidationFailure).errors, contains('days'));
      }
    });

    test('una franja invertida se rechaza', () {
      final result = AlertSubscriptionDraft.create(
        lotId: lotId,
        days: const [1],
        from: time(9, 0),
        to: time(7, 30),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('PushToken', () {
    test('un token vacío o demasiado largo no es válido', () {
      expect(PushToken.create('   ').failureOrNull, isA<ValidationFailure>());
      expect(
        PushToken.create('x' * (PushToken.maxLength + 1)).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(PushToken.create('x' * PushToken.maxLength).isSuccess, isTrue);
    });

    test('nunca muestra su valor al convertirse en texto (logs)', () {
      final token = pushToken('super-secret-token');

      expect('$token', isNot(contains('super-secret-token')));
      expect(token.toString(), isNot(contains('secret')));
    });
  });
}
