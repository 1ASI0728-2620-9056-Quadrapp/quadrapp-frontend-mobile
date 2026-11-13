// US17: el borrador de la distribución y su publicación.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_draft_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_publisher.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

const LotId _lot = LotId(1);

/// Zona Central (C-139, C-140) en un nivel y Zona Norte (N-01) en dos.
LotLayout _base() => const LotLayout(
  lotId: _lot,
  version: 4,
  zones: [
    Zone(
      id: ZoneId(10),
      name: 'Zona Central',
      levels: [
        Level(
          id: LevelId(100),
          name: 'Superficie',
          spaces: [
            Space(id: SpaceId(1), label: 'C-139'),
            Space(id: SpaceId(2), label: 'C-140'),
          ],
        ),
      ],
    ),
    Zone(
      id: ZoneId(11),
      name: 'Zona Norte',
      levels: [
        Level(
          id: LevelId(110),
          name: 'Piso 1',
          spaces: [Space(id: SpaceId(3), label: 'N-01')],
        ),
        Level(id: LevelId(111), name: 'Piso 2', spaces: []),
      ],
    ),
  ],
);

LayoutDraft _applied(DraftEdit edit) => switch (edit) {
  DraftApplied(:final draft) => draft,
  DraftRejected(:final error) => fail('rechazado: $error'),
};

DraftError? _error(DraftEdit edit) => switch (edit) {
  DraftApplied() => null,
  DraftRejected(:final error) => error,
};

class _MockPublisher extends Mock implements LayoutPublisher {}

class _MockStore extends Mock implements LayoutDraftStore {}

void main() {
  final base = _base();
  const empty = LayoutDraft(lotId: _lot, baseVersion: 4);

  group('LayoutDraft', () {
    test('una zona nueva nace con su nivel y códigos libres del nombre', () {
      final draft = _applied(
        empty.addZone(
          base,
          name: 'Zona Este',
          levelName: 'Sótano 1',
          initialSpaces: 3,
        ),
      );
      final zone = draft.applyTo(base).zones.last;

      expect(zone.isNew, isTrue);
      expect(zone.levels.single.name, 'Sótano 1');
      expect(zone.spaces.map((s) => s.label), ['E-01', 'E-02', 'E-03']);
      expect(draft.targetVersion, 5);
    });

    test('nombres de zona y códigos son únicos sin distinguir mayúsculas', () {
      expect(
        _error(
          empty.addZone(
            base,
            name: 'zona central',
            levelName: 'Piso 1',
            initialSpaces: 1,
          ),
        ),
        DraftError.zoneNameTaken,
      );
      expect(
        _error(empty.addSpace(base, zoneKey: 'z10', label: 'c-140')),
        DraftError.labelTaken,
      );
      expect(
        _error(
          empty.addZone(
            base,
            name: 'Zona Sur',
            levelName: 'Piso 1',
            initialSpaces: 0,
          ),
        ),
        DraftError.spacesOutOfRange,
      );
    });

    test('con varios niveles hay que elegir uno; se sugiere el código '
        'siguiente', () {
      expect(
        _error(empty.addSpace(base, zoneKey: 'z11', label: 'N-02')),
        DraftError.levelRequired,
      );
      expect(empty.suggestLabel(base, 'z10'), 'C-141');
      expect(empty.suggestLabel(base, 'z11'), 'N-02');
    });

    test('deshabilitar saca del aforo; deshacer lo revierte', () {
      final draft = empty.setEnabled(base, spaceKey: 's2', enabled: false);
      final summary = draft.summary(base);

      expect(summary.spacesBefore, 3);
      expect(summary.spacesAfter, 2);
      expect(summary.disabledLabels, ['C-140']);
      expect(draft.undo().isEmpty, isTrue);
      expect(draft.undo().summary(base).spacesAfter, 3);
    });

    test('el plan es el efecto neto: lo deshabilitado y vuelto a habilitar '
        'no viaja', () {
      var draft = _applied(
        empty.addSpace(
          base,
          zoneKey: 'z10',
          label: 'C-141',
          type: SpaceType.accessible,
        ),
      );
      draft = draft
          .setEnabled(base, spaceKey: 's1', enabled: false)
          .setEnabled(base, spaceKey: 's1', enabled: true);
      draft = _applied(
        draft.editSpace(
          base,
          spaceKey: 's3',
          label: 'N-001',
          type: SpaceType.standard,
        ),
      );
      final plan = draft.plan(base);

      expect(plan.baseVersion, 4);
      expect(plan.newSpaces.single.levelId, const LevelId(100));
      expect(plan.newSpaces.single.type, SpaceType.accessible);
      expect(plan.disabledSpaceIds, isEmpty);
      expect(plan.editedSpaces.single.label, 'N-001');
    });
  });

  group('PublishLayout', () {
    late _MockPublisher publisher;
    late _MockStore store;

    setUpAll(() {
      registerFallbackValue(empty.plan(base));
      registerFallbackValue(_lot);
    });

    setUp(() {
      publisher = _MockPublisher();
      store = _MockStore();
      when(() => store.clear(any())).thenAnswer((_) async {});
    });

    test('publica el plan y borra el borrador del teléfono', () async {
      when(
        () => publisher.publish(any()),
      ).thenAnswer((_) async => const Success(5));
      final draft = empty.setEnabled(base, spaceKey: 's1', enabled: false);

      final result = await PublishLayout(publisher: publisher, store: store)((
        draft: draft,
        base: base,
      ));

      expect(result, const Success(5));
      verify(() => store.clear(_lot)).called(1);
    });

    test('con 409 (otra persona publicó antes) el borrador queda', () async {
      when(
        () => publisher.publish(any()),
      ).thenAnswer((_) async => const Err(ValidationFailure('conflict')));
      final draft = empty.setEnabled(base, spaceKey: 's1', enabled: false);

      final result = await PublishLayout(publisher: publisher, store: store)((
        draft: draft,
        base: base,
      ));

      expect(result, isA<Err<int>>());
      verifyNever(() => store.clear(any()));
    });

    test('un borrador sin cambios no llama al servidor', () async {
      await PublishLayout(publisher: publisher, store: store)((
        draft: empty,
        base: base,
      ));

      verifyNever(() => publisher.publish(any()));
    });
  });
}
