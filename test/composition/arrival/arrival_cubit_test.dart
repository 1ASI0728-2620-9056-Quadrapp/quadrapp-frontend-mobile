// US05, US07, US09 a US15, US36: Inicio («Tu llegada») en cada estado.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_cubit.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';

class _MockOccupancy extends Mock implements GetLotOccupancy {}

class _MockRequest extends Mock implements RequestArrivalAdvice {}

class _MockRecalculate extends Mock implements RecalculateArrivalAdvice {}

class _MockNext extends Mock implements GetNextAvailability {}

class _MockWatch extends Mock implements WatchLotFeed {}

ParkingLot _lot(int id, {int layoutVersion = 4}) => ParkingLot(
  id: LotId(id),
  name: 'Sede $id',
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

LotOccupancy _occupancy({
  int lotId = 1,
  int free = 45,
  int occupied = 72,
  int unknown = 3,
  OccupancySource source = OccupancySource.network,
}) {
  final at = DateTime.utc(2026, 9, 28, 13, 42);
  return LotOccupancy(
    lotId: LotId(lotId),
    capacity: free + occupied + unknown,
    free: free,
    occupied: occupied,
    unknown: unknown,
    freshness: Freshness(
      consolidatedAt: at,
      serverTime: at.add(const Duration(seconds: 20)),
      staleAfter: const Duration(seconds: 180),
      receivedAt: Duration.zero,
    ),
    source: source,
  );
}

ArrivalAdvice _advice(
  int eta, {
  double probability = 0.82,
  ArrivalCategory? category = ArrivalCategory.high,
}) => ArrivalAdvice(
  etaMinutes: EtaMinutes.create(eta).valueOrNull!,
  probabilityOfSpace: probability,
  category: category,
  confidence: const Confidence(value: 0.8, level: ConfidenceLevel.high),
  generatedAt: DateTime.utc(2026, 9, 28, 13, 40),
);

void main() {
  late _MockOccupancy occupancy;
  late _MockRequest request;
  late _MockRecalculate recalculate;
  late _MockNext next;
  late _MockWatch watch;
  late FakeClock clock;
  late StreamController<OccupancyFeedEvent> feed;

  setUpAll(() {
    registerFallbackValue(const LotId(1));
    registerFallbackValue(
      const RequestArrivalAdviceParams(lotId: LotId(1), etaMinutes: 1),
    );
    registerFallbackValue(
      const RecalculateArrivalAdviceParams(lotId: LotId(1), newEtaMinutes: 1),
    );
    registerFallbackValue(
      const GetNextAvailabilityParams(lotId: LotId(1), hasFreeSpaces: true),
    );
  });

  setUp(() {
    occupancy = _MockOccupancy();
    request = _MockRequest();
    recalculate = _MockRecalculate();
    next = _MockNext();
    watch = _MockWatch();
    clock = FakeClock();
    feed = StreamController<OccupancyFeedEvent>.broadcast();
    when(() => occupancy(any())).thenAnswer((_) async => Success(_occupancy()));
    when(() => request(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single as RequestArrivalAdviceParams;
      return Success(_advice(params.etaMinutes));
    });
    when(() => recalculate(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single
              as RecalculateArrivalAdviceParams;
      return Success(_advice(params.newEtaMinutes));
    });
    when(() => next(any())).thenAnswer(
      (_) async => const Success(
        NextAvailabilityEstimate(minMinutes: 8, maxMinutes: 15),
      ),
    );
    when(() => watch(any())).thenAnswer((_) => feed.stream);
  });

  tearDown(() => feed.close());

  ArrivalCubit cubit() => ArrivalCubit(
    getLotOccupancy: occupancy,
    requestArrivalAdvice: request,
    recalculateAdvice: recalculate,
    getNextAvailability: next,
    watchLotFeed: watch,
    clock: clock,
  );

  ArrivalOverview overviewOf(ArrivalCubit c) => switch (c.state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    _ => fail('se esperaba contenido, no ${c.state}'),
  };

  Future<void> settle() => pumpEventQueue();

  group('ArrivalCubit', () {
    test(
      'con ETA llega todo: ocupación, asesoría y los cuatro horizontes',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setEta(27);

        await c.setLot(_lot(1));

        expect(c.state, isA<ViewData<ArrivalOverview>>());
        final overview = overviewOf(c);
        expect(overview.occupancy?.free, 45);
        expect(overview.adviceStatus, AdviceStatus.available);
        expect(overview.advice?.etaMinutes.value, 27);
        expect(overview.horizons.map((h) => h.horizon.minutes), [
          15,
          30,
          45,
          60,
        ]);
        expect(overview.horizons.every((h) => h.isAvailable), isTrue);
        // Cada horizonte se pide con sus propios minutos (y solo con ellos).
        final minutes = verify(
          () => request(captureAny()),
        ).captured.cast<RequestArrivalAdviceParams>().map((p) => p.etaMinutes);
        expect(minutes.toSet(), {15, 30, 45, 60});
        verifyNever(() => next(any()));
      },
    );

    test(
      'sin ETA hay que elegirlo; lo demás sí llega y no es parcial',
      () async {
        final c = cubit();
        addTearDown(c.close);

        await c.setLot(_lot(1));

        final overview = overviewOf(c);
        expect(overview.adviceStatus, AdviceStatus.needsEta);
        expect(overview.advice, isNull);
        expect(overview.occupancy, isNotNull);
        expect(c.state, isA<ViewData<ArrivalOverview>>());
        verifyNever(() => recalculate(any()));
      },
    );

    test(
      'una sede sin distribución publicada no pide nada (US04 esc. 2)',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setEta(27);

        await c.setLot(_lot(3, layoutVersion: 0));

        expect(overviewOf(c).hasNoData, isTrue);
        verifyNever(() => occupancy(any()));
        verifyNever(() => request(any()));
        verifyNever(() => watch(any()));
      },
    );

    test('si falla la asesoría, es parcial y la ocupación se ve', () async {
      when(() => recalculate(any())).thenAnswer(
        (_) async => const Err(NetworkFailure()),
      );
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);

      await c.setLot(_lot(1));

      expect(c.state, isA<ViewPartial<ArrivalOverview>>());
      expect((c.state as ViewPartial<ArrivalOverview>).missing, {'advice'});
      expect(overviewOf(c).adviceStatus, AdviceStatus.unavailable);
      expect(overviewOf(c).occupancy, isNotNull);
    });

    test('una categoría desconocida deja la asesoría no disponible', () async {
      when(() => recalculate(any())).thenAnswer(
        (invocation) async => Success(_advice(27, category: null)),
      );
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);

      await c.setLot(_lot(1));

      expect(overviewOf(c).adviceStatus, AdviceStatus.unavailable);
      expect(c.state, isA<ViewPartial<ArrivalOverview>>());
    });

    test('si falla la ocupación pero llega la asesoría, es parcial', () async {
      when(() => occupancy(any())).thenAnswer(
        (_) async => const Err(ServerFailure()),
      );
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);

      await c.setLot(_lot(1));

      expect(c.state, isA<ViewPartial<ArrivalOverview>>());
      expect((c.state as ViewPartial<ArrivalOverview>).missing, {'occupancy'});
      expect(overviewOf(c).occupancy, isNull);
      expect(overviewOf(c).occupancyFailure, isA<ServerFailure>());
      // Sin ocupación no se observa nada en vivo.
      verifyNever(() => watch(any()));
    });

    test('un horizonte sin asesoría es parcial; los demás se ven', () async {
      when(() => request(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single as RequestArrivalAdviceParams;
        return params.etaMinutes == 45
            ? const Err(NotFoundFailure())
            : Success(_advice(params.etaMinutes));
      });
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);

      await c.setLot(_lot(1));

      expect((c.state as ViewPartial<ArrivalOverview>).missing, {'horizons'});
      expect(
        overviewOf(c).horizons.map((h) => h.isAvailable),
        [true, true, false, true],
      );
    });

    test('si no llega nada, es un error con su causa', () async {
      when(() => occupancy(any())).thenAnswer(
        (_) async => const Err(NetworkFailure()),
      );
      when(() => request(any())).thenAnswer(
        (_) async => const Err(NetworkFailure()),
      );
      final c = cubit();
      addTearDown(c.close);

      await c.setLot(_lot(1));

      expect(
        c.state,
        const ViewError<ArrivalOverview>(NetworkFailure()),
      );
    });

    test(
      'con los datos de la caché, es un éxito marcado sin conexión',
      () async {
        when(() => occupancy(any())).thenAnswer(
          (_) async => Success(_occupancy(source: OccupancySource.cache)),
        );
        final c = cubit();
        addTearDown(c.close);

        await c.setLot(_lot(1));

        expect((c.state as ViewData<ArrivalOverview>).offline, isTrue);
      },
    );

    test(
      'lleno: pide cuándo se libera un espacio (US36); con libres, no',
      () async {
        when(() => occupancy(any())).thenAnswer(
          (_) async => Success(_occupancy(free: 0, occupied: 78, unknown: 2)),
        );
        final c = cubit();
        addTearDown(c.close);

        await c.setLot(_lot(2));

        expect(
          overviewOf(c).nextAvailability,
          const NextAvailabilityEstimate(minMinutes: 8, maxMinutes: 15),
        );
      },
    );

    test('cambiar el ETA vuelve a pedir solo la asesoría', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);
      await c.setLot(_lot(1));
      clearInteractions(occupancy);
      clearInteractions(request);
      clearInteractions(recalculate);

      await c.setEta(40);

      expect(overviewOf(c).advice?.etaMinutes.value, 40);
      verify(() => recalculate(any())).called(1);
      verifyNever(() => occupancy(any()));
      verifyNever(() => request(any()));
    });

    test('un ETA que llega mientras se carga también se aplica', () async {
      final gate = Completer<Result<LotOccupancy>>();
      when(() => occupancy(any())).thenAnswer((_) => gate.future);
      final c = cubit();
      addTearDown(c.close);

      final loading = c.setLot(_lot(1));
      await pumpEventQueue();
      await c.setEta(27);
      gate.complete(Success(_occupancy()));
      await loading;

      expect(overviewOf(c).adviceStatus, AdviceStatus.available);
      expect(overviewOf(c).advice?.etaMinutes.value, 27);
    });

    group('qué cambió cuando cambió el ETA (US14)', () {
      test('anota el ETA y la probabilidad de antes y de ahora', () async {
        when(() => recalculate(any())).thenAnswer((invocation) async {
          final params =
              invocation.positionalArguments.single
                  as RecalculateArrivalAdviceParams;
          return Success(
            _advice(
              params.newEtaMinutes,
              probability: params.newEtaMinutes > 30 ? 0.55 : 0.82,
              category: params.newEtaMinutes > 30
                  ? ArrivalCategory.limited
                  : ArrivalCategory.high,
            ),
          );
        });
        final c = cubit();
        addTearDown(c.close);
        await c.setEta(27);
        await c.setLot(_lot(1));
        clock.advance(const Duration(minutes: 2));

        await c.setEta(40);

        final change = overviewOf(c).lastChange;
        expect(change?.previousEta, 27);
        expect(change?.eta, 40);
        expect(change?.previousProbability, 0.82);
        expect(change?.probability, 0.55);
        expect(change?.previousCategory, ArrivalCategory.high);
        expect(change?.category, ArrivalCategory.limited);
        expect(change?.categoryChanged, isTrue);
        expect(change?.improved, isFalse);
        expect(change?.at, const Duration(minutes: 2));
      });

      test('la primera asesoría no es un cambio', () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setLot(_lot(1));

        await c.setEta(27);

        expect(overviewOf(c).lastChange, isNull);
      });

      test(
        'si la asesoría se conserva (cambio menor), no hay cambio nuevo',
        () async {
          when(() => recalculate(any())).thenAnswer((invocation) async {
            final params =
                invocation.positionalArguments.single
                    as RecalculateArrivalAdviceParams;
            return Success(params.current ?? _advice(params.newEtaMinutes));
          });
          final c = cubit();
          addTearDown(c.close);
          await c.setEta(27);
          await c.setLot(_lot(1));

          await c.setEta(28);

          expect(overviewOf(c).lastChange, isNull);
        },
      );

      test('el cambio se ve unos minutos y luego se va', () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setEta(27);
        await c.setLot(_lot(1));
        await c.setEta(40);
        final change = overviewOf(c).lastChange!;

        expect(change.isVisible(clock), isTrue);
        clock.advance(const Duration(minutes: 2, seconds: 59));
        expect(change.isVisible(clock), isTrue);
        clock.advance(const Duration(seconds: 2));
        expect(change.isVisible(clock), isFalse);
      });

      test('cambiar de sede borra el cambio', () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setEta(27);
        await c.setLot(_lot(1));
        await c.setEta(40);
        expect(overviewOf(c).lastChange, isNotNull);

        await c.setLot(_lot(2));

        expect(overviewOf(c).lastChange, isNull);
      });
    });

    test('el mismo ETA no vuelve a pedir nada', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);
      await c.setLot(_lot(1));
      clearInteractions(recalculate);

      await c.setEta(27);

      verifyNever(() => recalculate(any()));
    });

    test(
      'elegir un ETA después de cargar sin él completa la asesoría',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setLot(_lot(1));
        expect(overviewOf(c).adviceStatus, AdviceStatus.needsEta);

        await c.setEta(30);

        expect(overviewOf(c).adviceStatus, AdviceStatus.available);
      },
    );

    test('recargar vuelve a pedir todo', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setEta(27);
      await c.setLot(_lot(1));
      clearInteractions(occupancy);

      await c.refresh();

      verify(() => occupancy(const LotId(1))).called(1);
    });
  });

  group('en vivo (US07)', () {
    test('el enlace es el real: conectando, en línea, reconectando', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));
      expect(overviewOf(c).link, isNull);

      feed.add(const LinkChanged(RealtimeLink.connecting));
      await settle();
      expect(overviewOf(c).link, RealtimeLink.connecting);

      feed.add(const LinkChanged(RealtimeLink.live));
      await settle();
      expect(overviewOf(c).link, RealtimeLink.live);

      feed.add(const LinkChanged(RealtimeLink.reconnecting));
      await settle();
      expect(overviewOf(c).link, RealtimeLink.reconnecting);
    });

    test('cada cambio reemplaza la ocupación', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));

      feed.add(OccupancyReceived(Success(_occupancy(free: 44, occupied: 73))));
      await settle();

      expect(overviewOf(c).occupancy?.free, 44);
    });

    test('un fallo al leer en vivo no tumba lo que ya se ve', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));

      feed.add(const OccupancyReceived(Err(NetworkFailure())));
      await settle();

      expect(overviewOf(c).occupancy?.free, 45);
    });

    test('al llenarse pide cuándo se libera; al liberarse, lo quita', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));
      expect(overviewOf(c).nextAvailability, isNull);

      feed.add(
        OccupancyReceived(Success(_occupancy(free: 0, occupied: 120))),
      );
      await settle();
      expect(overviewOf(c).nextAvailability, isA<NextAvailabilityEstimate>());

      feed.add(OccupancyReceived(Success(_occupancy(free: 1, occupied: 119))));
      await settle();
      expect(overviewOf(c).nextAvailability, isNull);
    });

    test(
      'cambiar de sede deja de observar la anterior y carga la nueva',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setLot(_lot(1));
        expect(feed.hasListener, isTrue);

        await c.setLot(_lot(3, layoutVersion: 0));

        expect(feed.hasListener, isFalse);
        expect(overviewOf(c).lot.id, const LotId(3));
      },
    );

    test('la misma sede no recarga', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));
      clearInteractions(occupancy);

      await c.setLot(_lot(1));

      verifyNever(() => occupancy(any()));
    });

    test('sin sede vuelve al inicio y deja de observar', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setLot(_lot(1));

      await c.setLot(null);

      expect(c.state, isA<ViewInitial<ArrivalOverview>>());
      expect(feed.hasListener, isFalse);
    });

    test('al cerrarse deja de observar', () async {
      final c = cubit();
      await c.setLot(_lot(1));
      expect(feed.hasListener, isTrue);

      await c.close();

      expect(feed.hasListener, isFalse);
    });
  });
}
