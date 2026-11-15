import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/parking_configuration/mock_parking_configuration_datasources.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_zone_summary.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/mappers/occupancy_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/parking_configuration_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/lot_layout_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/parking_lot_reader_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

MockWorld newWorld({MockControls? controls}) => MockWorld(
  seed: testSeed,
  clock: FakeClock(),
  controls: controls,
  random: Random(1),
  latency: false,
);

void main() {
  group('mocks de parking_configuration', () {
    test(
      'GET /parking-lots: 4 estacionamientos con el formato de docs/07',
      () async {
        final world = newWorld();

        final lots = await MockParkingLotRemoteDataSource(world).list();

        expect(lots.map((l) => l.id), [1, 2, 3, 4]);
        expect(lots.map((l) => l.layoutVersion).toList(), [4, 2, 0, 3]);
        // El lote 3 no tiene coordenadas: solo ETA manual.
        expect(lots.where((l) => l.latitude == null).map((l) => l.id), [3]);
        expect(lots.map((l) => l.saturationThresholdPct), [90, 90, 90, 85]);
        expect(
          mockParkingLotJson(world.lots.first).keys,
          containsAll([
            'id',
            'name',
            'address',
            'latitude',
            'longitude',
            'layoutVersion',
            'staleAfterSeconds',
            'saturationThresholdPct',
          ]),
        );
      },
    );

    test('GET /parking-lots/{id}: 404 si no existe', () async {
      final source = MockParkingLotRemoteDataSource(newWorld());

      expect((await source.get(const LotId(2))).name, 'San Isidro');
      await expectLater(
        source.get(const LotId(99)),
        throwsA(anything),
      );
    });

    test('layout: sin distribución publicada responde 404', () async {
      final source = MockLotLayoutRemoteDataSource(newWorld());

      await expectLater(source.fetch(const LotId(3)), throwsA(anything));
    });

    test('layout: con la versión vigente responde 304; con otra, la '
        'distribución', () async {
      final source = MockLotLayoutRemoteDataSource(newWorld());

      expect(
        await source.fetch(const LotId(1), knownVersion: 4),
        isA<LayoutNotModified>(),
      );
      final fetched = await source.fetch(const LotId(1), knownVersion: 3);
      expect((fetched as LayoutFetched).dto.version, 4);
      expect(
        (await source.fetch(const LotId(1)) as LayoutFetched).dto.zones,
        hasLength(3),
      );
    });

    test('layout: el JSON tiene el formato de docs/07, con posiciones '
        'únicas', () async {
      final world = newWorld();
      final json = mockLayoutJson(world.lot(1)!);

      final dto = LotLayoutDto.fromJson(json);

      expect(json.keys, ['version', 'zones']);
      // Cada nivel es su propio plano: las posiciones son únicas por nivel.
      for (final zone in dto.zones) {
        for (final level in zone.levels) {
          final positions = {
            for (final s in level.spaces) '${s.posX},${s.posY}',
          };
          expect(positions.length, level.spaces.length, reason: level.name);
        }
      }
      expect(dto.zones.first.levels.first.spaces.first.label, 'A-01');
      expect(dto.zones.first.description, 'Edificios A–C');
    });

    test('un ciclo completo con el repositorio real: primero 200, luego 304 '
        'desde la caché', () async {
      final world = newWorld();
      final store = InMemoryKeyValueStore();
      final remote = _CountingLayoutSource(
        MockLotLayoutRemoteDataSource(world),
      );
      final reader = LotLayoutReaderImpl(
        remote: remote,
        cache: LotLayoutCacheDataSource(store),
      );

      final first = await reader.read(const LotId(1));
      final second = await reader.read(const LotId(1));

      expect(first.valueOrNull, second.valueOrNull);
      expect(remote.fetches.map((f) => f.runtimeType), [
        LayoutFetched,
        LayoutNotModified,
      ]);
    });

    test('los repositorios reales sobre los mocks convierten los errores '
        'forzados en Failure', () async {
      final controls = MockControls()..forceNetworkError = true;
      final world = newWorld(controls: controls);
      final reader = ParkingLotReaderImpl(
        remote: MockParkingLotRemoteDataSource(world),
      );

      expect((await reader.list()).failureOrNull, isA<NetworkFailure>());

      controls
        ..forceNetworkError = false
        ..force401 = true;
      expect((await reader.list()).failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('coherencia entre occupancy y parking_configuration (solo por '
      'identificadores)', () {
    for (final lotId in [1, 2]) {
      test('estacionamiento $lotId: los espacios y zonas de la ocupación son '
          'los del layout, y el conteo por zona coincide', () async {
        final world = newWorld();
        final layoutDto =
            (await MockLotLayoutRemoteDataSource(world).fetch(LotId(lotId))
                    as LayoutFetched)
                .dto;
        final layout = const ParkingConfigurationMapper().toLayout(
          layoutDto,
          LotId(lotId),
        );
        final occupancyDto = await MockOccupancyRemoteDataSource(world).fetch(
          LotId(lotId),
        );
        final occupancy = const OccupancyMapper(NoopLogger()).toEntity(
          occupancyDto,
          LotId(lotId),
        );

        // Mismos espacios.
        expect(
          occupancy.spaces.map((s) => s.id.value).toSet(),
          layout.zones.expand((z) => z.spaces).map((s) => s.id.value).toSet(),
        );
        // El conteo por zona calculado con el layout coincide con el del
        // servidor.
        final computed = const GetZoneSummary()(
          GetZoneSummaryParams(
            occupancy: occupancy,
            membership: layout.membership,
          ),
        );
        expect(computed, occupancy.zones);
        // Y los totales cuadran con la capacidad.
        expect(occupancy.capacity, layout.spaceCount);
        expect(
          occupancy.free + occupancy.occupied + occupancy.unknown,
          occupancy.capacity,
        );
      });
    }

    test('el estacionamiento casi lleno no tiene libres y no cuenta el '
        'desconocido como libre', () async {
      final world = newWorld();
      final dto = await MockOccupancyRemoteDataSource(world).fetch(
        const LotId(2),
      );
      final occupancy = const OccupancyMapper(NoopLogger()).toEntity(
        dto,
        const LotId(2),
      );

      expect(occupancy.isFull, isTrue);
      expect(occupancy.unknown, 2);
      expect(
        occupancy.spaces.where((s) => s.status == SpaceStatus.free),
        isEmpty,
      );
    });

    test('el estacionamiento sin layout no tiene ocupación (404)', () async {
      final world = newWorld();

      await expectLater(
        MockOccupancyRemoteDataSource(world).fetch(const LotId(3)),
        throwsA(anything),
      );
      expect(
        ParkingLotDto.fromJson(mockParkingLotJson(world.lot(3)!)).layoutVersion,
        0,
      );
    });
  });
}

class _CountingLayoutSource implements LotLayoutRemoteDataSource {
  _CountingLayoutSource(this._inner);

  final LotLayoutRemoteDataSource _inner;
  final List<LayoutFetch> fetches = [];

  @override
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion}) async {
    final result = await _inner.fetch(lotId, knownVersion: knownVersion);
    fetches.add(result);
    return result;
  }
}
