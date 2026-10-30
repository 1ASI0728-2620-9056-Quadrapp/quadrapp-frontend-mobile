import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/parking_configuration/mock_parking_configuration_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_prediction_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/request_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/arrival_category.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/mappers/prediction_mapper.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/repositories/prediction_repositories.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';
import '../../helpers/test_seed.dart';

class Suite {
  Suite(this.world, this.logger, this.clock)
    : mapper = PredictionMapper(logger) {
    forecasts = GetLotForecasts(
      ForecastReaderImpl(
        remote: MockForecastRemoteDataSource(world),
        mapper: mapper,
        clock: clock,
      ),
    );
    advice = RequestArrivalAdvice(
      ArrivalAdviceRequesterImpl(
        remote: MockArrivalAdviceRemoteDataSource(world),
        mapper: mapper,
        clock: clock,
      ),
    );
    nextAvailabilityRemote = MockNextAvailabilityRemoteDataSource(world);
    nextAvailability = GetNextAvailability(
      NextAvailabilityReaderImpl(
        remote: nextAvailabilityRemote,
        mapper: mapper,
      ),
    );
  }

  final MockWorld world;
  final RecordingLogger logger;
  final FakeClock clock;
  final PredictionMapper mapper;
  late final GetLotForecasts forecasts;
  late final RequestArrivalAdvice advice;
  late final MockNextAvailabilityRemoteDataSource nextAvailabilityRemote;
  late final GetNextAvailability nextAvailability;
}

Suite newSuite({MockControls? controls}) {
  final clock = FakeClock();
  final world = MockWorld(
    seed: testSeed,
    clock: clock,
    controls: controls,
    random: Random(1),
    latency: false,
  );
  return Suite(world, RecordingLogger(), clock);
}

