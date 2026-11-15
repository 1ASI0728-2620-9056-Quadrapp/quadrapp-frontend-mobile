import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../../helpers/pump_app.dart';

List<QaSpaceCell> _cells({QaSpaceState first = QaSpaceState.free}) => [
  QaSpaceCell(id: 1, x: 0, y: 0, state: first),
  const QaSpaceCell(id: 2, x: 1, y: 0, state: QaSpaceState.occupied),
  const QaSpaceCell(id: 3, x: 2, y: 0, state: QaSpaceState.unknown),
  const QaSpaceCell(id: 4, x: 0, y: 1, state: QaSpaceState.occupied),
];

const _zone = QaZoneSummary(
  name: 'Zone A',
  freeText: '1 free',
  occupiedText: '2 occupied',
  unknownText: '1 no data',
  semanticLabel: 'Zone A: 1 free, 2 occupied, 1 with no data',
);

const _legend = QaSpaceLegend(
  free: 'Free',
  occupied: 'Occupied',
  unknown: 'No data',
);

Widget _map(List<QaSpaceCell> cells, {bool isStale = false}) => QaSpaceMap(
  cells: cells,
  zones: const [_zone],
  summaryLabel: 'Parking map: 1 free, 2 occupied, 1 with no data',
  legend: _legend,
  isStale: isStale,
);

void main() {
  Future<ValueNotifier<List<QaSpaceCell>>> pumpLive(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    final cells = ValueNotifier(_cells());
    addTearDown(cells.dispose);
    await pumpInApp(
      tester,
      ValueListenableBuilder<List<QaSpaceCell>>(
        valueListenable: cells,
        builder: (context, value, _) => _map(value),
      ),
      disableAnimations: disableAnimations,
    );
    return cells;
  }

  testWidgets('muestra leyenda y la lista alternativa de zonas', (
    tester,
  ) async {
    await pumpInApp(tester, _map(_cells()));

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
    expect(find.text('Zone A'), findsOneWidget);
    expect(find.text('2 occupied'), findsOneWidget);
  });

  testWidgets('el lienzo se lee como un resumen, anunciado como región viva, '
      'y las zonas como texto', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(tester, _map(_cells()));

    final summary = tester.getSemantics(
      find.bySemanticsLabel('Parking map: 1 free, 2 occupied, 1 with no data'),
    );

    expect(summary.flagsCollection.isLiveRegion, isTrue);
    expect(
      find.bySemanticsLabel('Zone A: 1 free, 2 occupied, 1 with no data'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('un espacio que cambia de estado hace un pulso de 400 ms', (
    tester,
  ) async {
    final cells = await pumpLive(tester, disableAnimations: false);
    expect(tester.hasRunningAnimations, isFalse);

    cells.value = _cells(first: QaSpaceState.occupied);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('sin animaciones (ajuste del sistema) no hay pulso', (
    tester,
  ) async {
    final cells = await pumpLive(tester, disableAnimations: true);

    cells.value = _cells(first: QaSpaceState.occupied);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('cargando muestra skeleton con su etiqueta', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(tester, const QaSpaceMap.loading(semanticLabel: 'Loading'));

    expect(find.byType(QaSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('desactualizado pinta el marco con el tono limitada', (
    tester,
  ) async {
    await pumpInApp(tester, _map(_cells(), isStale: true));

    final widths = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border is Border)
        .map((d) => (d.border! as Border).top.width);

    expect(widths, contains(2));
  });

  test('QaSpaceCell compara por valor', () {
    const a = QaSpaceCell(id: 1, x: 0, y: 0, state: QaSpaceState.free);
    const b = QaSpaceCell(id: 1, x: 0, y: 0, state: QaSpaceState.free);
    const c = QaSpaceCell(id: 1, x: 0, y: 0, state: QaSpaceState.occupied);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
