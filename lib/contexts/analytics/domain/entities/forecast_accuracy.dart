import 'package:equatable/equatable.dart';

/// La precisión de una versión del modelo a un horizonte en el periodo
/// (US34 esc. 1 y 2, TS11 esc. 3).
class AccuracyResult extends Equatable {
  const AccuracyResult({
    required this.modelVersion,
    required this.horizonMinutes,
    required this.computable,
    this.maePoints,
    this.withinMarginPct,
  });

  final String modelVersion;

  /// 15, 30, 45 o 60.
  final int horizonMinutes;

  /// `false`: no hubo pronósticos y ocupación observada suficientes (US34
  /// esc. 3); entonces no hay cifras.
  final bool computable;

  /// Error absoluto medio en puntos porcentuales.
  final double? maePoints;

  /// Porcentaje de pronósticos dentro del margen configurado (0 a 100).
  final double? withinMarginPct;

  @override
  List<Object?> get props => [
    modelVersion,
    horizonMinutes,
    computable,
    maePoints,
    withinMarginPct,
  ];
}

/// Lo que una versión del modelo logró en el periodo: sus horizontes y el
/// resumen global (el promedio de los horizontes calculables).
class ModelAccuracy extends Equatable {
  ModelAccuracy({
    required this.modelVersion,
    required List<AccuracyResult> results,
  }) : results = List.unmodifiable(
         List<AccuracyResult>.of(results)
           ..sort((a, b) => a.horizonMinutes.compareTo(b.horizonMinutes)),
       );

  final String modelVersion;

  /// Por horizonte, de menor a mayor.
  final List<AccuracyResult> results;

  List<AccuracyResult> get _computable => [
    for (final r in results)
      if (r.computable) r,
  ];

  bool get isComputable => _computable.isNotEmpty;

  /// Porcentaje global dentro del margen, o `null` si nada es calculable.
  double? get withinMarginPct =>
      _mean([for (final r in _computable) ?r.withinMarginPct]);

  /// Error absoluto medio global, o `null` si nada es calculable.
  double? get maePoints => _mean([for (final r in _computable) ?r.maePoints]);

  static double? _mean(List<double> values) => values.isEmpty
      ? null
      : values.fold<double>(0, (total, v) => total + v) / values.length;

  @override
  List<Object?> get props => [modelVersion, results];
}

/// La precisión de las predicciones de un estacionamiento en un periodo,
/// separada por versión del modelo (US34 esc. 2).
class ForecastAccuracy extends Equatable {
  /// [results] llega ordenado de la versión más antigua a la más reciente
  /// (docs/07); ese orden se conserva.
  ForecastAccuracy(List<AccuracyResult> results)
    : models = List.unmodifiable(_group(results));

  /// De la versión más antigua a la más reciente.
  final List<ModelAccuracy> models;

  static List<ModelAccuracy> _group(List<AccuracyResult> results) {
    final byVersion = <String, List<AccuracyResult>>{};
    for (final result in results) {
      (byVersion[result.modelVersion] ??= []).add(result);
    }
    return [
      for (final entry in byVersion.entries)
        ModelAccuracy(modelVersion: entry.key, results: entry.value),
    ];
  }

  /// El periodo permite calcular la precisión de alguna versión (US34
  /// esc. 3).
  bool get isComputable => models.any((m) => m.isComputable);

  /// La versión más reciente con cifras: la que se presenta.
  ModelAccuracy? get current {
    for (final model in models.reversed) {
      if (model.isComputable) return model;
    }
    return null;
  }

  /// La versión anterior a [current] con cifras, para compararla (US34
  /// esc. 2), o `null` si no la hay.
  ModelAccuracy? get previous {
    final current = this.current;
    if (current == null) return null;
    final index = models.indexOf(current);
    for (final model in models.take(index).toList().reversed) {
      if (model.isComputable) return model;
    }
    return null;
  }

  @override
  List<Object?> get props => [models];
}
