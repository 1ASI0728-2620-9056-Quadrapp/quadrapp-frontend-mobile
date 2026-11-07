import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_json.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

MockWorld newWorld({MockControls? controls, int seed = 1}) => MockWorld(
  seed: testSeed,
  clock: FakeClock(),
  controls: controls,
  random: Random(seed),
  latency: false,
);

void main() {
  group('MockWorld', () {
    test(
      'tiene 4 estacionamientos: normal, casi lleno, sin layout y vencido',
      () {
        final world = newWorld();

        expect(world.lots.map((l) => l.id), [1, 2, 3, 4]);
        // Monterrico: 120 espacios en 3 pabellones, ~60 % ocupado, 3 sin datos.
        final a = world.lot(1)!;
        expect(a.capacity, 120);
        expect(a.zones, hasLength(3));
        expect(a.count('OCCUPIED'), 72);
        expect(a.count('UNKNOWN'), 3);
        expect(
          a.spaces
              .where((s) => s.status == 'UNKNOWN')
              .map((s) => s.unknownReason),
          unorderedEquals(['LOW_BATTERY', 'NO_HEARTBEAT', 'NO_SENSOR']),
        );
        // San Isidro, casi lleno: sin libres (US36) y con dos sin datos.
        final b = world.lot(2)!;
        expect(b.capacity, 80);
        expect(b.zones, hasLength(2));
        expect(b.count('FREE'), 0);
        expect(b.count('OCCUPIED'), 78);
        expect(b.count('UNKNOWN'), 2);
        expect(b.isSaturated, isTrue);
        expect(a.isSaturated, isFalse);
        // Sin distribución publicada (US04 esc. 2) y sin historial.
        expect(world.lot(3)!.hasLayout, isFalse);
        expect(world.lot(3)!.insufficientHistory, isTrue);
        // Villa: 150 espacios en 4 pabellones, ~25 % ocupado.
        final d = world.lot(4)!;
        expect(d.capacity, 150);
        expect(d.zones, hasLength(4));
        expect(d.count('OCCUPIED'), 37);
      },
    );

    test('el dato de cada lote tiene la antigüedad de la semilla y solo el '
        'lote 4 está vencido', () {
      final clock = FakeClock();
      final world = MockWorld(seed: testSeed, clock: clock, latency: false);

      Duration age(int id) =>
          clock.now().difference(world.lot(id)!.consolidatedAt);
      expect(age(1), const Duration(seconds: 20));
      expect(
        age(4),
        greaterThan(Duration(seconds: world.lot(4)!.staleAfterSeconds)),
      );
      expect(
        age(1),
        lessThan(Duration(seconds: world.lot(1)!.staleAfterSeconds)),
      );
    });

    test('el simulador nunca toca al lote con el dato vencido', () {
      final world = newWorld(seed: 5);
      final before = world.lot(4)!.consolidatedAt;

      for (var i = 0; i < 300; i++) {
        world.tick();
      }

      expect(world.lot(4)!.consolidatedAt, before);
    });

    test('reset vuelve a la semilla y conserva las sesiones y los tokens', () {
      final world = newWorld(seed: 5);
      world.iam.refreshTokens.add('r-1');
      world.notifications.deviceTokens.add('t-1');
      for (var i = 0; i < 100; i++) {
        world.tick();
      }
      world.notifications.subscriptions.clear();

      world.reset();

      expect(world.lot(1)!.count('OCCUPIED'), 72);
      expect(world.notifications.subscriptions, hasLength(3));
      expect(world.iam.refreshTokens, {'r-1'});
      expect(world.notifications.deviceTokens, {'t-1'});
    });

    test('cada lote con layout tiene coordenadas para el ETA y posiciones '
        'únicas para el mapa', () {
      final world = newWorld();

      for (final lot in world.lots) {
        if (lot.hasLayout) {
          expect(lot.latitude, inInclusiveRange(-90, 90));
          expect(lot.longitude, inInclusiveRange(-180, 180));
        }
        // Cada nivel es su propio plano: las posiciones son únicas por nivel.
        for (final level in lot.levels) {
          final positions = {
            for (final s in level.spaces) '${s.posX},${s.posY}',
          };
          expect(positions.length, level.spaces.length, reason: level.name);
        }
        expect(lot.spaces.map((s) => s.id).toSet().length, lot.capacity);
      }
    });

    test('tick cambia un espacio y emite el evento con el formato del '
        'WebSocket', () async {
      final world = newWorld(seed: 3);
      final future = world.events.first;

      MockSpaceEvent? event;
      for (var i = 0; i < 200 && event == null; i++) {
        event = world.tick();
      }

      expect(event, isNotNull);
      expect(await future, isNotNull);
      expect(event!.toJson().keys, ['eventId', 'spaceId', 'status', 'at']);
      expect(
        world.lot(event.lotId)!.consolidatedAt,
        event.at,
      );
    });

    test('un sensor puede pasar a UNKNOWN por batería baja', () {
      final world = newWorld();
      final lot = world.lot(1)!;
      final space = lot.spaces.first;

      world.setSpaceStatus(lot, space, 'UNKNOWN', reason: 'LOW_BATTERY');

      expect(space.status, 'UNKNOWN');
      expect(space.unknownReason, 'LOW_BATTERY');
    });
  });

  group('gate: interruptores', () {
    test('sin interruptores no falla', () async {
      await newWorld().gate();
    });

    test('red caída -> NetworkFailure', () async {
      final controls = MockControls()..forceNetworkError = true;

      final result = await guardResult(
        () => newWorld(controls: controls).gate(),
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('401 forzado solo en llamadas autenticadas', () async {
      final controls = MockControls()..force401 = true;
      final world = newWorld(controls: controls);

      final authed = await guardResult(world.gate);
      final auth = await guardResult(() => world.gate(isAuth: true));

      expect(authed.failureOrNull, isA<UnauthorizedFailure>());
      expect(auth.isSuccess, isTrue);
    });

    test('429 forzado en /auth con retryAfter', () async {
      final controls = MockControls()..force429 = true;
      final world = newWorld(controls: controls);

      final result = await guardResult(() => world.gate(isAuth: true));

      final failure = result.failureOrNull! as RateLimitedFailure;
      expect(failure.retryAfter, const Duration(seconds: 45));
      expect((await guardResult(world.gate)).isSuccess, isTrue);
    });

    test('el reloj del teléfono se desfasa sin tocar el monótono', () {
      final controls = MockControls()
        ..phoneClockSkew = const Duration(hours: 3);
      final base = FakeClock();
      final phone = MockPhoneClock(base, controls);

      expect(phone.now(), base.now().add(const Duration(hours: 3)));
      expect(phone.monotonic(), base.monotonic());
    });
  });

  group('mocks de ocupación', () {
    test(
      'el JSON respeta el formato de docs/07 y se lee con el DTO real',
      () async {
        final world = newWorld();
        final lot = world.lot(1)!;

        final json = mockOccupancyJson(world, lot);
        final dto = LotOccupancyDto.fromJson(json);

        expect(
          json.keys,
          containsAll([
            'capacity',
            'free',
            'occupied',
            'unknown',
            'consolidatedAt',
            'serverTime',
            'staleAfterSeconds',
            'stale',
            'zones',
            'spaces',
          ]),
        );
        expect(dto.capacity, lot.capacity);
        expect(dto.free + dto.occupied + dto.unknown, dto.capacity);
        expect(dto.spaces, hasLength(lot.capacity));
        expect(
          mockOccupancyJson(world, lot, detailed: false).containsKey('zones'),
          isFalse,
        );
      },
    );

    test('un estacionamiento sin layout responde 404', () async {
      final source = MockOccupancyRemoteDataSource(newWorld());

      final result = await guardResult(() => source.fetch(const LotId(3)));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('marca la ocupación como desactualizada pasado el umbral', () {
      final clock = FakeClock();
      final world = MockWorld(seed: testSeed, clock: clock, latency: false);
      clock.advance(const Duration(seconds: 200));

      final json = mockOccupancyJson(world, world.lot(1)!);

      expect(json['stale'], isTrue);
    });

    test('el tiempo real emite Connected y luego los cambios de ese '
        'estacionamiento', () async {
      final world = newWorld();
      final events = <OccupancyRealtimeEvent>[];
      final sub = MockOccupancyRealtimeDataSource(
        world,
      ).connect(const LotId(1)).listen(events.add);
      await pumpEventQueue();

      final lot = world.lot(1)!;
      world
        ..setSpaceStatus(lot, lot.spaces.first, 'OCCUPIED')
        ..setSpaceStatus(world.lot(2)!, world.lot(2)!.spaces.first, 'FREE');
      await pumpEventQueue();

      expect(events.first, isA<RealtimeConnected>());
      expect(events.whereType<RealtimeChange>(), hasLength(1));
      await sub.cancel();
    });

    test('los errores forzados llegan como los del backend real', () async {
      final controls = MockControls()..forceNetworkError = true;
      final source = MockOccupancyRemoteDataSource(
        newWorld(controls: controls),
      );

      await expectLater(
        source.fetch(const LotId(1)),
        throwsA(isA<DioException>()),
      );
    });
  });
}
