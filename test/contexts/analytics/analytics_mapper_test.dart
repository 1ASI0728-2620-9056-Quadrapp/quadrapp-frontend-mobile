// US21, US22, US34, TS11: mapper y repositorio de Analytics (caso feliz,
// error de red y valores desconocidos del servidor).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/mappers/analytics_mapper.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/repositories/analytics_repositories.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/recording_logger.dart';

class _MockRemote extends Mock implements AnalyticsRemoteDataSource {}

const LotId _lot = LotId(1);
final AnalyticsRange _range = AnalyticsRange.of(
  DateTime.utc(2026, 9, 28, 5),
  DateTime.utc(2026, 9, 28, 13, 42),
)!;

void main() {
  late RecordingLogger logger;
  late AnalyticsMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = AnalyticsMapper(logger);
  });

  test('lee el historial, las horas pico y la precisión (caso feliz)', () {
    final history = mapper.toHistory(
      OccupancyHistoryDto.fromJson({
        'serverTime': '2026-09-28T13:42:00Z',
        'granularity': 'HOUR',
        'points': [
          {'at': '2026-09-28T12:00:00Z', 'occupancyPct': 61.5},
          {'at': '2026-09-28T11:00:00Z', 'occupancyPct': 40},
        ],
      }),
      lotId: _lot,
      range: _range,
      requested: OccupancyGranularity.hour,
      zoneId: const ZoneId(10),
    );
    expect(history.zoneId, const ZoneId(10));
    expect(history.points.map((p) => p.occupancyPct), [40, 61.5]);

    final peaks = mapper.toPeaks(
      PeakHoursDto.fromJson({
        'sufficientData': true,
        'peaks': [
          {'startTime': '10:00', 'endTime': '11:30', 'avgOccupancyPct': 92},
        ],
      }),
    );
    expect(
      peaks.top,
      const PeakWindow(
        startMinute: 600,
        endMinute: 690,
        avgOccupancyPct: 92,
      ),
    );

    final accuracy = mapper.toAccuracy([
      AccuracyResultDto.fromJson({
        'modelVersion': 'v3.0',
        'horizon': 15,
        'maePoints': 3.1,
        'withinMarginPct': 91,
        'computable': true,
      }),
    ]);
    expect(accuracy.current!.withinMarginPct, 91);
    expect(logger.messages, isEmpty);
  });

  test('un valor desconocido del servidor no rompe la pantalla', () {
    final history = mapper.toHistory(
      OccupancyHistoryDto.fromJson({
        'serverTime': '2026-09-28T13:42:00Z',
        'granularity': 'WEEK',
        'points': [
          {'at': '2026-09-28T12:00:00Z', 'occupancyPct': 130},
        ],
      }),
      lotId: _lot,
      range: _range,
      requested: OccupancyGranularity.hour,
    );
    expect(history.granularity, OccupancyGranularity.hour);
    expect(history.points.single.occupancyPct, 100);

    final peaks = mapper.toPeaks(
      PeakHoursDto.fromJson({
        'sufficientData': true,
        'peaks': [
          {'startTime': 'diez', 'endTime': '11:30', 'avgOccupancyPct': 92},
          {'startTime': '16:00', 'endTime': '17:00', 'avgOccupancyPct': 70},
        ],
      }),
    );
    expect(peaks.peaks.single.startMinute, 960);

    // «Calculable» sin porcentaje: no se inventa una cifra.
    final accuracy = mapper.toAccuracy([
      AccuracyResultDto.fromJson({
        'modelVersion': 'v3.0',
        'horizon': 15,
        'computable': true,
      }),
    ]);
    expect(accuracy.isComputable, isFalse);
    expect(logger.messages, hasLength(4));
  });

  test('el reporte viaja con sus secciones y formato del contrato', () {
    final request = ReportRequest.create(
      lotId: _lot,
      range: _range,
      sections: const {ReportSection.alerts, ReportSection.occupancy},
      format: ReportFormat.csv,
    ).valueOrNull!;
    final json = mapper.toRequest(request).toJson();
    expect(json['sections'], ['OCCUPANCY', 'ALERTS']);
    expect(json['format'], 'CSV');
    expect(json['lotId'], 1);
  });

  test('un error de red llega como NetworkFailure', () async {
    final remote = _MockRemote();
    when(
      () => remote.peaks(
        lotId: _lot,
        from: _range.from,
        to: _range.to,
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/analytics/peaks'),
        type: DioExceptionType.connectionError,
      ),
    );
    final reader = AnalyticsReaderImpl(remote: remote, mapper: mapper);

    final result = await reader.peaks(lotId: _lot, range: _range);

    expect(result.failureOrNull, isA<NetworkFailure>());
  });
}
