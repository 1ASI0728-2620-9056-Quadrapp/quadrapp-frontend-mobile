// US13, US14, TS08: el ETA lo decide el conductor o se estima con su ubicación;
// lo manual manda, se mantiene al día solo y a Quadrapp solo llegan minutos.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../helpers/fake_clock.dart';

class _MockEstimate extends Mock implements EstimateArrivalEta {}

class _MockStatus extends Mock implements GetLocationPermissionStatus {}

class _MockRequest extends Mock implements RequestLocationPermission {}

class _MockGetPreferences extends Mock implements GetEtaPreferences {}

class _MockSavePreferences extends Mock implements SaveEtaPreferences {}

ParkingLot _lot({bool withCoordinates = true}) => ParkingLot(
  id: const LotId(1),
  name: 'Monterrico',
  layoutVersion: 4,
  staleAfter: const Duration(seconds: 180),
  latitude: withCoordinates ? -12.1035 : null,
  longitude: withCoordinates ? -76.963 : null,
);

EtaEstimate _device(int minutes) => EtaEstimate(
  minutes: EtaMinutes.create(minutes).valueOrNull!,
  source: EtaSource.device,
);

EtaEstimate _traffic(int minutes) => EtaEstimate(
  minutes: EtaMinutes.create(minutes).valueOrNull!,
  source: EtaSource.traffic,
);

EtaEstimate _manual(int minutes) => EtaEstimate(
  minutes: EtaMinutes.create(minutes).valueOrNull!,
  source: EtaSource.manual,
);

