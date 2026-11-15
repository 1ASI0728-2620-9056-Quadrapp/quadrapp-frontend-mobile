// US29, TS17: el estado de operación del turno.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/composition/shift/get_shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_dto.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_reader_impl.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';

Map<String, dynamic> overviewJson({
  int free = 45,
  int occupied = 72,
  int unknown = 3,
  Object? flow = const {'entries': 12, 'exits': 9, 'windowMin': 15},
  Object? saturation,
  List<String> unavailable = const [],
  bool stale = false,
}) => {
  'lotId': 1,
  'capacity': free + occupied + unknown,
  'free': free,
  'occupied': occupied,
  'unknown': unknown,
  'flow': flow,
  'saturation': saturation,
  'consolidatedAt': '2026-09-28T13:41:40Z',
  'serverTime': '2026-09-28T13:42:00Z',
  'staleAfterSeconds': 180,
  'stale': stale,
  'unavailable': unavailable,
};

class _FakeRemote implements ShiftOverviewRemoteDataSource {
  Future<ShiftOverviewDto> Function() handler = () async =>
      ShiftOverviewDto.fromJson(overviewJson());

  @override
  Future<ShiftOverviewDto> fetch(LotId lotId) => handler();
}

class _MockReader extends Mock implements ShiftOverviewReader {}

void main() {
  late RecordingLogger logger;
  late ShiftOverviewMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = ShiftOverviewMapper(logger);
  });

  ShiftOverview map(Map<String, dynamic> json) => mapper.toEntity(
    ShiftOverviewDto.fromJson(json),
    receivedAt: const Duration(seconds: 2),
  );

  group('ShiftOverviewMapper', () {
    test('caso feliz: cifras, flujo y antigüedad con la hora del servidor', () {
      final overview = map(
        overviewJson(
          saturation: {'expectedAt': '2026-09-28T13:55:00Z', 'pct': 93.5},
        ),
      );

      expect(overview.lotId, const LotId(1));
      expect(
        [overview.capacity, overview.free, overview.occupied, overview.unknown],
        [120, 45, 72, 3],
      );
      expect(overview.flow?.entries, 12);
      expect(overview.flow?.exits, 9);
      expect(overview.flow?.window, const Duration(minutes: 15));
      expect(
        overview.saturation?.expectedAt,
        DateTime.utc(2026, 9, 28, 13, 55),
      );
      expect(overview.saturation?.pct, 93.5);
      expect(overview.unavailable, isEmpty);
      expect(overview.freshness.receivedAt, const Duration(seconds: 2));
      expect(
        overview.freshness.age(FakeClock()),
        const Duration(seconds: 20),
      );
      expect(logger.messages, isEmpty);
    });

    test('respuesta parcial: la saturación no disponible no es "no se '
        'prevé saturación" (TS17 esc. 3)', () {
      final partial = map(overviewJson(unavailable: ['saturation']));
      final none = map(overviewJson());

      expect(partial.saturationUnavailable, isTrue);
      expect(partial.saturation, isNull);
      expect(partial.free, 45, reason: 'el estado actual sigue llegando');
      expect(none.saturationUnavailable, isFalse);
      expect(none.saturation, isNull);
    });

    test('sin conteo de flujo, flow es null; si falta una sección en '
        'unavailable, también', () {
      expect(map(overviewJson(flow: null)).flow, isNull);
      final flowDown = map(overviewJson(unavailable: ['flow']));

      expect(flowDown.flow, isNull);
      expect(flowDown.flowUnavailable, isTrue);
    });

    test('una sección desconocida se ignora y deja un aviso', () {
      final overview = map(overviewJson(unavailable: ['weather']));

      expect(overview.unavailable, isEmpty);
      expect(logger.messages, hasLength(1));
    });

    test('el dato vencido se detecta con el umbral del estacionamiento', () {
      final clock = FakeClock();
      final overview = map(overviewJson());

      expect(overview.freshness.isStale(clock), isFalse);
      clock.advance(const Duration(minutes: 3));
      expect(overview.freshness.isStale(clock), isTrue);
    });
  });

  group('ShiftOverview.occupancyFraction', () {
    test(
      'es ocupados ÷ (libres + ocupados): los desconocidos quedan fuera',
      () {
        final overview = map(overviewJson());

        expect(overview.occupancyFraction, closeTo(72 / 117, 1e-9));
        // Con otros desconocidos la fracción no cambia.
        expect(
          map(
            overviewJson(unknown: 50),
          ).occupancyFraction,
          closeTo(72 / 117, 1e-9),
        );
      },
    );

    test('sin ningún espacio con dato no hay porcentaje', () {
      expect(
        map(overviewJson(free: 0, occupied: 0, unknown: 5)).occupancyFraction,
        isNull,
      );
      expect(
        map(overviewJson(free: 0, occupied: 78, unknown: 2)).occupancyFraction,
        1,
      );
    });
  });

  group('GetShiftOverview', () {
    test('devuelve el estado de operación del estacionamiento', () async {
      final reader = _MockReader();
      final overview = map(overviewJson());
      registerFallbackValue(const LotId(1));
      when(() => reader.read(any())).thenAnswer((_) async => Success(overview));

      final result = await GetShiftOverview(reader)(const LotId(1));

      expect(result.valueOrNull, overview);
      verify(() => reader.read(const LotId(1))).called(1);
    });
  });

  group('ShiftOverviewReaderImpl', () {
    late _FakeRemote remote;
    late ShiftOverviewReaderImpl reader;

    setUp(() {
      remote = _FakeRemote();
      reader = ShiftOverviewReaderImpl(
        remote: remote,
        mapper: mapper,
        clock: FakeClock()..advance(const Duration(seconds: 5)),
      );
    });

    test('lee con el reloj monótono al recibir', () async {
      final result = await reader.read(const LotId(1));

      expect(
        result.valueOrNull?.freshness.receivedAt,
        const Duration(seconds: 5),
      );
    });

    test('403 de un conductor: ForbiddenFailure; 404: NotFoundFailure; sin '
        'red: NetworkFailure', () async {
      remote.handler = () async => throw mockHttpError(403);
      expect(
        (await reader.read(const LotId(1))).failureOrNull,
        isA<ForbiddenFailure>(),
      );

      remote.handler = () async => throw mockHttpError(404);
      expect(
        (await reader.read(const LotId(1))).failureOrNull,
        isA<NotFoundFailure>(),
      );

      remote.handler = () async =>
          throw mockDioError(DioExceptionType.connectionError);
      expect(
        (await reader.read(const LotId(1))).failureOrNull,
        isA<NetworkFailure>(),
      );
    });
  });
}
