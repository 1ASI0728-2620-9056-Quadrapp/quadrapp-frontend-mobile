import 'package:json_annotation/json_annotation.dart';

part 'notification_dtos.g.dart';

/// Una suscripción del servidor (`GET` y `POST /notification-subscriptions`).
@JsonSerializable()
class AlertSubscriptionDto {
  const AlertSubscriptionDto({
    required this.id,
    required this.lotId,
    required this.days,
    required this.from,
    required this.to,
    this.active = true,
  });

  factory AlertSubscriptionDto.fromJson(Map<String, dynamic> json) =>
      _$AlertSubscriptionDtoFromJson(json);

  final int id;
  final int lotId;

  /// 1 = lunes ... 7 = domingo.
  final List<int> days;

  /// `"HH:mm"`, hora local de Lima.
  final String from;
  final String to;
  final bool active;

  Map<String, dynamic> toJson() => _$AlertSubscriptionDtoToJson(this);
}

/// El cuerpo de `POST /notification-subscriptions`.
@JsonSerializable()
class AlertSubscriptionRequestDto {
  const AlertSubscriptionRequestDto({
    required this.lotId,
    required this.days,
    required this.from,
    required this.to,
  });

  factory AlertSubscriptionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AlertSubscriptionRequestDtoFromJson(json);

  final int lotId;
  final List<int> days;
  final String from;
  final String to;

  Map<String, dynamic> toJson() => _$AlertSubscriptionRequestDtoToJson(this);
}

/// El cuerpo de `PATCH /notification-subscriptions/{id}`.
@JsonSerializable()
class AlertSubscriptionActiveRequestDto {
  const AlertSubscriptionActiveRequestDto({required this.active});

  factory AlertSubscriptionActiveRequestDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AlertSubscriptionActiveRequestDtoFromJson(json);

  final bool active;

  Map<String, dynamic> toJson() =>
      _$AlertSubscriptionActiveRequestDtoToJson(this);
}

/// `GET` y `PUT /notification-preferences`.
@JsonSerializable()
class NotificationPreferencesDto {
  const NotificationPreferencesDto({
    required this.pushEnabled,
    required this.saturationAlerts,
    required this.lowArrivalAlerts,
    required this.locale,
    this.staleDataAlerts = true,
    this.eventAlerts = false,
  });

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  final bool pushEnabled;
  final bool saturationAlerts;
  final bool lowArrivalAlerts;

  /// Un servidor que aún no envía estos dos campos usa sus valores por
  /// defecto (docs/06).
  @JsonKey(defaultValue: true)
  final bool staleDataAlerts;
  @JsonKey(defaultValue: false)
  final bool eventAlerts;

  /// `"en-US"` o `"es-419"`; otro valor se trata como inglés.
  final String locale;

  Map<String, dynamic> toJson() => _$NotificationPreferencesDtoToJson(this);
}

/// El cuerpo de `POST /device-tokens/unregister`: solo el token, que no viaja
/// en la URL.
@JsonSerializable()
class DeviceTokenUnregisterRequestDto {
  const DeviceTokenUnregisterRequestDto({required this.token});

  factory DeviceTokenUnregisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenUnregisterRequestDtoFromJson(json);

  final String token;

  Map<String, dynamic> toJson() =>
      _$DeviceTokenUnregisterRequestDtoToJson(this);
}

/// El cuerpo de `POST /device-tokens`.
@JsonSerializable()
class DeviceTokenRequestDto {
  const DeviceTokenRequestDto({required this.token, required this.platform});

  factory DeviceTokenRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenRequestDtoFromJson(json);

  final String token;

  /// `"ANDROID"` (esta app es solo Android).
  final String platform;

  Map<String, dynamic> toJson() => _$DeviceTokenRequestDtoToJson(this);
}
