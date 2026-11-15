// US19, US29: los accesos vehiculares.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_cubit.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_dto.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/accesses/get_accesses_overview.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';

Map<String, dynamic> accessesJson({
  Object? flow = const {
    'entries': 12,
    'exits': 9,
    'windowMin': 15,
    'series': [
      {'minuteStart': '2026-09-28T13:41:00Z', 'entries': 2, 'exits': 1},
      {'minuteStart': '2026-09-28T13:40:00Z', 'entries': 1, 'exits': 0},
    ],
  },
  List<Map<String, Object?>> accesses = const [
    {
      'id': 102,
      'name': 'Acceso Sur',
      'type': 'BIDIRECTIONAL',
      'flowCountingEnabled': true,
      'status': 'OPERATIONAL',
      'entries': 7,
      'exits': 5,
    },
    {
      'id': 101,
      'name': 'Acceso Norte',
      'type': 'ENTRY',
      'flowCountingEnabled': true,
      'status': 'OPERATIONAL',
      'entries': 5,
      'exits': 0,
    },
  ],
  List<String> unavailable = const [],
}) => {
  'lotId': 1,
  'settings': {
    'opensAt': '08:00',
    'closesAt': '16:00',
    'saturationThresholdPct': 85,
  },
  'flow': flow,
  'accesses': accesses,
  'consolidatedAt': '2026-09-28T13:41:40Z',
  'serverTime': '2026-09-28T13:42:00Z',
  'staleAfterSeconds': 180,
  'stale': false,
  'unavailable': unavailable,
};

class _MockGetOverview extends Mock implements GetAccessesOverview {}

class _MockUpdateSettings extends Mock implements UpdateLotSettings {}

const LotId _lot = LotId(1);

