import 'package:quadrapp_mobile/contexts/analytics/domain/entities/analytics_report.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/forecast_accuracy.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/occupancy_history.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/occupancy_granularity.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// DTO <-> entidades del contexto Analytics. Un valor desconocido del
/// servidor no rompe la pantalla:
/// - una `granularity` que la app no reconoce se toma como la pedida;
/// - un porcentaje fuera de 0 a 100 se acota;
/// - una franja pico con horas ilegibles se omite;
/// - un resultado «calculable» sin porcentaje se trata como no calculable (no
///   se inventa una cifra).
/// Cada caso deja un aviso sin datos personales.
class AnalyticsMapper {
  const AnalyticsMapper(this._logger);

  final Logger _logger;

  OccupancyHistory toHistory(
    OccupancyHistoryDto dto, {
    required LotId lotId,
    required AnalyticsRange range,
    required OccupancyGranularity requested,
    ZoneId? zoneId,
  }) {
    return OccupancyHistory(
      lotId: lotId,
      zoneId: zoneId,
      range: range,
      granularity: _granularity(dto.granularity, requested),
      serverTime: dto.serverTime.toUtc(),
      points: [
        for (final point in dto.points)
          OccupancyPoint(
            at: point.at.toUtc(),
            occupancyPct: _pct(point.occupancyPct),
          ),
      ],
    );
  }

  PeakHours toPeaks(PeakHoursDto dto) {
    final windows = <PeakWindow>[];
    for (final item in dto.peaks) {
      final start = parseClock(item.startTime);
      final end = parseClock(item.endTime);
      if (start == null || end == null || end <= start) {
        _logger.warning('Franja pico ilegible: se omite');
        continue;
      }
      windows.add(
        PeakWindow(
          startMinute: start,
          endMinute: end,
          avgOccupancyPct: _pct(item.avgOccupancyPct),
        ),
      );
    }
    return PeakHours(sufficientData: dto.sufficientData, peaks: windows);
  }

  ForecastAccuracy toAccuracy(List<AccuracyResultDto> dtos) {
    return ForecastAccuracy([
      for (final dto in dtos) _result(dto),
    ]);
  }

  AccuracyResult _result(AccuracyResultDto dto) {
    final within = dto.withinMarginPct;
    if (dto.computable && within == null) {
      _logger.warning(
        'Precisión «calculable» sin porcentaje (modelo ${dto.modelVersion}): '
        'se trata como no calculable',
      );
    }
    final computable = dto.computable && within != null;
    final mae = dto.maePoints;
    return AccuracyResult(
      modelVersion: dto.modelVersion,
      horizonMinutes: dto.horizon,
      computable: computable,
      withinMarginPct: computable ? _pct(within) : null,
      maePoints: computable && mae != null ? _pct(mae) : null,
    );
  }

  ReportRequestDto toRequest(ReportRequest request) => ReportRequestDto(
    lotId: request.lotId.value,
    from: request.range.from,
    to: request.range.to,
    format: switch (request.format) {
      ReportFormat.pdf => 'PDF',
      ReportFormat.csv => 'CSV',
    },
    sections: [
      for (final section in ReportSection.values)
        if (request.sections.contains(section))
          switch (section) {
            ReportSection.occupancy => 'OCCUPANCY',
            ReportSection.accuracy => 'ACCURACY',
            ReportSection.alerts => 'ALERTS',
          },
    ],
  );

  ReportDelivery toDelivery(ReportDeliveryDto dto) =>
      ReportDelivery(sentTo: dto.sentTo);

  String granularityToApi(OccupancyGranularity granularity) =>
      switch (granularity) {
        OccupancyGranularity.hour => 'HOUR',
        OccupancyGranularity.day => 'DAY',
      };

  /// `HH:mm` (o `HH:mm:ss`) a minutos desde la medianoche; `24:00` vale como
  /// fin del día. Otro valor es `null`.
  static int? parseClock(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59 || hour < 0) return null;
    final total = hour * 60 + minute;
    return total > 24 * 60 ? null : total;
  }

  OccupancyGranularity _granularity(
    String raw,
    OccupancyGranularity requested,
  ) {
    switch (raw.toUpperCase()) {
      case 'HOUR':
        return OccupancyGranularity.hour;
      case 'DAY':
        return OccupancyGranularity.day;
    }
    _logger.warning('Granularidad no reconocida "$raw": se usa la pedida');
    return requested;
  }

  double _pct(double value) {
    if (value >= 0 && value <= 100) return value;
    _logger.warning('Porcentaje fuera de rango: se acota');
    return value.clamp(0, 100).toDouble();
  }
}
