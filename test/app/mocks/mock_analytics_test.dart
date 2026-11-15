// Datos de prueba de Analítica: 403, rango inválido, sin registros, horas
// pico y precisión por versión del modelo (US21, US22, US34, TS11).
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/analytics/mock_analytics_datasource.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

// 08:42 en Lima del lunes 28 de setiembre.
final DateTime _now = DateTime.utc(2026, 9, 28, 13, 42);
final DateTime _todayFrom = DateTime.utc(2026, 9, 28, 5);
final DateTime _monthFrom = DateTime.utc(2026, 8, 30, 5);

MockAnalyticsRemoteDataSource _source({String? role = 'ADMIN'}) {
  final world = MockWorld(
    seed: testSeed,
    clock: FakeClock(_now),
    random: Random(1),
    latency: false,
  );
  return MockAnalyticsRemoteDataSource(world, () => role);
}

Future<int?> _statusOf(Future<void> Function() call) async {
  try {
    await call();
    return null;
  } on DioException catch (error) {
    return error.response?.statusCode;
  }
}

void main() {
  test(
    'un conductor recibe 403 y un rango invertido, 400 (TS11 esc. 2)',
    () async {
      expect(
        await _statusOf(
          () => _source(role: 'DRIVER').peaks(
            lotId: const LotId(1),
            from: _todayFrom,
            to: _now,
          ),
        ),
        403,
      );
      expect(
        await _statusOf(
          () => _source().accuracy(
            lotId: const LotId(1),
            from: _now,
            to: _todayFrom,
          ),
        ),
        400,
      );
    },
  );

  test(
    'hoy va por hora desde las 06:00 y sube hacia el pico de la mañana',
    () async {
      final history = await _source().occupancy(
        lotId: const LotId(1),
        from: _todayFrom,
        to: _now,
        granularity: 'HOUR',
      );
      // 06:00, 07:00 y 08:00 de Lima.
      expect(history.points, hasLength(3));
      expect(history.points.first.at, DateTime.utc(2026, 9, 28, 11));
      final values = [for (final p in history.points) p.occupancyPct];
      expect(values, orderedEquals([...values]..sort()));
    },
  );

  test('30 días va por día y los fines de semana son más bajos', () async {
    final history = await _source().occupancy(
      lotId: const LotId(1),
      from: _monthFrom,
      to: _now,
      granularity: 'DAY',
    );
    expect(history.points, hasLength(30));
    OccupancyPointDto on(int month, int day) => history.points.firstWhere(
      (p) => p.at == DateTime.utc(2026, month, day, 5),
    );
    // Domingo 27 contra viernes 25.
    expect(on(9, 27).occupancyPct, lessThan(on(9, 25).occupancyPct / 2));
  });

  test('sin distribución no hay registros ni horas pico ni precisión '
      '(US21, US22 y US34 esc. 3)', () async {
    final source = _source();
    const lot = LotId(3);
    final history = await source.occupancy(
      lotId: lot,
      from: _monthFrom,
      to: _now,
      granularity: 'DAY',
    );
    final peaks = await source.peaks(lotId: lot, from: _monthFrom, to: _now);
    final accuracy = await source.accuracy(
      lotId: lot,
      from: _monthFrom,
      to: _now,
    );
    expect(history.points, isEmpty);
    expect(peaks.sufficientData, isFalse);
    expect(accuracy.every((r) => !r.computable), isTrue);
  });

  test(
    'las horas pico de Monterrico están a media mañana (US22 esc. 1)',
    () async {
      final peaks = await _source().peaks(
        lotId: const LotId(1),
        from: _monthFrom,
        to: _now,
      );
      expect(peaks.sufficientData, isTrue);
      expect(
        peaks.peaks.first.startTime.compareTo('09:00'),
        greaterThanOrEqualTo(0),
      );
      expect(
        peaks.peaks.first.endTime.compareTo('12:30'),
        lessThanOrEqualTo(0),
      );
    },
  );

  test('30 días distinguen dos versiones del modelo; 7 días, una '
      '(US34 esc. 2)', () async {
    final source = _source();
    final month = await source.accuracy(
      lotId: const LotId(1),
      from: _monthFrom,
      to: _now,
    );
    final week = await source.accuracy(
      lotId: const LotId(1),
      from: DateTime.utc(2026, 9, 22, 5),
      to: _now,
    );
    expect(month.map((r) => r.modelVersion).toSet(), {'v2.3', 'v3.0'});
    expect(week.map((r) => r.modelVersion).toSet(), {'v3.0'});
  });

  test('en Villa los horizontes largos no son calculables', () async {
    final results = await _source().accuracy(
      lotId: const LotId(4),
      from: _monthFrom,
      to: _now,
    );
    expect(
      {for (final r in results) r.horizon: r.computable},
      {15: true, 30: true, 45: false, 60: false},
    );
  });

  test('el reporte se envía al correo y sin contenido responde 400', () async {
    final source = _source();
    final delivery = await source.exportReport(
      ReportRequestDto(
        lotId: 1,
        from: _monthFrom,
        to: _now,
        sections: const ['OCCUPANCY'],
        format: 'PDF',
      ),
    );
    expect(delivery.sentTo, endsWith('@upc.edu.pe'));
    expect(
      await _statusOf(
        () => source.exportReport(
          ReportRequestDto(
            lotId: 1,
            from: _monthFrom,
            to: _now,
            sections: const [],
            format: 'PDF',
          ),
        ),
      ),
      400,
    );
  });
}