void main() {
  late _MockEstimate estimate;
  late _MockStatus status;
  late _MockRequest request;
  late _MockGetPreferences getPreferences;
  late _MockSavePreferences savePreferences;
  late StreamController<void> ticks;
  late FakeClock clock;
  late LocationPermissionStatus permission;

  /// Lo que estima la app cuando el conductor no eligió: sale del ETA que da
  /// el estimador (con tráfico si se pidió).
  late int autoMinutes;
  late EtaPreferences stored;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const EstimateArrivalEtaParams());
    registerFallbackValue(const EtaPreferences());
  });

  setUp(() {
    estimate = _MockEstimate();
    status = _MockStatus();
    request = _MockRequest();
    getPreferences = _MockGetPreferences();
    savePreferences = _MockSavePreferences();
    ticks = StreamController<void>.broadcast();
    clock = FakeClock();
    permission = LocationPermissionStatus.granted;
    autoMinutes = 25;
    stored = const EtaPreferences();
    when(() => status(any())).thenAnswer((_) async => Success(permission));
    when(() => request(any())).thenAnswer((_) async {
      permission = LocationPermissionStatus.granted;
      return Success(permission);
    });
    when(() => getPreferences(any())).thenAnswer((_) async => Success(stored));
    when(() => savePreferences(any())).thenAnswer((invocation) async {
      stored = invocation.positionalArguments.single as EtaPreferences;
      return const Success<void>(null);
    });
    when(() => estimate(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single as EstimateArrivalEtaParams;
      final manual = params.manualMinutes;
      if (manual != null) return Success(_manual(manual));
      return Success(
        params.useTraffic ? _traffic(autoMinutes) : _device(autoMinutes),
      );
    });
  });

  tearDown(() => ticks.close());

  EtaCubit cubit({bool trafficAvailable = false}) => EtaCubit(
    estimateArrivalEta: estimate,
    getPermissionStatus: status,
    requestPermission: request,
    getPreferences: getPreferences,
    savePreferences: savePreferences,
    clock: clock,
    trafficAvailable: trafficAvailable,
    ticker: () => ticks.stream,
  );

  Future<void> tick(
    EtaCubit c, {
    Duration after = const Duration(minutes: 1),
  }) async {
    clock.advance(after);
    ticks.add(null);
    await pumpEventQueue();
  }

  group('ETA automático', () {
    test('con la sede y el permiso, estima el ETA en el dispositivo', () async {
      final c = cubit();
      addTearDown(c.close);

      await c.setDestination(_lot());

      expect(c.state.estimate, _device(25));
      expect(c.state.hasDestination, isTrue);
      expect(c.state.isManual, isFalse);
      // A la estimación solo le llega el destino: la posición vive en el
      // estimador y no sale de él.
      final params =
          verify(() => estimate(captureAny())).captured.single
              as EstimateArrivalEtaParams;
      expect(params.manualMinutes, isNull);
      expect(params.useTraffic, isFalse);
      expect(params.destination?.latitude, -12.1035);
    });

    test('sin coordenadas de la sede no hay ETA automático ni error', () async {
      final c = cubit();
      addTearDown(c.close);

      await c.setDestination(_lot(withCoordinates: false));

      expect(c.state.estimate, isNull);
      expect(c.state.hasDestination, isFalse);
      verifyNever(() => estimate(any()));
    });

    test(
      'sin permiso no hay ETA automático y la app sigue en modo manual',
      () async {
        permission = LocationPermissionStatus.denied;
        final c = cubit();
        addTearDown(c.close);

        await c.setDestination(_lot());

        expect(c.state.estimate, isNull);
        expect(c.state.permission, LocationPermissionStatus.denied);
        expect(c.state.canUseLocation, isTrue);
        verifyNever(() => request(any()));
      },
    );

    test('cambiar de sede recalcula con las coordenadas de la nueva', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      await c.setDestination(_lot(withCoordinates: false));

      expect(c.state.hasDestination, isFalse);
      expect(c.state.estimate, isNull);
    });

    test('anota cuándo se calculó, con el reloj monótono', () async {
      final c = cubit();
      addTearDown(c.close);
      clock.advance(const Duration(minutes: 7));

      await c.setDestination(_lot());

      expect(c.state.updatedAt, const Duration(minutes: 7));
    });
  });

  group('se mantiene al día solo (US14)', () {
    test('se recalcula cada minuto con el ETA automático', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      clearInteractions(estimate);

      await tick(c);
      await tick(c);

      verify(() => estimate(any())).called(2);
    });

    test('un cambio de menos de 2 minutos no publica un ETA nuevo', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      autoMinutes = 24;
      await tick(c);

      expect(c.state.estimate, _device(25));
      // Pero sí se anota que se volvió a calcular.
      expect(c.state.updatedAt, const Duration(minutes: 1));
    });

    test('un cambio de 2 minutos o más sí se publica', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      autoMinutes = 22;
      await tick(c);

      expect(c.state.estimate, _device(22));
    });

    test('al llegar (0 minutos) siempre se publica', () async {
      final c = cubit();
      addTearDown(c.close);
      autoMinutes = 1;
      await c.setDestination(_lot());

      autoMinutes = 0;
      await tick(c);

      expect(c.state.estimate, _device(0));
    });

    test(
      'si cambia de dónde sale el ETA, se publica aunque sea parecido',
      () async {
        final c = cubit(trafficAvailable: true);
        addTearDown(c.close);
        await c.setDestination(_lot());
        expect(c.state.estimate, _device(25));

        autoMinutes = 24;
        await c.setTrafficEnabled(enabled: true);

        expect(c.state.estimate, _traffic(24));
      },
    );

    test(
      'una decisión del conductor (otra sede) publica aunque cambie poco',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setDestination(_lot());

        autoMinutes = 24;
        await c.setDestination(_lot());

        expect(c.state.estimate, _device(24));
      },
    );
  });

  group('ETA manual', () {
    test('lo manual manda sobre lo estimado', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      await c.chooseManual(40);

      expect(c.state.estimate, _manual(40));
      expect(c.state.manualMinutes, 40);
      expect(c.state.isManual, isTrue);
    });

    test('sirve aunque la sede no tenga coordenadas ni haya permiso', () async {
      permission = LocationPermissionStatus.deniedForever;
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot(withCoordinates: false));

      await c.chooseManual(30);

      expect(c.state.estimate, _manual(30));
    });

    test('un tiempo fuera de 0 a 120 se ignora', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      await c.chooseManual(121);
      await c.chooseManual(-5);

      expect(c.state.manualMinutes, isNull);
      expect(c.state.estimate, _device(25));
    });

    test(
      'baja solo con el reloj: «llego en 20» es una hora de llegada',
      () async {
        final c = cubit();
        addTearDown(c.close);
        await c.setDestination(_lot());
        await c.chooseManual(20);

        await tick(c, after: const Duration(minutes: 5));
        expect(c.state.estimate, _manual(15));

        await tick(c, after: const Duration(minutes: 10));
        expect(c.state.estimate, _manual(5));
        // Lo que eligió sigue siendo lo que eligió.
        expect(c.state.manualMinutes, 20);
      },
    );

    test('a los 59 segundos todavía son los minutos elegidos', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      await c.chooseManual(20);

      await tick(c, after: const Duration(seconds: 59));

      expect(c.state.estimate, _manual(20));
    });

    test('al llegar a cero deja de recalcular', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      await c.chooseManual(10);

      await tick(c, after: const Duration(minutes: 12));
      expect(c.state.estimate, _manual(0));
      clearInteractions(estimate);

      await tick(c);

      verifyNever(() => estimate(any()));
    });

    test(
      'volver al automático quita lo manual y pide el permiso solo si se puede',
      () async {
        permission = LocationPermissionStatus.denied;
        final c = cubit();
        addTearDown(c.close);
        await c.setDestination(_lot());
        await c.chooseManual(30);

        await c.useLocation();

        expect(c.state.manualMinutes, isNull);
        verify(() => request(any())).called(1);
        expect(c.state.estimate, _device(25));
      },
    );

    test('con el permiso bloqueado, usar la ubicación no pide nada', () async {
      permission = LocationPermissionStatus.deniedForever;
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());

      await c.useLocation();

      verifyNever(() => request(any()));
      expect(c.state.estimate, isNull);
      expect(c.state.permission, LocationPermissionStatus.deniedForever);
    });
  });

  group('ETA inválido (US13 esc. 2)', () {
    test(
      'a más de 2 horas no hay ETA y se dice por qué, sin error técnico',
      () async {
        when(() => estimate(any())).thenAnswer(
          (_) async => const Err(ValidationFailure('x')),
        );
        final c = cubit();
        addTearDown(c.close);

        await c.setDestination(_lot());

        expect(c.state.estimate, isNull);
        expect(c.state.issue, EtaIssue.tooFar);
      },
    );

    test(
      'sigue mirando: al acercarse aparece el ETA y se va el aviso',
      () async {
        var farAway = true;
        when(() => estimate(any())).thenAnswer(
          (_) async => farAway
              ? const Err(ValidationFailure('x'))
              : Success(_device(90)),
        );
        final c = cubit();
        addTearDown(c.close);
        await c.setDestination(_lot());
        expect(c.state.issue, EtaIssue.tooFar);

        farAway = false;
        await tick(c);

        expect(c.state.estimate, _device(90));
        expect(c.state.issue, isNull);
      },
    );
  });

  group('modo automático y tráfico', () {
    test('apagar el automático no usa la ubicación y lo guarda', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      clearInteractions(estimate);

      await c.setAutoEnabled(enabled: false);

      expect(c.state.autoEnabled, isFalse);
      expect(c.state.estimate, isNull);
      expect(stored.autoEnabled, isFalse);
      verifyNever(() => estimate(any()));
    });

    test('con el automático apagado lo manual sigue sirviendo', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      await c.setAutoEnabled(enabled: false);

      await c.chooseManual(30);

      expect(c.state.estimate, _manual(30));
    });

    test('encender el automático equivale a usar la ubicación', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.setDestination(_lot());
      await c.chooseManual(30);
      await c.setAutoEnabled(enabled: false);

      await c.setAutoEnabled(enabled: true);

      expect(c.state.autoEnabled, isTrue);
      expect(c.state.manualMinutes, isNull);
      expect(c.state.estimate, _device(25));
      expect(stored.autoEnabled, isTrue);
    });

    test('el tráfico se pide solo si está activado y hay proveedor', () async {
      final c = cubit(trafficAvailable: true);
      addTearDown(c.close);
      await c.setDestination(_lot());

      await c.setTrafficEnabled(enabled: true);

      final params = verify(
        () => estimate(captureAny()),
      ).captured.cast<EstimateArrivalEtaParams>();
      expect(params.first.useTraffic, isFalse);
      expect(params.last.useTraffic, isTrue);
      expect(stored.trafficEnabled, isTrue);
      expect(c.state.usesTraffic, isTrue);
    });

    test('sin proveedor (sin clave) el tráfico nunca se pide', () async {
      stored = const EtaPreferences(trafficEnabled: true);
      final c = cubit();
      addTearDown(c.close);

      await c.setDestination(_lot());

      final params =
          verify(() => estimate(captureAny())).captured.single
              as EstimateArrivalEtaParams;
      expect(params.useTraffic, isFalse);
      expect(c.state.usesTraffic, isFalse);
    });

    test('las preferencias guardadas se leen al empezar', () async {
      stored = const EtaPreferences(autoEnabled: false, trafficEnabled: true);
      final c = cubit(trafficAvailable: true);
      addTearDown(c.close);

      await c.setDestination(_lot());

      expect(c.state.autoEnabled, isFalse);
      expect(c.state.trafficEnabled, isTrue);
      expect(c.state.estimate, isNull);
      verifyNever(() => estimate(any()));
    });
  });

  test('al cerrarse deja de escuchar el reloj', () async {
    final c = cubit();
    await c.setDestination(_lot());
    expect(ticks.hasListener, isTrue);

    await c.close();

    expect(ticks.hasListener, isFalse);
  });
}
