import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/level.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/space.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/zone.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import 'support.dart';

void main() {
  group('ParkingLot', () {
    test('hasPublishedLayout: versión 0 es sin distribución publicada', () {
      expect(lotEntity(1).hasPublishedLayout, isTrue);
      expect(lotEntity(1, layoutVersion: 0).hasPublishedLayout, isFalse);
    });

    test('hasCoordinates: sin coordenadas no hay ETA en el dispositivo', () {
      expect(lotEntity(1).hasCoordinates, isTrue);
      expect(lotEntity(1, latitude: null).hasCoordinates, isFalse);
      expect(lotEntity(1, longitude: null).hasCoordinates, isFalse);
    });

    test('compara por valor', () {
      expect(lotEntity(1), lotEntity(1));
      expect(lotEntity(1), isNot(lotEntity(2)));
      expect(lotEntity(1), isNot(lotEntity(1, layoutVersion: 5)));
    });
  });

  group('Space', () {
    test('hasPosition necesita las dos coordenadas', () {
      expect(
        const Space(
          id: SpaceId(1),
          label: 'A-01',
          posX: 0,
          posY: 1,
        ).hasPosition,
        isTrue,
      );
      expect(
        const Space(id: SpaceId(1), label: 'A-01', posX: 0).hasPosition,
        isFalse,
      );
    });
  });

  group('LotLayout', () {
    test('spaceCount suma los espacios de todas las zonas', () {
      expect(sampleLayout().spaceCount, 4);
    });

    test('levelMembership da solo identificadores, por nivel', () {
      expect(sampleLayout().levelMembership, const {
        LevelId(100): [SpaceId(1), SpaceId(2)],
        LevelId(110): [SpaceId(3)],
        LevelId(111): [SpaceId(4)],
      });
      expect(sampleLayout().levels.map((l) => l.name), [
        'Sótano 1',
        'Piso 1',
        'Piso 2',
      ]);
    });

    test('membership da solo identificadores, por zona', () {
      expect(sampleLayout().membership, const {
        ZoneId(10): [SpaceId(1), SpaceId(2)],
        ZoneId(11): [SpaceId(3), SpaceId(4)],
      });
    });

    test('canDrawMap exige posición en todos los espacios', () {
      expect(sampleLayout().canDrawMap, isTrue);
      expect(sampleLayout(withPositions: false).canDrawMap, isFalse);
    });

    test('canDrawMap es falso si falta la posición de uno solo', () {
      const layout = LotLayout(
        lotId: LotId(1),
        version: 1,
        zones: [
          Zone(
            id: ZoneId(10),
            name: 'A',
            levels: [
              Level(
                id: LevelId(100),
                name: 'Piso 1',
                spaces: [
                  Space(id: SpaceId(1), label: 'A-01', posX: 0, posY: 0),
                  Space(id: SpaceId(2), label: 'A-02'),
                ],
              ),
            ],
          ),
        ],
      );

      expect(layout.canDrawMap, isFalse);
    });

    test('una distribución vacía no se puede dibujar', () {
      const empty = LotLayout(lotId: LotId(3), version: 1, zones: []);

      expect(empty.canDrawMap, isFalse);
      expect(empty.spaceCount, 0);
      expect(empty.membership, isEmpty);
      expect(empty.levelMembership, isEmpty);
    });
  });
}
