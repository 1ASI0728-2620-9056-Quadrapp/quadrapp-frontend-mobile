// US06, US07, US08: Zonas en cada estado.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import 'support.dart';

class _MockLayout extends Mock implements GetLotLayout {}

class _MockOccupancy extends Mock implements GetLotOccupancy {}

class _MockWatch extends Mock implements WatchLotFeed {}

void main() {
  late _MockLayout getLayout;
  late _MockOccupancy getOccupancy;
  late _MockWatch watch;
  late StreamController<OccupancyFeedEvent> feed;

  setUpAll(() => registerFallbackValue(const LotId(1)));

  setUp(() {
    getLayout = _MockLayout();
    getOccupancy = _MockOccupancy();
    watch = _MockWatch();
    feed = StreamController<OccupancyFeedEvent>.broadcast();
    when(() => getLayout(any())).thenAnswer((_) async => Success(layout()));
    when(
      () => getOccupancy(any()),
    ).thenAnswer((_) async => Success(occupancy()));
    when(() => watch(any())).thenAnswer((_) => feed.stream);
  });

  tearDown(() => feed.close());

  ZonesCubit cubit() => ZonesCubit(
    getLotLayout: getLayout,
    getLotOccupancy: getOccupancy,
    watchLotFeed: watch,
    getZoneSummary: const GetZoneSummary(),
    getLevelSummary: const GetLevelSummary(),
  );

  ZonesOverview dataOf(ZonesCubit c) => switch (c.state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    final other => fail('se esperaba contenido y hay $other'),
  };

  test('sin sede elegida no hay nada que cargar', () async {
    final c = cubit();
    await c.setLot(null);

    expect(c.state, isA<ViewInitial<ZonesOverview>>());
    verifyNever(() => getLayout(any()));
    await c.close();
  });

  test(
    'una sede sin distribución publicada no pide nada (US04 esc. 2)',
    () async {
      final c = cubit();
      await c.setLot(lot(layoutVersion: 0));

      final data = dataOf(c);
      expect(data.hasNoData, isTrue);
      expect(data.layout, isNull);
      verifyNever(() => getLayout(any()));
      verifyNever(() => getOccupancy(any()));
      verifyNever(() => watch(any()));
      await c.close();
    },
  );

  test(
    'carga la distribución y cuenta por pabellón y por nivel (US06)',
    () async {
      final c = cubit();
      await c.setLot(lot());

      expect(c.state, isA<ViewData<ZonesOverview>>());
      final data = dataOf(c);
      expect(
        data.countsOfZone(const ZoneId(11)),
        const AreaCounts(free: 3, occupied: 2, unknown: 1),
      );
      expect(
        data.countsOfZone(const ZoneId(12)),
        const AreaCounts(free: 0, occupied: 2, unknown: 0),
      );
      expect(
        data.countsOfLevel(const LevelId(111)),
        const AreaCounts(free: 1, occupied: 2, unknown: 1),
      );
      expect(
        data.countsOfLevel(const LevelId(112)),
        const AreaCounts(free: 2, occupied: 0, unknown: 0),
      );
      expect(
        data.lotCounts,
        const AreaCounts(free: 3, occupied: 4, unknown: 1),
      );
      await c.close();
    },
  );

  test(
    'un espacio sin estado cuenta como sin datos, nunca como libre (US08)',
    () async {
      // El espacio 6 no llega en la ocupación.
      when(() => getOccupancy(any())).thenAnswer(
        (_) async => Success(
          occupancy(
            spaces: [
              state(1, SpaceStatus.free),
              state(2, SpaceStatus.occupied),
              state(3, SpaceStatus.occupied),
              state(4, SpaceStatus.occupied),
              state(5, SpaceStatus.free),
              state(7, SpaceStatus.occupied),
              state(8, SpaceStatus.occupied),
            ],
          ),
        ),
      );
      final c = cubit();
      await c.setLot(lot());

      expect(
        dataOf(c).countsOfLevel(const LevelId(112)),
        const AreaCounts(free: 1, occupied: 0, unknown: 1),
      );
      await c.close();
    },
  );

  test('sin la ocupación: parcial, con la estructura y sin conteos', () async {
    when(
      () => getOccupancy(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = cubit();
    await c.setLot(lot());

    final state = c.state as ViewPartial<ZonesOverview>;
    expect(state.missing, {'occupancy'});
    expect(state.data.layout, isNotNull);
    expect(state.data.countsOfZone(const ZoneId(11)), isNull);
    // Sin ocupación no se observa en vivo.
    verifyNever(() => watch(any()));
    await c.close();
  });

  test('sin la distribución: parcial, con los totales de la sede', () async {
    when(
      () => getLayout(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = cubit();
    await c.setLot(lot());

    final state = c.state as ViewPartial<ZonesOverview>;
    expect(state.missing, {'layout'});
    expect(state.data.lotCounts, isNotNull);
    expect(state.data.zoneCounts, isEmpty);
    await c.close();
  });

  test('si falla todo, error recuperable; al reintentar se recupera', () async {
    when(
      () => getLayout(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    when(
      () => getOccupancy(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = cubit();
    await c.setLot(lot());

    expect(c.state, isA<ViewError<ZonesOverview>>());
    expect(
      (c.state as ViewError<ZonesOverview>).failure,
      isA<NetworkFailure>(),
    );

    when(() => getLayout(any())).thenAnswer((_) async => Success(layout()));
    when(
      () => getOccupancy(any()),
    ).thenAnswer((_) async => Success(occupancy()));
    await c.load();

    expect(c.state, isA<ViewData<ZonesOverview>>());
    await c.close();
  });

  test('al recargar conserva lo que ya se veía', () async {
    final c = cubit();
    await c.setLot(lot());
    final before = dataOf(c);

    final states = <ViewState<ZonesOverview>>[];
    final sub = c.stream.listen(states.add);
    await c.refresh();
    await sub.cancel();

    expect((states.first as ViewLoading<ZonesOverview>).previous, before);
    await c.close();
  });

  test('con la caché, los conteos salen como sin conexión', () async {
    when(() => getOccupancy(any())).thenAnswer(
      (_) async => Success(occupancy(source: OccupancySource.cache)),
    );
    final c = cubit();
    await c.setLot(lot());

    expect((c.state as ViewData<ZonesOverview>).offline, isTrue);
    await c.close();
  });

  test('un cambio en vivo recalcula los conteos (US07)', () async {
    final c = cubit();
    await c.setLot(lot());
    expect(dataOf(c).countsOfLevel(const LevelId(112))?.free, 2);

    feed.add(
      OccupancyReceived(
        Success(
          occupancy(
            spaces: [
              state(1, SpaceStatus.free),
              state(2, SpaceStatus.occupied),
              state(3, SpaceStatus.occupied),
              state(4, SpaceStatus.occupied),
              state(5, SpaceStatus.occupied),
              state(6, SpaceStatus.free),
              state(7, SpaceStatus.occupied),
              state(8, SpaceStatus.occupied),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final data = dataOf(c);
    expect(
      data.countsOfLevel(const LevelId(112)),
      const AreaCounts(free: 1, occupied: 1, unknown: 0),
    );
    expect(data.countsOfZone(const ZoneId(11))?.unknown, 0);
    await c.close();
  });

  test(
    'informa la conexión real y un fallo en vivo no tumba lo visto',
    () async {
      final c = cubit();
      await c.setLot(lot());

      feed.add(const LinkChanged(RealtimeLink.reconnecting));
      await Future<void>.delayed(Duration.zero);
      expect(dataOf(c).link, RealtimeLink.reconnecting);

      final before = dataOf(c).occupancy;
      feed.add(const OccupancyReceived(Err(NetworkFailure())));
      await Future<void>.delayed(Duration.zero);
      expect(dataOf(c).occupancy, before);
      await c.close();
    },
  );

  test('otra sede carga de nuevo; la misma no', () async {
    final c = cubit();
    await c.setLot(lot());
    await c.setLot(lot());
    verify(() => getLayout(any())).called(1);

    await c.setLot(lot(id: 2));
    verify(() => getLayout(any())).called(1);
    expect(dataOf(c).lot.id, const LotId(2));
    await c.close();
  });
}
