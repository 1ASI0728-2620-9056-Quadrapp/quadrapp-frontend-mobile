import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/arrival_category.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_validity.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/saturation.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// DTO -> entidades del dominio. Un valor desconocido del servidor no rompe la
/// pantalla; cae en el valor más seguro para el usuario y deja un aviso sin
/// datos personales:
/// - nivel de confianza no reconocido → `LOW`;
/// - categoría de llegada no reconocida → sin categoría (la asesoría se trata
///   como no disponible);
/// - `method` no reconocido → `FALLBACK` (contingencia, el lado cauteloso);
/// - `reason` de próxima liberación no reconocido → sin estimación.
class PredictionMapper {
  const PredictionMapper(this._logger);

  final Logger _logger;

  /// [horizon] es el que se pidió (autoritativo); [receivedAt] es la lectura
  /// del reloj monótono al recibir la respuesta.
  Forecast toForecast(
    ForecastDto dto,
    ForecastHorizon horizon, {
    required Duration receivedAt,
  }) {
    return Forecast(
      horizon: horizon,
      expectedOccupancyPct: dto.expectedOccupancyPct.clamp(0, 100).toDouble(),
      confidence: toConfidence(dto.confidence),
      modelVersion: dto.modelVersion,
      method: parseMethod(dto.method),
      generatedAt: dto.generatedAt.toUtc(),
      validity: ForecastValidity(
        validUntil: dto.validUntil.toUtc(),
        serverTime: dto.serverTime.toUtc(),
        receivedAt: receivedAt,
      ),
      saturation: dto.saturation == null
          ? null
          : Saturation(
              expectedAt: dto.saturation!.expectedAt.toUtc(),
              pct: dto.saturation!.pct.clamp(0, 100).toDouble(),
            ),
    );
  }

  ArrivalAdvice toAdvice(ArrivalAdviceDto dto, {Duration? receivedAt}) {
    final eta = EtaMinutes.create(dto.etaMinutes).valueOrNull;
    if (eta == null) {
      // El servidor devolvió un ETA fuera de 0..120: el contrato no se cumple.
      throw ParseException('etaMinutes fuera de rango: ${dto.etaMinutes}');
    }
    return ArrivalAdvice(
      etaMinutes: eta,
      probabilityOfSpace: dto.probabilityOfSpace.clamp(0, 1).toDouble(),
      category: parseCategory(dto.category),
      confidence: toConfidence(dto.confidence),
      horizonUsed: ForecastHorizon.fromMinutes(dto.horizonUsed),
      generatedAt: dto.generatedAt.toUtc(),
      serverTime: dto.serverTime.toUtc(),
      receivedAt: receivedAt,
    );
  }

  NextAvailability toNextAvailability(NextAvailabilityDto dto) {
    if (dto.available) {
      final min = dto.minMinutes;
      final max = dto.maxMinutes;
      // Dice que hay estimación pero no trae el rango: no se puede mostrar.
      if (min == null || max == null) return const NextAvailabilityNoEstimate();
      return NextAvailabilityEstimate(
        minMinutes: min <= max ? min : max,
        maxMinutes: min <= max ? max : min,
        confidence: dto.confidence == null
            ? null
            : toConfidence(dto.confidence!),
      );
    }
    switch (dto.reason?.toUpperCase()) {
      case 'HAS_FREE_SPACES':
        return const NextAvailabilityNotApplicable();
      case 'NO_EXITS':
        return const NextAvailabilityNoEstimate();
    }
    if (dto.reason != null) {
      _logger.warning(
        'Motivo de próxima liberación no reconocido "${dto.reason}"',
      );
    }
    return const NextAvailabilityNoEstimate();
  }

  Confidence toConfidence(ConfidenceDto dto) => Confidence(
    value: dto.value.clamp(0, 1).toDouble(),
    level: parseLevel(dto.level),
  );

  /// `HIGH`, `MEDIUM` y `LOW`, sin distinguir mayúsculas; otro valor es `LOW`.
  ConfidenceLevel parseLevel(String raw) {
    switch (raw.toUpperCase()) {
      case 'HIGH':
        return ConfidenceLevel.high;
      case 'MEDIUM':
        return ConfidenceLevel.medium;
      case 'LOW':
        return ConfidenceLevel.low;
    }
    _logger.warning('Nivel de confianza no reconocido "$raw": se usa LOW');
    return ConfidenceLevel.low;
  }

  /// `HIGH`, `LIMITED` y `LOW`, sin distinguir mayúsculas; otro valor es
  /// `null` (sin categoría).
  ArrivalCategory? parseCategory(String raw) {
    switch (raw.toUpperCase()) {
      case 'HIGH':
        return ArrivalCategory.high;
      case 'LIMITED':
        return ArrivalCategory.limited;
      case 'LOW':
        return ArrivalCategory.low;
    }
    _logger.warning('Categoría de llegada no reconocida "$raw": sin categoría');
    return null;
  }

  /// `PRIMARY_MODEL` y `FALLBACK`; otro valor es `FALLBACK`.
  ForecastMethod parseMethod(String raw) {
    final method = raw.toUpperCase();
    if (method == 'PRIMARY_MODEL') {
      return ForecastMethod.primaryModel;
    }
    if (method != 'FALLBACK') {
      _logger.warning(
        'Método de pronóstico no reconocido "$raw": se usa FALLBACK',
      );
    }
    return ForecastMethod.fallback;
  }
}