void main() {
  late RecordingLogger logger;
  late AccessesOverviewMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = AccessesOverviewMapper(logger);
  });

  AccessesOverview map(Map<String, dynamic> json) => mapper.toEntity(
    AccessesOverviewDto.fromJson(json),
    receivedAt: const Duration(seconds: 2),
  );

  group('AccessesOverviewMapper', () {
    test('caso feliz: flujo con su serie ordenada, accesos por nombre, '
        'configuración y antigüedad con la hora del servidor', () {
      final overview = map(accessesJson());

      expect(overview.flow?.entries, 12);
      expect(overview.flow?.net, 3);
      expect(overview.flow?.window, const Duration(minutes: 15));
      expect(
        overview.flow?.minutes.map((m) => m.start.minute),
        [40, 41],
        reason: 'del más antiguo al minuto en curso',
      );
      expect(overview.accesses.map((a) => a.name), [
        'Acceso Norte',
        'Acceso Sur',
      ]);
      expect(overview.accesses.first.type, AccessType.entry);
      expect(overview.settings.opensAt?.hhmm, '08:00');
      expect(overview.settings.saturationThresholdPct, 85);
      expect(
        overview.freshness.age(FakeClock()),
        const Duration(seconds: 20),
      );
      expect(logger.messages, isEmpty);
    });

    test('valores desconocidos no rompen: tipo → entrada y salida, estado → '
        'sin señal (cauteloso), sección → se ignora; cada uno con aviso', () {
      final overview = map(
        accessesJson(
          accesses: const [
            {
              'id': 1,
              'name': 'Portón',
              'type': 'TURNSTILE',
              'flowCountingEnabled': true,
              'status': 'MAINTENANCE',
              'entries': 3,
              'exits': 1,
            },
          ],
          unavailable: ['weather'],
        ),
      );

      final access = overview.accesses.single;
      expect(access.type, AccessType.bidirectional);
      expect(access.status, AccessStatus.unreachable);
      expect(overview.flowUnavailable, isFalse);
      expect(logger.messages, hasLength(3));
    });

    test('un acceso sin conteo no muestra cifras aunque lleguen (US19 '
        'esc. 3)', () {
      final access = map(
        accessesJson(
          accesses: const [
            {
              'id': 1,
              'name': 'Portón',
              'type': 'BIDIRECTIONAL',
              'flowCountingEnabled': false,
              'status': 'OPERATIONAL',
              'entries': 3,
              'exits': 1,
            },
          ],
        ),
      ).accesses.single;

      expect(access.status, AccessStatus.notCounting);
      expect(access.entries, isNull);
      expect(access.exits, isNull);
    });

    test('flujo no disponible (parcial) no es lo mismo que sin conteo', () {
      final partial = map(accessesJson(unavailable: ['flow']));
      final none = map(accessesJson(flow: null));

      expect(partial.flow, isNull);
      expect(partial.flowUnavailable, isTrue);
      expect(none.flow, isNull);
      expect(none.flowUnavailable, isFalse);
    });
  });

  group('AccessesCubit', () {
    late _MockGetOverview getOverview;
    late _MockUpdateSettings updateSettings;

    final overview =
        AccessesOverviewMapper(
          RecordingLogger(),
        ).toEntity(
          AccessesOverviewDto.fromJson(accessesJson()),
          receivedAt: Duration.zero,
        );
    final partial = AccessesOverviewMapper(RecordingLogger()).toEntity(
      AccessesOverviewDto.fromJson(accessesJson(unavailable: ['flow'])),
      receivedAt: Duration.zero,
    );
    final newSettings =
        (LotSettings.create(
                  opensAt: LotTime.of(7, 0),
                  closesAt: LotTime.of(22, 0),
                  saturationThresholdPct: 90,
                )
                as Success<LotSettings>)
            .value;

    setUpAll(() {
      registerFallbackValue(_lot);
      registerFallbackValue((lotId: _lot, settings: newSettings));
    });

    setUp(() {
      getOverview = _MockGetOverview();
      updateSettings = _MockUpdateSettings();
    });

    AccessesCubit build() => AccessesCubit(
      getAccessesOverview: getOverview,
      updateLotSettings: updateSettings,
    );

    blocTest<AccessesCubit, ViewState<AccessesOverview>>(
      'con todo, los accesos completos',
      setUp: () => when(
        () => getOverview(any()),
      ).thenAnswer((_) async => Success(overview)),
      build: build,
      act: (cubit) => cubit.load(_lot),
      expect: () => [
        const ViewLoading<AccessesOverview>(),
        ViewData(overview),
      ],
    );

    blocTest<AccessesCubit, ViewState<AccessesOverview>>(
      'sin el flujo, parcial con lo que llegó',
      setUp: () => when(
        () => getOverview(any()),
      ).thenAnswer((_) async => Success(partial)),
      build: build,
      act: (cubit) => cubit.load(_lot),
      expect: () => [
        const ViewLoading<AccessesOverview>(),
        ViewPartial(partial, missing: const {'flow'}),
      ],
    );

    blocTest<AccessesCubit, ViewState<AccessesOverview>>(
      'si la recarga falla, el error conserva lo anterior',
      setUp: () {
        var calls = 0;
        when(() => getOverview(any())).thenAnswer(
          (_) async =>
              calls++ == 0 ? Success(overview) : const Err(NetworkFailure()),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(_lot);
        await cubit.refresh();
      },
      skip: 2,
      expect: () => [
        ViewLoading(previous: overview),
        ViewError<AccessesOverview>(
          const NetworkFailure(),
          previous: overview,
        ),
      ],
    );

    test('guardar la configuración la muestra sin recargar', () async {
      when(
        () => getOverview(any()),
      ).thenAnswer((_) async => Success(overview));
      when(
        () => updateSettings(any()),
      ).thenAnswer((_) async => Success(newSettings));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load(_lot);

      final failure = await cubit.saveSettings(newSettings);

      expect(failure, isNull);
      expect(
        (cubit.state as ViewData<AccessesOverview>).data.settings,
        newSettings,
      );
      verify(() => getOverview(any())).called(1);
    });

    test('si el servidor rechaza (403), devuelve la falla y no cambia lo '
        'mostrado', () async {
      when(
        () => getOverview(any()),
      ).thenAnswer((_) async => Success(overview));
      when(
        () => updateSettings(any()),
      ).thenAnswer((_) async => const Err(ForbiddenFailure()));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load(_lot);

      final failure = await cubit.saveSettings(newSettings);

      expect(failure, const ForbiddenFailure());
      expect(cubit.state, ViewData(overview));
    });
  });
}
