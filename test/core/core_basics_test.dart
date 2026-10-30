import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/problem_details.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

import '../helpers/fake_clock.dart';

class _Item implements Resettable {
  _Item({this.throws = false});

  final bool throws;
  int resets = 0;

  @override
  Future<void> reset() async {
    resets++;
    if (throws) throw StateError('boom');
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  group('Result', () {
    test('map y flatMap transforman el éxito y dejan pasar el error', () {
      const ok = Success<int>(2);
      const err = Err<int>(NetworkFailure());

      expect(ok.map((v) => v * 2), const Success(4));
      expect(err.map((v) => v * 2), const Err<int>(NetworkFailure()));
      expect(ok.flatMap((v) => Success('v$v')), const Success('v2'));
      expect(
        ok.flatMap<int>((_) => const Err(NotFoundFailure())).isFailure,
        isTrue,
      );
    });

    test('fold, valueOrNull y failureOrNull', () {
      const ok = Success<int>(2);
      const err = Err<int>(NetworkFailure());

      expect(ok.fold((v) => 'ok$v', (f) => 'err'), 'ok2');
      expect(
        err.fold((v) => 'ok', (f) => f.runtimeType.toString()),
        'NetworkFailure',
      );
      expect(ok.valueOrNull, 2);
      expect(err.valueOrNull, isNull);
      expect(err.failureOrNull, isA<NetworkFailure>());
    });
  });

  test('los identificadores tipados envuelven un int', () {
    const lot = LotId(7);
    const space = SpaceId(7);

    expect(lot.value, 7);
    expect(space.value, 7);
    expect(const LotId(7) == lot, isTrue);
  });

  test('ProblemDetails lee un cuerpo tolerante', () {
    expect(ProblemDetails.tryParse('texto'), isNull);
    final problem = ProblemDetails.tryParse({
      'title': 'T',
      'status': 'x',
      'errors': {
        'a': 'una',
        'b': ['dos', 3],
      },
    })!;

    expect(problem.title, 'T');
    expect(problem.status, isNull);
    expect(problem.errors, {
      'a': ['una'],
      'b': ['dos', '3'],
    });
  });

  group('almacenes en memoria', () {
    test('SecureStore', () async {
      final store = InMemorySecureStore();
      await store.write('a', '1');
      await store.write('b', '2');

      expect(await store.read('a'), '1');
      await store.delete('a');
      expect(await store.read('a'), isNull);
      await store.deleteAll();
      expect(await store.read('b'), isNull);
    });

    test('KeyValueStore borra por prefijo y conserva lo demás', () async {
      final store = InMemoryKeyValueStore();
      await store.setString('${StoreKeys.cache}layout', 'x');
      await store.setString('${StoreKeys.cache}occupancy', 'y');
      await store.setString('${StoreKeys.user}lot', '3');
      await store.setString('${StoreKeys.device}locale', 'es');

      await store.removeByPrefix(StoreKeys.cache);
      await store.removeByPrefix(StoreKeys.user);

      expect(await store.getString('${StoreKeys.cache}layout'), isNull);
      expect(await store.getString('${StoreKeys.user}lot'), isNull);
      expect(await store.getString('${StoreKeys.device}locale'), 'es');
    });
  });

  group('ResettableRegistry', () {
    test('limpia todo aunque uno falle', () async {
      final failing = _Item(throws: true);
      final ok = _Item();
      final registry = ResettableRegistry()
        ..register(failing)
        ..register(ok)
        ..register(ok);

      await registry.resetAll();

      expect(registry.items, hasLength(2));
      expect(failing.resets, 1);
      expect(ok.resets, 1);
    });
  });

  group('tiempo', () {
    test('AppTimeFormatter muestra la hora de Lima (UTC-5)', () {
      const formatter = AppTimeFormatter();
      final instant = DateTime.utc(2026, 9, 28, 13, 42);

      expect(_plain(formatter.formatTime(instant, 'en')), '8:42 AM');
      expect(formatter.formatTime(instant, 'es'), '8:42');
    });

    test('AppTimeFormatter cruza la medianoche', () {
      const formatter = AppTimeFormatter();

      expect(
        formatter.toLima(DateTime.utc(2026, 9, 29, 3)),
        DateTime.utc(2026, 9, 28, 22),
      );
    });

    test('SystemClock devuelve UTC y un tiempo monótono no decreciente', () {
      final clock = SystemClock();
      final first = clock.monotonic();

      expect(clock.now().isUtc, isTrue);
      expect(clock.monotonic() >= first, isTrue);
    });

    test('FakeClock: ajustar la hora de pared no cambia el monótono', () {
      final clock = FakeClock()
        ..advance(const Duration(seconds: 10))
        ..wallClock = DateTime.utc(2030);

      expect(clock.monotonic(), const Duration(seconds: 10));
      expect(clock.now().year, 2030);
    });
  });
}

/// `intl` usa espacios finos o sin separación antes de AM/PM.
String _plain(String text) => text.replaceAll(RegExp(r'\s'), ' ');
