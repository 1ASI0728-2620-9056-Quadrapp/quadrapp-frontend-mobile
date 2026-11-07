import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';

import '../../helpers/fake_clock.dart';

void main() {
  group('Countdown', () {
    test('cuenta con el reloj monótono hasta cero y termina', () async {
      final clock = FakeClock();
      final ticks = StreamController<void>();
      final values = <Duration>[];
      final done = Countdown(
        clock,
        ticker: () => ticks.stream,
      ).run(const Duration(seconds: 3)).forEach(values.add);

      await Future<void>.delayed(Duration.zero);
      clock
        ..advance(const Duration(seconds: 1))
        ..advance(const Duration(milliseconds: 500));
      // Un tick atrasado no desvía la cuenta: se mide con el reloj.
      ticks.add(null);
      await Future<void>.delayed(Duration.zero);
      clock.advance(const Duration(seconds: 5));
      ticks.add(null);
      await done;

      expect(values, [
        const Duration(seconds: 3),
        const Duration(milliseconds: 1500),
        Duration.zero,
      ]);
    });

    test('con una duración de cero emite cero y termina', () async {
      final values = await Countdown(
        FakeClock(),
        ticker: () => const Stream<void>.empty(),
      ).run(Duration.zero).toList();

      expect(values, [Duration.zero]);
    });
  });

  test('formatCountdown muestra m:ss y redondea hacia arriba', () {
    const formatter = AppTimeFormatter();

    expect(formatter.formatCountdown(const Duration(seconds: 45)), '0:45');
    expect(formatter.formatCountdown(const Duration(seconds: 65)), '1:05');
    expect(
      formatter.formatCountdown(const Duration(milliseconds: 100)),
      '0:01',
    );
    expect(formatter.formatCountdown(Duration.zero), '0:00');
  });
}
