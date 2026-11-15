import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_day.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_time_slot.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/api_language.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// DTO <-> entidades del dominio. Aquí vive el mapeo del idioma de la app a
/// la API (`en` → `en-US`, `es` → `es-419`) y el formato `"HH:mm"` de las
/// franjas.
///
/// Un valor desconocido del servidor no rompe la pantalla:
/// - un `locale` que no es `en-US` ni `es-419` → inglés;
/// - una suscripción de la lista que no se puede leer (día fuera de 1..7, hora
///   ilegible, franja invertida) se omite; las demás se muestran.
/// Cada caso deja un aviso sin datos personales.
class NotificationsMapper {
  const NotificationsMapper(this._logger);

  final Logger _logger;

  /// Las suscripciones legibles de la lista, activas e inactivas (una
  /// desactivada se conserva para poder reactivarla).
  List<AlertSubscription> toSubscriptions(List<AlertSubscriptionDto> dtos) {
    return [for (final dto in dtos) ?_tryToSubscription(dto)];
  }

  /// Una suscripción suelta (la respuesta de `POST`). Si no se puede leer, es
  /// un `ParseException` (→ `ParseFailure`).
  AlertSubscription toSubscription(AlertSubscriptionDto dto) =>
      _tryToSubscription(dto) ??
      (throw ParseException('Suscripción ${dto.id} ilegible.'));

  AlertSubscriptionRequestDto toRequestDto(AlertSubscriptionDraft draft) =>
      AlertSubscriptionRequestDto(
        lotId: draft.lotId.value,
        days: [for (final day in draft.days) day.isoNumber],
        from: formatTime(draft.slot.from),
        to: formatTime(draft.slot.to),
      );

  NotificationPreferences toPreferences(NotificationPreferencesDto dto) =>
      NotificationPreferences(
        pushEnabled: dto.pushEnabled,
        saturationAlerts: dto.saturationAlerts,
        lowArrivalAlerts: dto.lowArrivalAlerts,
        staleDataAlerts: dto.staleDataAlerts,
        eventAlerts: dto.eventAlerts,
        language: parseLanguage(dto.locale),
      );

  NotificationPreferencesDto toPreferencesDto(
    NotificationPreferences preferences,
  ) => NotificationPreferencesDto(
    pushEnabled: preferences.pushEnabled,
    saturationAlerts: preferences.saturationAlerts,
    lowArrivalAlerts: preferences.lowArrivalAlerts,
    staleDataAlerts: preferences.staleDataAlerts,
    eventAlerts: preferences.eventAlerts,
    locale: apiLanguageTag(preferences.language.code),
  );

  /// `"HH:mm"`, con ceros a la izquierda.
  String formatTime(ClockTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// `"HH:mm"` (se tolera `"HH:mm:ss"`), o `null` si no es una hora válida.
  ClockTime? parseTime(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw);
    if (match == null) return null;
    return ClockTime.create(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    ).valueOrNull;
  }

  /// El idioma de la app para un `locale` de la API; inglés si no se reconoce.
  AlertLanguage parseLanguage(String locale) {
    for (final language in AlertLanguage.values) {
      if (apiLanguageTag(language.code) == locale) return language;
    }
    _logger.warning('Idioma de alertas no reconocido "$locale": se usa en');
    return AlertLanguage.en;
  }

  AlertSubscription? _tryToSubscription(AlertSubscriptionDto dto) {
    final days = <AlertDay>{};
    for (final number in dto.days) {
      final day = AlertDay.fromIsoNumber(number);
      if (day == null) return _skip(dto);
      days.add(day);
    }
    final from = parseTime(dto.from);
    final to = parseTime(dto.to);
    if (days.isEmpty || from == null || to == null) return _skip(dto);
    final slot = AlertTimeSlot.create(from: from, to: to).valueOrNull;
    if (slot == null) return _skip(dto);
    return AlertSubscription(
      id: AlertSubscriptionId(dto.id),
      lotId: LotId(dto.lotId),
      days: days.toList()..sort((a, b) => a.isoNumber.compareTo(b.isoNumber)),
      slot: slot,
      active: dto.active,
    );
  }

  AlertSubscription? _skip(AlertSubscriptionDto dto) {
    _logger.warning('Suscripción ${dto.id} ilegible: se omite');
    return null;
  }
}
