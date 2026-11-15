// US21, US22, US34, TS11: reglas del dominio y casos de uso de Analytics.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/report_exporter.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

class _MockReader extends Mock implements AnalyticsReader {}

class _MockExporter extends Mock implements ReportExporter {}

const Duration _lima = Duration(hours: -5);
const LotId _lot = LotId(1);

AccuracyResult _result(
  String version,
  int horizon,
  double? within, {
  bool computable = true,
}) => AccuracyResult(
  modelVersion: version,
  horizonMinutes: horizon,
  computable: computable,
  withinMarginPct: within,
  maePoints: within == null ? null : (100 - within) / 4,
);

void main() {
  setUpAll(() {
    registerFallbackValue(OccupancyGranularity.hour);
    registerFallbackValue(
      AnalyticsRange.of(DateTime.utc(2026), DateTime.utc(2026, 2)),
    );
  });

  group('AnalyticsRange', () {
    // 08:42 en Lima del lunes 28 de setiembre.
    final now = DateTime.utc(2026, 9, 28, 13, 42);

    test('hoy empieza a la medianoche de Lima y termina ahora', () {
      final range = AnalyticsRange.forPeriod(
        AnalyticsPeriod.today,
        now: now,
        utcOffset: _lima,
      );
      expect(range.from, DateTime.utc(2026, 9, 28, 5));
      expect(range.to, now);
    });

    test('7 y 30 días cuentan hoy como el último día', () {
      final week = AnalyticsRange.forPeriod(
        AnalyticsPeriod.last7Days,
        now: now,
        utcOffset: _lima,
      );
      final month = AnalyticsRange.forPeriod(
        AnalyticsPeriod.last30Days,
        now: now,
        utcOffset: _lima,
      );
      expect(week.from, DateTime.utc(2026, 9, 22, 5));
      expect(month.from, DateTime.utc(2026, 8, 30, 5));
    });

    test('justo después de la medianoche de Lima ya es el día nuevo', () {
      final range = AnalyticsRange.forPeriod(
        AnalyticsPeriod.today,
        now: DateTime.utc(2026, 9, 29, 5, 1),
        utcOffset: _lima,
      );
      expect(range.from, DateTime.utc(2026, 9, 29, 5));
    });

    test('un rango cuyo inicio no es anterior al fin no es válido '
        '(TS11 esc. 2)', () {
      final day = DateTime.utc(2026, 9, 28);
      expect(AnalyticsRange.of(day, day), isNull);
      expect(AnalyticsRange.of(day.add(const Duration(hours: 1)), day), isNull);
    });

    test('un rango de días incluye el último día completo', () {
      final range = AnalyticsRange.days(
        DateTime(2026, 9),
        DateTime(2026, 9, 14),
        utcOffset: _lima,
      )!;
      expect(range.from, DateTime.utc(2026, 9, 1, 5));
      expect(range.to, DateTime.utc(2026, 9, 15, 5));
      expect(
        AnalyticsRange.days(
          DateTime(2026, 9, 14),
          DateTime(2026, 9),
          utcOffset: _lima,
        ),
        isNull,
      );
    });

    test('hasta un día se agrega por hora; más, por día', () {
      expect(
        OccupancyGranularity.forLength(const Duration(hours: 9)),
        OccupancyGranularity.hour,
      );
      expect(
        OccupancyGranularity.forLength(const Duration(days: 7)),
        OccupancyGranularity.day,
      );
    });
  });

  group('OccupancyHistory', () {
    test('ordena los puntos y resume el periodo (US21)', () {
      final history = OccupancyHistory(
        lotId: _lot,
        range: AnalyticsRange.of(DateTime.utc(2026), DateTime.utc(2026, 2))!,
        granularity: OccupancyGranularity.day,
        serverTime: DateTime.utc(2026, 2),
        points: [
          OccupancyPoint(at: DateTime.utc(2026, 1, 2), occupancyPct: 80),
          OccupancyPoint(at: DateTime.utc(2026), occupancyPct: 40),
        ],
      );
      expect(history.points.first.at, DateTime.utc(2026));
      expect(history.peak!.occupancyPct, 80);
      expect(history.average, 60);
      expect(history.isEmpty, isFalse);
    });
  });

  group('PeakHours (US22)', () {
    test('ordena las franjas de mayor a menor ocupación', () {
      final peaks = PeakHours(
        sufficientData: true,
        peaks: const [
          PeakWindow(startMinute: 960, endMinute: 1020, avgOccupancyPct: 70),
          PeakWindow(startMinute: 600, endMinute: 690, avgOccupancyPct: 92),
        ],
      );
      expect(peaks.top!.startMinute, 600);
    });

    test('sin datos suficientes no hay franjas (esc. 3)', () {
      final peaks = PeakHours(
        sufficientData: false,
        peaks: const [
          PeakWindow(startMinute: 600, endMinute: 690, avgOccupancyPct: 92),
        ],
      );
      expect(peaks.peaks, isEmpty);
      expect(peaks.top, isNull);
    });
  });

  group('ForecastAccuracy (US34)', () {
    test('presenta la versión más reciente y su promedio global (esc. 1)', () {
      final accuracy = ForecastAccuracy([
        _result('v2.3', 15, 80),
        _result('v2.3', 30, 70),
        _result('v3.0', 30, 86),
        _result('v3.0', 15, 90),
      ]);
      final current = accuracy.current!;
      expect(current.modelVersion, 'v3.0');
      expect(current.results.map((r) => r.horizonMinutes), [15, 30]);
      expect(current.withinMarginPct, 88);
      expect(current.maePoints, 3);
      expect(accuracy.previous!.modelVersion, 'v2.3');
      expect(accuracy.previous!.withinMarginPct, 75);
    });

    test('un horizonte no calculable no entra en el promedio', () {
      final accuracy = ForecastAccuracy([
        _result('v3.0', 15, 90),
        _result('v3.0', 60, null, computable: false),
      ]);
      expect(accuracy.current!.withinMarginPct, 90);
      expect(accuracy.previous, isNull);
    });

    test('un periodo sin nada calculable lo dice (esc. 3)', () {
      final accuracy = ForecastAccuracy([
        _result('v3.0', 15, null, computable: false),
      ]);
      expect(accuracy.isComputable, isFalse);
      expect(accuracy.current, isNull);
    });
  });

  group('ReportRequest', () {
    test('un reporte sin contenido no es válido', () {
      final range = AnalyticsRange.of(
        DateTime.utc(2026),
        DateTime.utc(2026, 2),
      )!;
      final empty = ReportRequest.create(
        lotId: _lot,
        range: range,
        sections: const {},
        format: ReportFormat.pdf,
      );
      expect(empty.failureOrNull, isA<ValidationFailure>());

      final ok = ReportRequest.create(
        lotId: _lot,
        range: range,
        sections: const {ReportSection.accuracy},
        format: ReportFormat.csv,
      );
      expect(ok.valueOrNull?.sections, {ReportSection.accuracy});
    });
  });

  group('casos de uso', () {
    late _MockReader reader;

    setUp(() => reader = _MockReader());

    test('GetOccupancyHistory pide por hora un día y por día una semana '
        '(TS11 esc. 1)', () async {
      when(
        () => reader.occupancy(
          lotId: any(named: 'lotId'),
          range: any(named: 'range'),
          granularity: any(named: 'granularity'),
          zoneId: any(named: 'zoneId'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      final useCase = GetOccupancyHistory(reader);
      final day = AnalyticsRange.of(
        DateTime.utc(2026, 9, 28, 5),
        DateTime.utc(2026, 9, 28, 13),
      )!;
      final week = AnalyticsRange.of(
        DateTime.utc(2026, 9, 22, 5),
        DateTime.utc(2026, 9, 28, 13),
      )!;

      await useCase((lotId: _lot, range: day, zoneId: const ZoneId(10)));
      await useCase((lotId: _lot, range: week, zoneId: null));

      verify(
        () => reader.occupancy(
          lotId: _lot,
          range: day,
          granularity: OccupancyGranularity.hour,
          zoneId: const ZoneId(10),
        ),
      ).called(1);
      verify(
        () => reader.occupancy(
          lotId: _lot,
          range: week,
          granularity: OccupancyGranularity.day,
        ),
      ).called(1);
    });

    test('ExportAnalyticsReport entrega la solicitud al exportador', () async {
      final exporter = _MockExporter();
      final request = ReportRequest.create(
        lotId: _lot,
        range: AnalyticsRange.of(DateTime.utc(2026), DateTime.utc(2026, 2))!,
        sections: const {ReportSection.occupancy},
        format: ReportFormat.pdf,
      ).valueOrNull!;
      when(() => exporter.export(request)).thenAnswer(
        (_) async => const Success(ReportDelivery(sentTo: 'a•••@upc.edu.pe')),
      );

      final result = await ExportAnalyticsReport(exporter)(request);

      expect(result.valueOrNull?.sentTo, 'a•••@upc.edu.pe');
    });
  });
}
