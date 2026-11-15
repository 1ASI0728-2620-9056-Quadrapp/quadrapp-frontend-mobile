// US19, US29 (configuración propia del estacionamiento)
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Hora del día de un estacionamiento (`parking_lots.opens_at` y
/// `closes_at`, docs/06): hora y minuto en la hora local de la sede
/// (America/Lima), sin fecha ni zona. Se compara por minutos desde la
/// medianoche.
class LotTime extends Equatable implements Comparable<LotTime> {
  const LotTime._(this.minutesOfDay);

  /// `null` si la hora no está entre 00:00 y 23:59.
  static LotTime? of(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return LotTime._(hour * 60 + minute);
  }

  /// Lee `HH:mm` (o `HH:mm:ss`, como un `TIME` de PostgreSQL). `null` si
  /// falta o no se puede leer.
  static LotTime? parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return of(hour, minute);
  }

  final int minutesOfDay;

  int get hour => minutesOfDay ~/ 60;

  int get minute => minutesOfDay % 60;

  /// `HH:mm`, el formato del contrato.
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LotTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  List<Object?> get props => [minutesOfDay];
}

/// Por qué una configuración no es válida.
enum LotSettingsError {
  /// Hay apertura sin cierre o cierre sin apertura.
  scheduleIncomplete,

  /// El cierre no es posterior a la apertura (no hay horarios que crucen la
  /// medianoche).
  closesBeforeOpens,

  /// La alerta de ocupación no está entre 1 y 100 %.
  thresholdOutOfRange,
}

/// La configuración propia de un estacionamiento: su horario y el umbral de
/// ocupación con el que se avisa al turno (`saturation_threshold_pct`). Solo
/// afecta a ese estacionamiento. El estacionamiento siempre es gratuito: la
/// modalidad no es configurable.
class LotSettings extends Equatable {
  const LotSettings._({
    required this.saturationThresholdPct,
    this.opensAt,
    this.closesAt,
  });

  static const String _invalid =
      'La configuración del estacionamiento no es válida.';

  static const int minThresholdPct = 1;
  static const int maxThresholdPct = 100;

  /// El valor por defecto de docs/06.
  static const int defaultThresholdPct = 90;

  /// Los motivos por los que la configuración no sería válida (vacío si lo
  /// es).
  static Set<LotSettingsError> validate({
    required LotTime? opensAt,
    required LotTime? closesAt,
    required int saturationThresholdPct,
  }) => {
    if ((opensAt == null) != (closesAt == null))
      LotSettingsError.scheduleIncomplete,
    if (opensAt != null && closesAt != null && closesAt.compareTo(opensAt) <= 0)
      LotSettingsError.closesBeforeOpens,
    if (saturationThresholdPct < minThresholdPct ||
        saturationThresholdPct > maxThresholdPct)
      LotSettingsError.thresholdOutOfRange,
  };

  /// Una configuración válida o un `ValidationFailure` con el campo que falla
  /// (`opensAt`, `closesAt` o `saturationThresholdPct`) y el nombre del
  /// motivo.
  static Result<LotSettings> create({
    required int saturationThresholdPct,
    LotTime? opensAt,
    LotTime? closesAt,
  }) {
    final errors = validate(
      opensAt: opensAt,
      closesAt: closesAt,
      saturationThresholdPct: saturationThresholdPct,
    );
    if (errors.isNotEmpty) {
      return Err(
        ValidationFailure(_invalid, {
          for (final error in errors)
            switch (error) {
              LotSettingsError.scheduleIncomplete =>
                opensAt == null ? 'opensAt' : 'closesAt',
              LotSettingsError.closesBeforeOpens => 'closesAt',
              LotSettingsError.thresholdOutOfRange => 'saturationThresholdPct',
            }: [
              error.name,
            ],
        }),
      );
    }
    return Success(
      LotSettings._(
        opensAt: opensAt,
        closesAt: closesAt,
        saturationThresholdPct: saturationThresholdPct,
      ),
    );
  }

  /// Para leer lo que manda el servidor sin romper la pantalla: si los datos
  /// no son válidos, queda «sin horario» y el umbral se ajusta a 1–100
  /// (`adjusted` es `true` para dejar un aviso).
  static ({LotSettings settings, bool adjusted}) tolerant({
    required int saturationThresholdPct,
    LotTime? opensAt,
    LotTime? closesAt,
  }) {
    final valid = validate(
      opensAt: opensAt,
      closesAt: closesAt,
      saturationThresholdPct: saturationThresholdPct,
    ).isEmpty;
    if (valid) {
      return (
        settings: LotSettings._(
          opensAt: opensAt,
          closesAt: closesAt,
          saturationThresholdPct: saturationThresholdPct,
        ),
        adjusted: false,
      );
    }
    return (
      settings: LotSettings._(
        saturationThresholdPct: saturationThresholdPct.clamp(
          minThresholdPct,
          maxThresholdPct,
        ),
      ),
      adjusted: true,
    );
  }

  /// `null` sin horario definido (`opens_at` es opcional en docs/06).
  final LotTime? opensAt;
  final LotTime? closesAt;

  /// De 1 a 100: al superarlo, el turno recibe una alerta y el
  /// estacionamiento se considera «casi lleno».
  final int saturationThresholdPct;

  bool get hasSchedule => opensAt != null && closesAt != null;

  @override
  List<Object?> get props => [opensAt, closesAt, saturationThresholdPct];
}
