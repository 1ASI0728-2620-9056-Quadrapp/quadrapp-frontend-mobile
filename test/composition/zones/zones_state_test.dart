// US06, US08: la disponibilidad de un pabellón o un nivel y el orden de Zonas.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';

import 'support.dart';

void main() {
  group('AreaCounts.availability (umbral de saturación de la sede)', () {
    SpaceAvailability of(int free, int occupied, int unknown, [int pct = 90]) =>
        AreaCounts(
          free: free,
          occupied: occupied,
          unknown: unknown,
        ).availability(pct);

    test('con espacios por debajo del umbral es buena', () {
      expect(of(45, 72, 3), SpaceAvailability.good);
    });

    test('justo en el umbral (90 %) ya es limitada; por debajo, no', () {
      expect(of(1, 9, 0), SpaceAvailability.limited);
      expect(of(11, 89, 0), SpaceAvailability.good);
    });

    test('usa el umbral de la sede, no uno fijo', () {
      expect(of(3, 2, 0, 40), SpaceAvailability.limited);
      expect(of(3, 2, 0), SpaceAvailability.good);
    });

    test('sin ningún libre es llena', () {
      expect(of(0, 78, 2), SpaceAvailability.full);
    });

    test('los sin datos no cuentan ni como libres ni como ocupados', () {
      expect(of(0, 0, 20), SpaceAvailability.noData);
      // 1 libre y 1 ocupado: 50 % ocupado, aunque haya 18 sin datos.
      expect(of(1, 1, 18), SpaceAvailability.good);
    });
  });

  group('arrangeZones', () {
    List<String> names(ZonesOverview overview, ZoneListOptions options) => [
      for (final zone in arrangeZones(overview, options)) zone.name,
    ];

    test('por pabellón respeta el orden de la sede', () {
      expect(names(overview(), const ZoneListOptions()), [
        'Pabellón A',
        'Pabellón B',
      ]);
    });

    test('con más libres primero; a igualdad, el orden de la sede', () {
      // B con 2 libres y A con 1: B sube.
      final mostFree = overview(
        lotOccupancy: occupancy(
          spaces: [
            state(1, SpaceStatus.free),
            state(2, SpaceStatus.occupied),
            state(3, SpaceStatus.occupied),
            state(4, SpaceStatus.occupied),
            state(5, SpaceStatus.occupied),
            state(6, SpaceStatus.occupied),
            state(7, SpaceStatus.free),
            state(8, SpaceStatus.free),
          ],
        ),
      );
      expect(
        names(mostFree, const ZoneListOptions(order: ZoneOrder.mostFree)),
        ['Pabellón B', 'Pabellón A'],
      );
      // A y B con 1 libre cada uno: queda el orden de la sede.
      final tie = overview(
        lotOccupancy: occupancy(
          spaces: [
            state(1, SpaceStatus.free),
            for (var id = 2; id <= 6; id++) state(id, SpaceStatus.occupied),
            state(7, SpaceStatus.free),
            state(8, SpaceStatus.occupied),
          ],
        ),
      );
      expect(names(tie, const ZoneListOptions(order: ZoneOrder.mostFree)), [
        'Pabellón A',
        'Pabellón B',
      ]);
    });

    test('«solo con libres» oculta el pabellón sin espacios libres', () {
      expect(names(overview(), const ZoneListOptions(onlyWithFree: true)), [
        'Pabellón A',
      ]);
    });

    test('sin ocupación no se ordena ni se filtra', () {
      final withoutOccupancy = ZonesOverview(lot: lot(), layout: layout());
      expect(
        names(
          withoutOccupancy,
          const ZoneListOptions(
            order: ZoneOrder.mostFree,
            onlyWithFree: true,
          ),
        ),
        ['Pabellón A', 'Pabellón B'],
      );
    });
  });
}
