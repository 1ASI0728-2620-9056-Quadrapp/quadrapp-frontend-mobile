// US13, US14, TS08: «¿Cuándo llegas?» (el cálculo automático con su explicación
// de privacidad, el tráfico en tiempo real, o elegir el tiempo a mano), con las
// guías de accesibilidad.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/eta/eta_sheet.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/pump_screen.dart';

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

void main() {
  late _MockEstimate estimate;
  late _MockStatus status;
  late _MockRequest request;
  late _MockGetPreferences getPreferences;
  late _MockSavePreferences savePreferences;
  late LocationPermissionStatus permission;
  late EtaPreferences stored;
  late bool tooFar;
  late EtaCubit cubit;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const EstimateArrivalEtaParams());
    registerFallbackValue(const EtaPreferences());
  });

  void createCubit({bool trafficAvailable = false}) {
    cubit = EtaCubit(
      estimateArrivalEta: estimate,
      getPermissionStatus: status,
      requestPermission: request,
      getPreferences: getPreferences,
      savePreferences: savePreferences,
      clock: FakeClock(),
      trafficAvailable: trafficAvailable,
      ticker: () => const Stream<void>.empty(),
    );
  }

  setUp(() {
    estimate = _MockEstimate();
    status = _MockStatus();
    request = _MockRequest();
    getPreferences = _MockGetPreferences();
    savePreferences = _MockSavePreferences();
    permission = LocationPermissionStatus.granted;
    stored = const EtaPreferences();
    tooFar = false;
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
      if (tooFar) return const Err(ValidationFailure('x'));
      final params =
          invocation.positionalArguments.single as EstimateArrivalEtaParams;
      final manual = params.manualMinutes;
      return Success(
        EtaEstimate(
          minutes: EtaMinutes.create(manual ?? 25).valueOrNull!,
          source: manual != null
              ? EtaSource.manual
              : params.useTraffic
              ? EtaSource.traffic
              : EtaSource.device,
        ),
      );
    });
    createCubit();
  });

  tearDown(() => cubit.close());

  Future<void> openSheet(
    WidgetTester tester, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
  }) async {
    await pumpScreen(
      tester,
      BlocProvider<EtaCubit>.value(
        value: cubit,
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => unawaited(showEtaSheet(context)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      textScale: textScale,
      brightness: brightness,
      locale: locale,
      size: const Size(360, 1400),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  group('cálculo automático', () {
    testWidgets('con el ETA estimado lo dice, de dónde sale, y ofrece elegir', (
      tester,
    ) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(find.text('When do you arrive?'), findsOneWidget);
      expect(find.text('Calculate my arrival automatically'), findsOneWidget);
      expect(
        tester.widget<Switch>(find.byType(Switch).first).value,
        isTrue,
      );
      expect(
        find.text('Now: 25 min · estimated on your phone'),
        findsOneWidget,
      );
      expect(find.text('Or pick the time yourself'), findsOneWidget);
      for (final minutes in etaQuickMinutes) {
        expect(find.text('$minutes min'), findsWidgets);
      }
      // Ya usa la ubicación: no ofrece pedirla otra vez.
      expect(find.text('Use my location'), findsNothing);
    });

    testWidgets('antes de pedir el permiso, la explicación de privacidad está '
        'a la vista y el botón lo pide', (tester) async {
      permission = LocationPermissionStatus.denied;
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(find.textContaining('never your location'), findsWidgets);
      expect(find.text('Use my location'), findsOneWidget);
      verifyNever(() => request(any()));

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      verify(() => request(any())).called(1);
      expect(cubit.state.estimate?.isEstimated, isTrue);
      expect(
        find.text('Now: 25 min · estimated on your phone'),
        findsOneWidget,
      );
    });

    testWidgets('se puede apagar: no usa la ubicación y lo dice', (
      tester,
    ) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);

      await tester.tap(find.text('Calculate my arrival automatically'));
      await tester.pumpAndSettle();

      expect(cubit.state.autoEnabled, isFalse);
      expect(stored.autoEnabled, isFalse);
      expect(cubit.state.estimate, isNull);
      expect(
        find.textContaining("Off: we won't use your location"),
        findsOneWidget,
      );
      expect(find.textContaining('Now:'), findsNothing);
    });

    testWidgets('apagado, se vuelve a encender', (tester) async {
      await cubit.setDestination(_lot());
      await cubit.setAutoEnabled(enabled: false);
      await openSheet(tester);

      await tester.tap(find.text('Calculate my arrival automatically'));
      await tester.pumpAndSettle();

      expect(cubit.state.autoEnabled, isTrue);
      expect(cubit.state.estimate?.isEstimated, isTrue);
    });

    testWidgets('a más de 2 horas dice por qué no hay ETA', (tester) async {
      tooFar = true;
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(
        find.textContaining("You're more than 2 hours from campus"),
        findsOneWidget,
      );
    });
  });

  group('tráfico en tiempo real', () {
    testWidgets('sin proveedor (sin clave) no se ofrece', (tester) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(find.text('Include live traffic'), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('con proveedor, explica qué se comparte y se enciende aparte', (
      tester,
    ) async {
      createCubit(trafficAvailable: true);
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(find.text('Include live traffic'), findsOneWidget);
      // Apagado por defecto, con lo que pasa si se enciende a la vista.
      expect(tester.widget<Switch>(find.byType(Switch).last).value, isFalse);
      expect(
        find.textContaining('your location never leaves your phone'),
        findsOneWidget,
      );

      await tester.tap(find.text('Include live traffic'));
      await tester.pumpAndSettle();

      expect(cubit.state.trafficEnabled, isTrue);
      expect(stored.trafficEnabled, isTrue);
      expect(find.textContaining('goes to Google'), findsOneWidget);
      expect(
        find.text('Now: 25 min · with live traffic'),
        findsOneWidget,
      );
    });

    testWidgets('con el automático apagado, el tráfico no aparece', (
      tester,
    ) async {
      createCubit(trafficAvailable: true);
      await cubit.setDestination(_lot());
      await cubit.setAutoEnabled(enabled: false);
      await openSheet(tester);

      expect(find.text('Include live traffic'), findsNothing);
    });
  });

  group('a mano', () {
    testWidgets('elegir una opción rápida aplica el ETA al instante', (
      tester,
    ) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);

      await tester.tap(find.widgetWithText(InkWell, '45 min').first);
      await tester.pumpAndSettle();

      expect(cubit.state.manualMinutes, 45);
      expect(cubit.state.estimate?.source, EtaSource.manual);
      expect(
        find.text('Now: 45 min · chosen by you'),
        findsOneWidget,
      );
      // Lo manual avisa que baja solo y ofrece volver al automático.
      expect(
        find.text('Chosen by you. It goes down by itself as time passes.'),
        findsOneWidget,
      );
      expect(find.text('Go back to automatic'), findsOneWidget);
    });

    testWidgets('volver al automático quita lo manual', (tester) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);
      await tester.tap(find.widgetWithText(InkWell, '45 min').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Go back to automatic'));
      await tester.tap(find.text('Go back to automatic'));
      await tester.pumpAndSettle();

      expect(cubit.state.manualMinutes, isNull);
      expect(cubit.state.estimate?.isEstimated, isTrue);
      expect(find.text('Go back to automatic'), findsNothing);
    });

    testWidgets('el ajuste suma y resta de 5 en 5 y no pasa de 120', (
      tester,
    ) async {
      await cubit.setDestination(_lot());
      await openSheet(tester);
      await cubit.chooseManual(20);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('More time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More time'));
      await tester.pumpAndSettle();
      expect(cubit.state.manualMinutes, 25);

      await tester.tap(find.byTooltip('Less time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Less time'));
      await tester.pumpAndSettle();
      expect(cubit.state.manualMinutes, 15);

      await cubit.chooseManual(120);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.add_rounded),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('lo que no se puede', () {
    testWidgets(
      'con el permiso bloqueado no ofrece pedirlo y explica por qué',
      (
        tester,
      ) async {
        permission = LocationPermissionStatus.deniedForever;
        await cubit.setDestination(_lot());
        await openSheet(tester);

        expect(find.text('Use my location'), findsNothing);
        expect(
          find.textContaining('Location is blocked for Quadrapp'),
          findsOneWidget,
        );
      },
    );

    testWidgets('con la ubicación apagada, lo explica', (tester) async {
      permission = LocationPermissionStatus.serviceDisabled;
      await cubit.setDestination(_lot());
      await openSheet(tester);

      expect(find.text('Use my location'), findsNothing);
      expect(find.textContaining('location is off'), findsOneWidget);
    });

    testWidgets('una sede sin coordenadas solo admite elegir a mano', (
      tester,
    ) async {
      await cubit.setDestination(_lot(withCoordinates: false));
      await openSheet(tester);

      expect(find.text('Use my location'), findsNothing);
      expect(find.textContaining('no map position yet'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, '30 min').first);
      await tester.pumpAndSettle();
      expect(cubit.state.estimate?.minutes.value, 30);
    });

    testWidgets(
      'si no se puede usar la ubicación y está apagado, no se enciende',
      (
        tester,
      ) async {
        permission = LocationPermissionStatus.deniedForever;
        await cubit.setDestination(_lot());
        await cubit.setAutoEnabled(enabled: false);
        await openSheet(tester);

        expect(
          tester.widget<Switch>(find.byType(Switch).first).onChanged,
          isNull,
        );
      },
    );
  });

  testWidgets('«Done» cierra la ventana', (tester) async {
    await cubit.setDestination(_lot());
    await openSheet(tester);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('When do you arrive?'), findsNothing);
  });

  for (final (scale, dark) in [(1.0, false), (2.0, false), (1.0, true)]) {
    testWidgets('accesible (${scale}x${dark ? ', oscuro' : ''})', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      permission = LocationPermissionStatus.denied;
      createCubit(trafficAvailable: true);
      await cubit.setDestination(_lot());
      await openSheet(
        tester,
        textScale: scale,
        brightness: dark ? Brightness.dark : Brightness.light,
      );

      expect(tester.takeException(), isNull);
      await expectAccessible(tester);
      handle.dispose();
    });
  }

  testWidgets('en español', (tester) async {
    permission = LocationPermissionStatus.denied;
    createCubit(trafficAvailable: true);
    await cubit.setDestination(_lot());
    await openSheet(tester, locale: const Locale('es'));

    expect(find.text('¿Cuándo llegas?'), findsOneWidget);
    expect(find.text('Calcular mi llegada automáticamente'), findsOneWidget);
    expect(find.text('Incluir el tráfico en tiempo real'), findsOneWidget);
    expect(find.text('Usar mi ubicación'), findsOneWidget);
    expect(find.text('O elige tú el tiempo'), findsOneWidget);
  });
}
