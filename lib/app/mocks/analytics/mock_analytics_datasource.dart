import 'dart:math' as math;

import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La analítica desde [MockWorld] (docs/07, "Datos y comportamiento de los
/// mocks"). Los datos son **deterministas**: salen de un perfil diario de
/// ocupación (pico a media mañana y otro menor a media tarde, fines de semana
/// más bajos) escalado por estacionamiento y por zona. Así la gráfica no
/// salta entre recargas y se puede probar.
///
/// - Solo atiende a un rol de Operación (403 a un conductor) y responde 404 a
///   un estacionamiento inexistente y 400 a un rango inválido (TS11 esc. 2).
/// - Un estacionamiento sin distribución publicada no tiene registros (US21
///   esc. 3); uno con historial insuficiente no tiene horas pico (US22 esc. 3)
///   ni precisión calculable (US34 esc. 3).
/// - La precisión de Monterrico distingue dos versiones del modelo en los
///   últimos 30 días (US34 esc. 2); en Villa, los horizontes de 45 y 60 min no
///   son calculables.
class MockAnalyticsRemoteDataSource implements AnalyticsRemoteDataSource {
  const MockAnalyticsRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  static const Duration _lima = Duration(hours: -5);

  /// La versión vigente del modelo y la anterior, que se reemplazó hace 12
  /// días.
  static const String currentModel = 'v3.0';
  static const String previousModel = 'v2.3';
  static const Duration _modelAge = Duration(days: 12);

  Future<MockLot> _gate(LotId lotId, DateTime from, DateTime to) async {
    await _world.gateConsole(_callerRole());
    final lot = _world.lot(lotId.value);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    if (!from.isBefore(to)) {
      throw mockHttpError(
        400,
        title: 'Bad Request',
        detail: 'La fecha de inicio debe ser anterior a la de fin.',
        extra: {
          'errors': {
            'from': ['must be before to'],
          },
        },
      );
    }
    return lot;
  }

  @override
  Future<OccupancyHistoryDto> occupancy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
    required String granularity,
    ZoneId? zoneId,
  }) async {
    final lot = await _gate(lotId, from, to);
    final now = _world.clock.now();
    final zoneIndex = zoneId == null
        ? null
        : lot.zones.indexWhere((zone) => zone.id == zoneId.value);
    if (zoneIndex == -1) throw mockHttpError(404, title: 'Not Found');
    final end = to.isAfter(now) ? now : to;
    final points = !lot.hasLayout || !from.isBefore(end)
        ? const <OccupancyPointDto>[]
        : granularity == 'DAY'
        ? _daily(lot, zoneIndex, from, end)
        : _hourly(lot, zoneIndex, from, end);
    return OccupancyHistoryDto(
      serverTime: now,
      granularity: granularity == 'DAY' ? 'DAY' : 'HOUR',
      points: points,
    );
  }

  @override
  Future<PeakHoursDto> peaks({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  }) async {
    final lot = await _gate(lotId, from, to);
    if (!lot.hasLayout || lot.insufficientHistory) {
      return const PeakHoursDto(sufficientData: false);
    }
    // Promedio de cada media hora entre las 06:00 y las 22:00; las franjas
    // son los tramos seguidos que llegan al 90 % del máximo.
    final weekdayShare = _weekdayShare(from, to);
    final slots = <(int, double)>[
      for (var minute = 6 * 60; minute < 22 * 60; minute += 30)
        (
          minute,
          _value(lot, null, minute + 15) *
              (weekdayShare + (1 - weekdayShare) * 0.4),
        ),
    ];
    final top = slots.map((s) => s.$2).reduce(math.max);
    final windows = <PeakWindowDto>[];
    int? start;
    final values = <double>[];
    void close(int endMinute) {
      final begin = start;
      if (begin == null) return;
      final avg = values.reduce((a, b) => a + b) / values.length;
      windows.add(
        PeakWindowDto(
          startTime: _hhmm(begin),
          endTime: _hhmm(endMinute),
          avgOccupancyPct: _round(avg),
        ),
      );
      start = null;
      values.clear();
    }

    for (final (minute, value) in slots) {
      if (value >= top * 0.85) {
        start ??= minute;
        values.add(value);
      } else {
        close(minute);
      }
    }
    close(22 * 60);
    return PeakHoursDto(sufficientData: true, peaks: windows);
  }

  @override
  Future<List<AccuracyResultDto>> accuracy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  }) async {
    final lot = await _gate(lotId, from, to);
    const horizons = [15, 30, 45, 60];
    if (!lot.hasLayout || lot.insufficientHistory) {
      return [
        for (final horizon in horizons)
          AccuracyResultDto(
            modelVersion: currentModel,
            horizon: horizon,
            computable: false,
          ),
      ];
    }
    final now = _world.clock.now();
    final includesPrevious = from.isBefore(now.subtract(_modelAge));
    final penalty = switch (lot.id) {
      2 => 3.0,
      4 => 5.0,
      _ => 0.0,
    };
    AccuracyResultDto result(String version, int horizon, double within) {
      // En Villa los sensores de bajo consumo no dan para los horizontes
      // largos.
      final computable = !(lot.id == 4 && horizon >= 45);
      return AccuracyResultDto(
        modelVersion: version,
        horizon: horizon,
        computable: computable,
        withinMarginPct: computable ? within - penalty : null,
        maePoints: computable
            ? _round(2 + (100 - within + penalty) * 0.22)
            : null,
      );
    }

    return [
      if (includesPrevious) ...[
        result(previousModel, 15, 85),
        result(previousModel, 30, 79),
        result(previousModel, 45, 72),
        result(previousModel, 60, 66),
      ],
      result(currentModel, 15, 91),
      result(currentModel, 30, 86),
      result(currentModel, 45, 81),
      result(currentModel, 60, 76),
    ];
  }

  @override
  Future<ReportDeliveryDto> exportReport(ReportRequestDto request) async {
    await _gate(LotId(request.lotId), request.from, request.to);
    if (request.sections.isEmpty) {
      throw mockHttpError(
        400,
        title: 'Bad Request',
        extra: {
          'errors': {
            'sections': ['must not be empty'],
          },
        },
      );
    }
    final role = _callerRole();
    return ReportDeliveryDto(
      sentTo: role == 'ADMIN' ? 'a•••@upc.edu.pe' : 'o•••@upc.edu.pe',
    );
  }

  // ---------------------------------------------------------------- perfil

  /// La ocupación típica de un día hábil a [minuteOfDay] (hora de Lima): un
  /// pico a las 10:30 y otro menor a las 16:30, de 0 a 1.
  static double _profile(int minuteOfDay) {
    final h = minuteOfDay / 60;
    if (h < 6 || h > 22) return 0.03;
    double bell(double center, double width) =>
        math.exp(-math.pow(h - center, 2) / (2 * width * width));
    return math.min(1, 0.08 + 0.92 * bell(10.5, 1.6) + 0.62 * bell(16.5, 1.4));
  }

  /// El techo de cada estacionamiento (Monterrico casi lleno al pico, San
  /// Isidro lleno, Villa holgado) y, por zona, una variación de ±8 %.
  static double _value(MockLot lot, int? zoneIndex, int minuteOfDay) {
    final ceiling = switch (lot.id) {
      1 => 94.0,
      2 => 99.0,
      4 => 52.0,
      _ => 80.0,
    };
    final zoneFactor = zoneIndex == null ? 1.0 : 0.92 + 0.08 * zoneIndex;
    return (ceiling * zoneFactor * _profile(minuteOfDay)).clamp(0, 100);
  }

  /// Por hora, desde las 06:00 de cada día del rango hasta [end].
  List<OccupancyPointDto> _hourly(
    MockLot lot,
    int? zoneIndex,
    DateTime from,
    DateTime end,
  ) {
    final points = <OccupancyPointDto>[];
    var at = DateTime.utc(from.year, from.month, from.day, from.hour);
    if (at.isBefore(from)) at = at.add(const Duration(hours: 1));
    while (at.isBefore(end)) {
      final local = at.add(_lima);
      final minute = local.hour * 60 + 30;
      if (local.hour >= 6 && local.hour < 22) {
        final value = _value(lot, zoneIndex, minute) * _dayFactor(lot, local);
        points.add(OccupancyPointDto(at: at, occupancyPct: _round(value)));
      }
      at = at.add(const Duration(hours: 1));
    }
    return points;
  }

  /// Por día (medianoche de Lima), el promedio de 07:00 a 21:00.
  List<OccupancyPointDto> _daily(
    MockLot lot,
    int? zoneIndex,
    DateTime from,
    DateTime end,
  ) {
    final points = <OccupancyPointDto>[];
    final first = from.add(_lima);
    var day = DateTime.utc(first.year, first.month, first.day);
    while (day.subtract(_lima).isBefore(end)) {
      var sum = 0.0;
      var count = 0;
      for (var minute = 7 * 60; minute <= 21 * 60; minute += 30) {
        sum += _value(lot, zoneIndex, minute);
        count++;
      }
      final value = sum / count * _dayFactor(lot, day);
      points.add(
        OccupancyPointDto(at: day.subtract(_lima), occupancyPct: _round(value)),
      );
      day = DateTime.utc(day.year, day.month, day.day + 1);
    }
    return points;
  }

  /// Fines de semana más bajos y una variación fija por día (±6 %).
  static double _dayFactor(MockLot lot, DateTime localDay) {
    final weekday = switch (localDay.weekday) {
      DateTime.saturday => 0.45,
      DateTime.sunday => 0.12,
      _ => 1.0,
    };
    final seed = (localDay.day * 7 + localDay.month * 13 + lot.id * 5) % 13;
    return weekday * (0.94 + seed / 100);
  }

  /// La parte de días hábiles del rango (para las horas pico).
  static double _weekdayShare(DateTime from, DateTime to) {
    var day = from.add(_lima);
    final end = to.add(_lima);
    var weekdays = 0;
    var total = 0;
    while (day.isBefore(end)) {
      total++;
      if (day.weekday <= DateTime.friday) weekdays++;
      day = day.add(const Duration(days: 1));
    }
    return total == 0 ? 1 : weekdays / total;
  }

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  static double _round(double value) => (value * 10).roundToDouble() / 10;
}
