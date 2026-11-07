import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_change.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_counter.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_reducer.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/freshness.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

SpaceChange change(
  String eventId,
  int spaceId,
  SpaceStatus status,
  DateTime at,
) => SpaceChange(
  eventId: eventId,
  spaceId: SpaceId(spaceId),
  status: status,
  at: at,
);

void main() {
  group('OccupancyCounter', () {
    const counter = OccupancyCounter();

    test('cuenta libres, ocupados y desconocidos; el desconocido nunca es '
        'libre', () {
      final counts = counter.count([
        space(1, SpaceStatus.free),
        space(2, SpaceStatus.unknown),
        space(3, SpaceStatus.unknown),
        space(4, SpaceStatus.occupied),
      ]);

      expect(counts.free, 1);
      expect(counts.occupied, 1);
      expect(counts.unknown, 2);
      expect(counts.total, 4);
    });

    test('por zona: un espacio sin estado cuenta como desconocido, no como '
        'libre', () {
      final zones = counter.byZone(
        [space(1, SpaceStatus.free), space(2, SpaceStatus.occupied)],
        {
          const ZoneId(10): [const SpaceId(1), const SpaceId(2)],
          const ZoneId(11): [const SpaceId(3), const SpaceId(99)],
        },
      );

      expect(zones, const [
        ZoneOccupancy(zoneId: ZoneId(10), free: 1, occupied: 1, unknown: 0),
        ZoneOccupancy(zoneId: ZoneId(11), free: 0, occupied: 0, unknown: 2),
      ]);
    });

    test('SpaceStatus.isAvailable solo es cierto para libre', () {
      expect(SpaceStatus.free.isAvailable, isTrue);
      expect(SpaceStatus.occupied.isAvailable, isFalse);
      expect(SpaceStatus.unknown.isAvailable, isFalse);
    });
  });

  group('Freshness', () {
    Freshness build({Duration? receivedAt, DateTime? storedAt}) => Freshness(
      consolidatedAt: t0,
      serverTime: t0.add(const Duration(seconds: 40)),
      staleAfter: const Duration(seconds: 180),
      receivedAt: receivedAt,
      storedAt: storedAt,
    );

    test('antigüedad = serverTime - consolidatedAt + tiempo local', () {
      final clock = FakeClock(t0)..advance(const Duration(seconds: 10));
      final freshness = build(receivedAt: Duration.zero);

      expect(freshness.age(clock), const Duration(seconds: 50));
    });

    test('un reloj del teléfono desfasado no altera la antigüedad', () {
      final clock = FakeClock(t0)
        ..advance(const Duration(seconds: 10))
        ..wallClock = DateTime.utc(2035);
      final freshness = build(receivedAt: Duration.zero);

      expect(freshness.age(clock), const Duration(seconds: 50));
    });

    test('desde la caché usa la hora local de guardado', () {
      final clock = FakeClock(t0.add(const Duration(minutes: 5)));
      final freshness = build(storedAt: t0);

      expect(freshness.age(clock), const Duration(minutes: 5, seconds: 40));
      expect(freshness.isStale(clock), isTrue);
    });

    test('isStale respeta el umbral', () {
      final clock = FakeClock(t0);
      final freshness = build(receivedAt: Duration.zero);

      expect(freshness.isStale(clock), isFalse);
      clock.advance(const Duration(seconds: 140));
      expect(freshness.age(clock), const Duration(seconds: 180));
      expect(freshness.isStale(clock), isFalse);
      clock.advance(const Duration(seconds: 1));
      expect(freshness.isStale(clock), isTrue);
    });

    test('las diferencias negativas valen cero', () {
      final clock = FakeClock(t0);
      final freshness = Freshness(
        consolidatedAt: t0,
        serverTime: t0.subtract(const Duration(seconds: 30)),
        staleAfter: const Duration(seconds: 180),
        receivedAt: const Duration(seconds: 100),
      );

      expect(freshness.age(clock), Duration.zero);
    });

    test('asCached ancla la antigüedad a la hora local de guardado', () {
      final cached = build(receivedAt: Duration.zero).asCached(t0);

      expect(cached.receivedAt, isNull);
      expect(cached.storedAt, t0);
    });
  });

  group('LotOccupancy', () {
    test('isFull: sin libres (los desconocidos no cuentan)', () {
      final full = sampleOccupancy().copyWith(free: 0);

      expect(full.isFull, isTrue);
      expect(sampleOccupancy().isFull, isFalse);
    });

    test('isFromCache', () {
      expect(sampleOccupancy().isFromCache, isFalse);
      expect(
        sampleOccupancy().copyWith(source: OccupancySource.cache).isFromCache,
        isTrue,
      );
    });
  });

  group('OccupancyReducer', () {
    late OccupancyReducer reducer;
    final at = t0.add(const Duration(seconds: 5));

    setUp(() => reducer = OccupancyReducer(sampleOccupancy()));

    test('aplica un cambio: actualiza el espacio, los conteos y la '
        'antigüedad', () {
      final next = reducer.apply(
        change('e1', 1, SpaceStatus.occupied, at),
        receivedAt: const Duration(seconds: 7),
      )!;

      expect(next.free, 0);
      expect(next.occupied, 3);
      expect(next.unknown, 1);
      expect(next.isFull, isTrue);
      expect(next.consolidatedAt, at);
      expect(next.freshness.receivedAt, const Duration(seconds: 7));
      expect(next.freshness.serverTime, at);
    });

    test('descarta un evento repetido (mismo eventId)', () {
      final first = change('e1', 1, SpaceStatus.occupied, at);
      reducer.apply(first, receivedAt: Duration.zero);

      expect(reducer.apply(first, receivedAt: Duration.zero), isNull);
    });

    test('descarta un evento anterior al último aplicado a ese espacio', () {
      reducer.apply(
        change('e1', 1, SpaceStatus.occupied, at),
        receivedAt: Duration.zero,
      );

      final late = reducer.apply(
        change(
          'e2',
          1,
          SpaceStatus.free,
          at.subtract(const Duration(seconds: 1)),
        ),
        receivedAt: Duration.zero,
      );

      expect(late, isNull);
      expect(reducer.current.spaces.first.status, SpaceStatus.occupied);
    });

    test('descarta un evento anterior al dato consolidado', () {
      final old = reducer.apply(
        change(
          'e1',
          1,
          SpaceStatus.occupied,
          t0.subtract(const Duration(seconds: 1)),
        ),
        receivedAt: Duration.zero,
      );

      expect(old, isNull);
    });

    test('un evento de otro espacio no se ve afectado por el orden del '
        'primero', () {
      reducer.apply(
        change('e1', 1, SpaceStatus.occupied, at),
        receivedAt: Duration.zero,
      );

      final other = reducer.apply(
        change('e2', 2, SpaceStatus.free, t0.add(const Duration(seconds: 1))),
        receivedAt: Duration.zero,
      );

      expect(other, isNotNull);
      expect(other!.free, 1);
    });

    test('descarta un cambio de un espacio que no está en la ocupación', () {
      expect(
        reducer.apply(
          change('e1', 99, SpaceStatus.free, at),
          receivedAt: Duration.zero,
        ),
        isNull,
      );
    });

    test('un espacio que pasa a desconocido deja de contar como libre', () {
      final next = reducer.apply(
        change('e1', 1, SpaceStatus.unknown, at),
        receivedAt: Duration.zero,
      )!;

      expect(next.free, 0);
      expect(next.unknown, 2);
    });

    test('recuerda solo los últimos maxRememberedEvents', () {
      final small = OccupancyReducer(sampleOccupancy(), maxRememberedEvents: 2);
      for (var i = 0; i < 3; i++) {
        small.apply(
          change(
            'e$i',
            1,
            i.isEven ? SpaceStatus.free : SpaceStatus.occupied,
            at.add(Duration(seconds: i)),
          ),
          receivedAt: Duration.zero,
        );
      }

      // e0 ya se olvidó: se aplica de nuevo (pero su hora es anterior a la
      // última del espacio, así que igual se descarta por orden).
      expect(
        small.apply(
          change('e0', 1, SpaceStatus.free, at),
          receivedAt: Duration.zero,
        ),
        isNull,
      );
      // e2 sigue recordado.
      expect(
        small.apply(
          change('e2', 1, SpaceStatus.free, at.add(const Duration(seconds: 9))),
          receivedAt: Duration.zero,
        ),
        isNull,
      );
    });
  });
}
