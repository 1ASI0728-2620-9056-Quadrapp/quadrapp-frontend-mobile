// US13 (mapa de la llegada); TS08: la posición solo se usa con el ETA
// automático y el permiso, y nunca se pide desde el mapa.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_map_card.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_map_cubit.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../contexts/parking_configuration/support.dart';
import '../../helpers/pump_screen.dart';

class _MockGetPosition extends Mock implements GetApproximatePosition {}

const _origin = GeoPoint(latitude: -12.09, longitude: -77.05);

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  late _MockGetPosition getPosition;
  late ArrivalMapCubit cubit;

  setUp(() {
    getPosition = _MockGetPosition();
    when(
      () => getPosition(any()),
    ).thenAnswer((_) async => const Success(_origin));
    cubit = ArrivalMapCubit(getPosition: getPosition);
  });

  tearDown(() => cubit.close());

  group('ArrivalMapCubit', () {
    test('sin usar la ubicación: solo la sede, sin leer la posición', () async {
      await cubit.sync(lot: lotEntity(1), useLocation: false);

      expect(cubit.state.destination, isNotNull);
      expect(cubit.state.origin, isNull);
      verifyNever(() => getPosition(any()));
    });

    test('con la ubicación: la sede y la posición aproximada', () async {
      await cubit.sync(lot: lotEntity(1), useLocation: true);

      expect(cubit.state.origin, _origin);
    });

    test('sede sin coordenadas: no hay mapa', () async {
      await cubit.sync(
        lot: lotEntity(3, latitude: null, longitude: null),
        useLocation: true,
      );

      expect(cubit.state.hasMap, isFalse);
      verifyNever(() => getPosition(any()));
    });
  });

  group('embeddedMapUri', () {
    const destination = GeoPoint(latitude: -12.1035, longitude: -76.963);

    test('solo la sede: un marcador, sin clave', () {
      final uri = embeddedMapUri(
        const ArrivalMapState(destination: destination),
        'es',
      );
      expect(uri.host, 'maps.google.com');
      expect(uri.queryParameters, {
        'q': '-12.1035,-76.963',
        'z': '16',
        'hl': 'es',
        'output': 'embed',
      });
    });

    test('con la posición: la ruta desde ella', () {
      final uri = embeddedMapUri(
        const ArrivalMapState(destination: destination, origin: _origin),
        'en',
      );
      expect(uri.queryParameters['saddr'], '-12.09,-77.05');
      expect(uri.queryParameters['daddr'], '-12.1035,-76.963');
      expect(uri.queryParameters, isNot(contains('q')));
    });
  });

  group('ArrivalMapCard', () {
    Future<void> pump(WidgetTester tester, {Locale? locale}) => pumpScreen(
      tester,
      BlocProvider<ArrivalMapCubit>.value(
        value: cubit,
        child: const SingleChildScrollView(child: ArrivalMapCard()),
      ),
      locale: locale ?? const Locale('en'),
    );

    testWidgets('sin mapa no ocupa lugar', (tester) async {
      await pump(tester);
      expect(find.text('Getting there'), findsNothing);
    });

    testWidgets('dice qué recibe Google, con y sin la ubicación', (
      tester,
    ) async {
      await cubit.sync(lot: lotEntity(1), useLocation: false);
      await pump(tester);
      expect(find.text('Getting there'), findsOneWidget);
      expect(find.textContaining("your location isn't used"), findsOneWidget);

      await cubit.sync(lot: lotEntity(1), useLocation: true);
      await tester.pumpAndSettle();
      expect(find.textContaining('about 100 m'), findsOneWidget);
    });

    testWidgets('sin WebView (pruebas) muestra el aviso, accesible', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await cubit.sync(lot: lotEntity(1), useLocation: false);
      await pump(tester, locale: const Locale('es'));

      expect(find.text('Cómo llegar'), findsOneWidget);
      expect(
        find.text('El mapa no está disponible en este momento.'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('al tocarla se abre a pantalla completa', (tester) async {
      await cubit.sync(lot: lotEntity(1), useLocation: false);
      await pump(tester);

      await tester.tap(find.text('Getting there'));
      await tester.pumpAndSettle();

      expect(find.byType(ArrivalMapPage), findsOneWidget);
      expect(find.text('Estacionamiento 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ArrivalMapPage), findsNothing);
    });
  });
}
