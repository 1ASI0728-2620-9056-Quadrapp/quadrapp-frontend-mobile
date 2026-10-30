import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_level_summary.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_zone_summary.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/watch_lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/level_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_realtime.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import 'support.dart';

class _MockReader extends Mock implements OccupancyReader {}

class _MockRealtime extends Mock implements OccupancyRealtime {}

void main() {
  const lotId = LotId(1);

  group('GetLotOccupancy', () {
    test('devuelve la ocupación del lector', () async {
      final reader = _MockReader();
      final occupancy = sampleOccupancy();
      when(
        () => reader.read(lotId),
      ).thenAnswer((_) async => Success(occupancy));

      final result = await GetLotOccupancy(reader)(lotId);

      expect(result, Success(occupancy));
      verify(() => reader.read(lotId)).called(1);
    });

    test('propaga la falla', () async {
      final reader = _MockReader();
      when(() => reader.read(lotId)).thenAnswer(
        (_) async => const Err<LotOccupancy>(NotFoundFailure()),
      );

      final result = await GetLotOccupancy(reader)(lotId);

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  test('WatchLotOccupancy delega en el tiempo real', () async {
    final realtime = _MockRealtime();
    final occupancy = sampleOccupancy();
    when(() => realtime.watch(lotId)).thenAnswer(
      (_) => Stream.value(Success(occupancy)),
    );

    final results = await WatchLotOccupancy(realtime)(lotId).toList();

    expect(results, [Success(occupancy)]);
  });

  group('GetZoneSummary', () {
    test('cuenta por zona sin contar los desconocidos como libres', () {
      final summary = const GetZoneSummary()(
        GetZoneSummaryParams(
          occupancy: sampleOccupancy(),
          membership: const {
            ZoneId(10): [SpaceId(1), SpaceId(2)],
            ZoneId(11): [SpaceId(3), SpaceId(4)],
          },
        ),
      );

      expect(summary, const [
        ZoneOccupancy(zoneId: ZoneId(10), free: 1, occupied: 1, unknown: 0),
        ZoneOccupancy(zoneId: ZoneId(11), free: 0, occupied: 1, unknown: 1),
      ]);
    });
  });

  group('GetLevelSummary', () {
    test('cuenta por nivel; un espacio sin estado cuenta como desconocido', () {
      final summary = const GetLevelSummary()(
        GetLevelSummaryParams(
          occupancy: sampleOccupancy(),
          membership: const {
            LevelId(100): [SpaceId(1), SpaceId(2)],
            // El espacio 99 no tiene estado: nunca es libre.
            LevelId(101): [SpaceId(3), SpaceId(4), SpaceId(99)],
          },
        ),
      );

      expect(summary, const [
        LevelOccupancy(levelId: LevelId(100), free: 1, occupied: 1, unknown: 0),
        LevelOccupancy(levelId: LevelId(101), free: 0, occupied: 1, unknown: 2),
      ]);
    });
  });
}