void main() {
  group('mocks de prediction_advisory', () {
    test(
      'los 4 horizontes salen en el formato de docs/07, sin avisos',
      () async {
        final suite = newSuite();

        final result = await suite.forecasts(const LotId(1));

        final forecasts = result.valueOrNull!;
        expect(
          forecasts.forecasts.map((f) => f.horizon),
          ForecastHorizon.values,
        );
        expect(forecasts.isPartial(suite.clock), isFalse);
        expect(suite.logger.messages, isEmpty);
      },
    );

    test('un horizonte faltante responde 404 y queda como faltante', () async {
      final controls = MockControls()..missingForecastHorizons = {30};
      final suite = newSuite(controls: controls);

      final forecasts = (await suite.forecasts(const LotId(1))).valueOrNull!;

      final slots = forecasts.slots(suite.clock);
      expect(slots[1].status, ForecastSlotStatus.missing);
      expect(slots[0].status, ForecastSlotStatus.available);
    });

    test('un error de red forzado falla igual que el real', () async {
      final controls = MockControls()..forceNetworkError = true;
      final suite = newSuite(controls: controls);

      final result = await suite.forecasts(const LotId(1));

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('el servidor rechaza un ETA fuera de 0..120 con 400', () async {
      final suite = newSuite();
      final remote = MockArrivalAdviceRemoteDataSource(suite.world);

      await expectLater(
        remote.request(
          const ArrivalAdviceRequestDto(lotId: 1, etaMinutes: 121),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            400,
          ),
        ),
      );
    });

    test('horizonUsed es el horizonte más cercano al ETA', () async {
      final suite = newSuite();
      final expected = {0: 15, 22: 15, 23: 30, 38: 45, 52: 45, 53: 60, 120: 60};

      for (final MapEntry(key: eta, value: horizon) in expected.entries) {
        final advice = (await suite.advice(
          RequestArrivalAdviceParams(lotId: const LotId(1), etaMinutes: eta),
        )).valueOrNull!;
        expect(advice.horizonUsed?.minutes, horizon, reason: 'ETA $eta');
      }
    });
  });

  group('coherencia entre contextos (solo por identificadores)', () {
    test('los ids de los lotes coinciden con parking_configuration', () async {
      final suite = newSuite();
      final lots = await MockParkingLotRemoteDataSource(suite.world).list();

      for (final lot in lots) {
        // Cada lote de la configuración responde pronóstico y asesoría.
        final result = await suite.advice(
          RequestArrivalAdviceParams(lotId: LotId(lot.id), etaMinutes: 20),
        );
        expect(result.isSuccess, isTrue, reason: 'lote ${lot.id}');
      }
      expect(lots.map((l) => l.id), [1, 2, 3, 4]);
    });

    test(
      'lote casi lleno: sin libres en occupancy ⇒ saturación y US36',
      () async {
        final suite = newSuite();
        final occupancy = await MockOccupancyRemoteDataSource(
          suite.world,
        ).fetch(const LotId(2));
        expect(occupancy.free, 0);

        final forecasts = (await suite.forecasts(const LotId(2))).valueOrNull!;
        expect(forecasts.forecasts.every((f) => f.saturation != null), isTrue);
        expect(
          forecasts.forecasts.every(
            (f) =>
                f.expectedOccupancyPct >=
                occupancy.occupied / occupancy.capacity * 100,
          ),
          isTrue,
        );

        final next = await suite.nextAvailability(
          const GetNextAvailabilityParams(
            lotId: LotId(2),
            hasFreeSpaces: false,
          ),
        );
        expect(
          next.valueOrNull,
          isA<NextAvailabilityEstimate>()
              .having((e) => e.minMinutes, 'min', 8)
              .having((e) => e.maxMinutes, 'max', 15),
        );
        final advice = (await suite.advice(
          const RequestArrivalAdviceParams(lotId: LotId(2), etaMinutes: 15),
        )).valueOrNull!;
        expect(advice.category, ArrivalCategory.low);
      },
    );

    test('lote casi lleno sin salidas: NO_EXITS sin estimación', () async {
      final controls = MockControls()..nextAvailabilityNoExits = true;
      final suite = newSuite(controls: controls);

      final next = await suite.nextAvailability(
        const GetNextAvailabilityParams(lotId: LotId(2), hasFreeSpaces: false),
      );

      expect(next.valueOrNull, isA<NextAvailabilityNoEstimate>());
    });

    test(
      'lote con libres: sin saturación y US36 no aplica sin llamar',
      () async {
        final suite = newSuite();
        final occupancy = await MockOccupancyRemoteDataSource(
          suite.world,
        ).fetch(const LotId(1));
        expect(occupancy.free, greaterThan(0));

        final forecasts = (await suite.forecasts(const LotId(1))).valueOrNull!;
        expect(forecasts.forecasts.every((f) => f.saturation == null), isTrue);

        final next = await suite.nextAvailability(
          GetNextAvailabilityParams(
            lotId: const LotId(1),
            hasFreeSpaces: occupancy.free > 0,
          ),
        );
        expect(next.valueOrNull, isA<NextAvailabilityNotApplicable>());

        // Si la app preguntara igual, el servidor respondería lo mismo.
        final raw = await suite.nextAvailabilityRemote.fetch(const LotId(1));
        expect(raw.reason, 'HAS_FREE_SPACES');
      },
    );

    test('historial insuficiente: FALLBACK con confianza LOW', () async {
      final suite = newSuite();

      final forecasts = (await suite.forecasts(const LotId(3))).valueOrNull!;

      expect(forecasts.forecasts, hasLength(4));
      for (final forecast in forecasts.forecasts) {
        expect(forecast.method, ForecastMethod.fallback);
        expect(forecast.confidence.level, ConfidenceLevel.low);
        expect(forecast.isLowConfidence, isTrue);
      }
      final advice = (await suite.advice(
        const RequestArrivalAdviceParams(lotId: LotId(3), etaMinutes: 20),
      )).valueOrNull!;
      expect(advice.isLowConfidence, isTrue);
    });

    test('la vigencia sale del reloj del servidor, no del teléfono', () async {
      final controls = MockControls()
        ..phoneClockSkew = const Duration(hours: 5);
      final suite = newSuite(controls: controls);

      final forecasts = (await suite.forecasts(const LotId(1))).valueOrNull!;

      // generatedAt = hace 2 min, vigencia 15 min ⇒ quedan 13 min.
      expect(
        forecasts.forecasts.first.validity.remaining(suite.clock),
        const Duration(minutes: 13),
      );
    });
  });
}
