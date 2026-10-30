// US23, US24, US33: Alertas y preferencias en cada estado, con las guías de
// accesibilidad.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_cubit.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_state.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_tab_page.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/pump_screen.dart';
import 'support.dart' as s;

class _MockAlerts extends MockCubit<ViewState<AlertsOverview>>
    implements AlertsCubit {}

class _MockSede extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

ParkingLot _lot(int id, String name) => ParkingLot(
  id: LotId(id),
  name: name,
  layoutVersion: 4,
  staleAfter: const Duration(seconds: 180),
);

void main() {
  late _MockAlerts alerts;
  late _MockSede sede;
  late StreamController<AlertsNotice> notices;

  final lots = [_lot(1, 'Monterrico'), _lot(2, 'San Isidro'), _lot(3, 'Villa')];

  setUpAll(() {
    registerFallbackValue(AlertPreference.events);
    registerFallbackValue(s.subscription());
    registerFallbackValue(
      CreateAlertSubscriptionParams(
        lotId: const LotId(1),
        days: const {1},
        from: s.time(8, 0),
        to: s.time(9, 0),
      ),
    );
  });

  setUp(() {
    alerts = _MockAlerts();
    sede = _MockSede();
    notices = StreamController<AlertsNotice>.broadcast();
    when(() => alerts.notices).thenAnswer((_) => notices.stream);
    when(() => alerts.load()).thenAnswer((_) async {});
    when(() => alerts.refresh()).thenAnswer((_) async {});
    when(
      () => alerts.setPreference(any(), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(
      () => alerts.setPushEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    when(
      () => alerts.setSubscriptionActive(any(), active: any(named: 'active')),
    ).thenAnswer((_) async {});
    when(() => alerts.removeSubscription(any())).thenAnswer((_) async {});
    when(() => sede.load()).thenAnswer((_) async {});
  });

  tearDown(() => notices.close());

  Future<void> pumpPage(
    WidgetTester tester,
    ViewState<AlertsOverview> state, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(360, 2400),
    bool withLots = true,
  }) async {
    whenListen(
      alerts,
      const Stream<ViewState<AlertsOverview>>.empty(),
      initialState: state,
    );
    final sedeState = withLots
        ? ViewData(SedeSelection(lots: lots, selected: lots.first))
        : const ViewLoading<SedeSelection>();
    whenListen(
      sede,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState: sedeState,
    );
    await pumpScreen(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<AlertsCubit>.value(value: alerts),
          BlocProvider<SedeCubit>.value(value: sede),
        ],
        child: const AlertsTabPage(tabIndex: 3),
      ),
      brightness: brightness,
      locale: locale,
      textScale: textScale,
      size: size,
    );
    await tester.pump();
  }

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final states = <String, ViewState<AlertsOverview>>{
    'cargando (skeleton)': const ViewLoading(),
    'con datos': ViewData(s.overview()),
    'notificaciones desactivadas': ViewData(
      s.overview(prefs: s.preferences.copyWith(pushEnabled: false)),
    ),
    'sin franjas': ViewData(s.overview(subscriptions: const [])),
    'sin las preferencias': ViewPartial(
      s.overview(prefs: null),
      missing: const {'preferences'},
    ),
    'sin las franjas': ViewPartial(
      s.overview(withSubscriptions: false),
      missing: const {'subscriptions'},
    ),
    'error': const ViewError(NetworkFailure()),
    'error con el contenido anterior': ViewError(
      const ServerFailure(),
      previous: s.overview(),
    ),
  };

  group('estados, accesibles y sin desbordes', () {
    for (final MapEntry(key: name, value: state) in states.entries) {
      for (final (scale, dark, size) in [
        (1.0, false, const Size(360, 800)),
        (2.0, true, const Size(360, 640)),
      ]) {
        testWidgets('$name (${scale}x, ${dark ? 'oscuro' : 'claro'})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await pumpPage(
            tester,
            state,
            textScale: scale,
            size: size,
            brightness: dark ? Brightness.dark : Brightness.light,
          );

          expect(tester.takeException(), isNull);
          await expectAccessible(tester);
          handle.dispose();
        });
      }
    }
  });

  group('contenido', () {
    testWidgets('carga al abrir y muestra los cuatro interruptores', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(s.overview()));

      verify(() => alerts.load()).called(1);
      expect(find.text('Receive notifications'), findsOneWidget);
      expect(find.text('TELL ME WHEN'), findsOneWidget);
      for (final text in [
        'A lot is expected to fill up',
        'Availability is low',
        'Data is out of date',
        'Events change things',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      // Los valores salen de las preferencias: saturación y datos, encendidos.
      final switches = tester
          .widgetList<Switch>(find.byType(Switch))
          .map((w) => w.value)
          .toList();
      expect(switches.take(5), [true, true, false, true, false]);
    });

    testWidgets(
      'las franjas dicen la sede, los días y la hora; la pausada se ve',
      (
        tester,
      ) async {
        await pumpPage(tester, ViewData(s.overview()));

        expect(find.text('YOUR TIME SLOTS'), findsOneWidget);
        expect(find.text('Monterrico'), findsNWidgets(2));
        expect(find.text('San Isidro'), findsOneWidget);
        expect(find.text('Mon–Fri ·'), findsOneWidget);
        expect(find.text('Mon, Wed, Fri ·'), findsOneWidget);
        expect(find.text('Sat ·'), findsOneWidget);
        // Solo la pausada lleva la etiqueta.
        expect(find.text('Paused'), findsOneWidget);
      },
    );

    testWidgets('con las notificaciones apagadas, las alertas se desactivan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(s.overview(prefs: s.preferences.copyWith(pushEnabled: false))),
      );

      final first = tester.widget<Switch>(find.byType(Switch).at(1));
      expect(first.onChanged, isNull);
      expect(
        find.text('Turn notifications on to choose which alerts you get.'),
        findsOneWidget,
      );
      expect(
        find.text("Off: you won't get alerts, even for the slots you follow."),
        findsOneWidget,
      );
    });

    testWidgets('sin franjas, el estado vacío invita a agregar una', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(s.overview(subscriptions: const [])));

      expect(find.text("You don't follow any slot yet"), findsOneWidget);
      expect(find.text('Add a time slot'), findsOneWidget);
    });

    testWidgets('la conectividad y la privacidad se dicen como en el diseño', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(s.overview()));

      expect(find.text('Intermittent connection'), findsOneWidget);
      expect(find.text('Automatic'), findsOneWidget);
      expect(
        find.text(
          'Keeps the last lookup and syncs when the connection returns.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining("Quadrapp doesn't receive your location"),
        findsOneWidget,
      );
    });

    testWidgets('sin las preferencias o sin las franjas, avisa y reintenta', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewPartial(s.overview(prefs: null), missing: const {'preferences'}),
      );

      expect(find.text("We couldn't load your preferences."), findsOneWidget);
      expect(find.text('YOUR TIME SLOTS'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => alerts.load()).called(2);
    });

    testWidgets('el error sin contenido ofrece reintentar', (tester) async {
      await pumpPage(tester, const ViewError(NetworkFailure()));

      expect(find.text("Couldn't load your alerts"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => alerts.load()).called(2);
    });

    testWidgets('en español', (tester) async {
      await pumpPage(
        tester,
        ViewData(s.overview()),
        locale: const Locale('es'),
      );

      expect(find.text('Alertas y preferencias'), findsOneWidget);
      expect(find.text('AVÍSAME CUANDO'), findsOneWidget);
      expect(find.text('La disponibilidad sea baja'), findsOneWidget);
      expect(find.text('Los datos estén desactualizados'), findsOneWidget);
      expect(find.text('Lun–Vie ·'), findsOneWidget);
      expect(find.text('Pausada'), findsOneWidget);
    });
  });

  group('interacción', () {
    testWidgets('un interruptor de «Avísame cuando» llama al cubit', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.tap(find.text('Events change things'));

      verify(
        () => alerts.setPreference(AlertPreference.events, value: true),
      ).called(1);
    });

    testWidgets('el interruptor general llama al cubit', (tester) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.tap(find.text('Receive notifications'));

      verify(() => alerts.setPushEnabled(enabled: false)).called(1);
    });

    testWidgets('pausar una franja llama al cubit', (tester) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.tap(find.byType(Switch).at(5));

      verify(
        () => alerts.setSubscriptionActive(any(), active: false),
      ).called(1);
    });

    testWidgets('eliminar pide confirmar y nombra la franja', (tester) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.tap(
        find.byTooltip(
          RegExp('Delete the slot for Monterrico, Mon–Fri'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete this time slot?'), findsOneWidget);
      expect(find.textContaining('Monterrico · Mon–Fri'), findsOneWidget);
      verifyNever(() => alerts.removeSubscription(any()));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => alerts.removeSubscription(any())).called(1);
    });

    testWidgets('cancelar la confirmación no elimina nada', (tester) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.tap(
        find.byTooltip(RegExp('Delete the slot for Monterrico, Mon–Fri')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => alerts.removeSubscription(any()));
    });

    testWidgets('los avisos del cubit salen como mensaje emergente', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(s.overview()));

      notices.add(AlertsNotice.permissionBlocked);
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          "Notifications are blocked. Turn them on in your phone's settings.",
        ),
        findsOneWidget,
      );
    });
  });

  group('Nueva franja', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpPage(tester, ViewData(s.overview()));
      await tester.ensureVisible(find.text('Add a time slot'));
      await tester.tap(find.text('Add a time slot'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre con la sede elegida y explica el permiso', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('New time slot'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Monterrico'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Monterrico'))
            .selected,
        isTrue,
      );
      expect(
        find.textContaining("We'll ask for the notifications permission"),
        findsOneWidget,
      );
    });

    testWidgets('sin días ni horas dice qué falta y no llama al cubit', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Add time slot'));
      await tester.pumpAndSettle();
      expect(find.text('Pick at least one day.'), findsOneWidget);

      await tester.tap(find.text('Mon'));
      await tester.tap(find.text('Add time slot'));
      await tester.pumpAndSettle();
      expect(find.text('Pick a start and an end time.'), findsOneWidget);

      verifyNever(() => alerts.createSubscription(any()));
    });

    testWidgets('una hora de fin igual al inicio no es válida', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Mon'));
      await tester.tap(find.bySemanticsLabel(RegExp('^From')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^To')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add time slot'));
      await tester.pumpAndSettle();

      expect(
        find.text('The end time must be after the start.'),
        findsOneWidget,
      );
      verifyNever(() => alerts.createSubscription(any()));
    });

    testWidgets('con días y horas válidos crea la franja y se cierra', (
      tester,
    ) async {
      when(() => alerts.createSubscription(any())).thenAnswer(
        (_) async => Success(
          CreatedAlertSubscription(
            subscription: s.subscription(id: 9),
            device: DeviceActivation.registered,
          ),
        ),
      );
      await openSheet(tester);
      await tester.tap(find.text('Mon'));
      await tester.pump();
      await tester.tap(find.text('Wed'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'San Isidro'));
      await tester.tap(find.bySemanticsLabel(RegExp('^From')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^To')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add time slot'));
      await tester.pumpAndSettle();

      final params =
          verify(() => alerts.createSubscription(captureAny())).captured.single
              as CreateAlertSubscriptionParams;
      expect(params.lotId, const LotId(2));
      expect(params.days, {1, 3});
      expect(params.from, s.time(8, 0));
      expect(params.to, s.time(20, 0));
      expect(find.text('New time slot'), findsNothing);
    });

    testWidgets('una franja repetida se dice dentro de la ventana', (
      tester,
    ) async {
      when(() => alerts.createSubscription(any())).thenAnswer(
        (_) async => const Err(
          ValidationFailure('x', {
            'slot': ['duplicate'],
          }),
        ),
      );
      await openSheet(tester);
      await tester.tap(find.text('Mon'));
      await tester.tap(find.bySemanticsLabel(RegExp('^From')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^To')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add time slot'));
      await tester.pumpAndSettle();

      expect(find.text('You already follow this time slot.'), findsOneWidget);
      expect(find.text('New time slot'), findsOneWidget);
    });
  });
}
